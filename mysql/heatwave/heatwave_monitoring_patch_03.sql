-- ===============================================================================================
-- HEATWAVE MONITORING DEPLOYMENT v2.0 - MYSQL 9.x COMPATIBLE
-- Fixed for MySQL 9.3.2+ with proper UTF8MB4 charset handling
-- ===============================================================================================

-- Set proper charset at session level
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET character_set_client = utf8mb4;
SET character_set_connection = utf8mb4;
SET character_set_results = utf8mb4;

-- Create schema with proper charset
CREATE SCHEMA IF NOT EXISTS support_heatwave 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE support_heatwave;

-- Ensure we're using the right charset for this session
ALTER DATABASE support_heatwave CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

SELECT 'HeatWave Change Monitoring System v2.0 - Starting Deployment (MySQL 9.x Compatible)' as deployment_status;
SELECT CONCAT('MySQL Version: ', VERSION()) as database_info;
SELECT CONCAT('Deployment Time: ', NOW()) as deployment_time;

-- ===============================================================================================
-- STEP 1: ENVIRONMENT PREPARATION
-- ===============================================================================================

SELECT 'Step 1: Preparing environment...' as step_info;

-- Clean existing objects for fresh deployment
DROP EVENT IF EXISTS support_heatwave.enhanced_rapid_monitoring;
DROP EVENT IF EXISTS support_heatwave.automatic_cleanup;
DROP VIEW IF EXISTS vw_recent_dynamic_operations;
DROP VIEW IF EXISTS vw_heatwave_dynamic_tables;
DROP PROCEDURE IF EXISTS tracked_secondary_unload;
DROP PROCEDURE IF EXISTS tracked_secondary_load;
DROP TABLE IF EXISTS dynamic_load_operations;

SELECT 'Environment cleaned and ready' as cleanup_status;

-- ===============================================================================================
-- STEP 2: DYNAMIC OPERATIONS TRACKING TABLE
-- ===============================================================================================

SELECT 'Step 2: Creating dynamic operations tracking...' as step_info;

-- Track dynamic loading operations
CREATE TABLE dynamic_load_operations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    operation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(128) NOT NULL,
    operation_type ENUM('LOAD', 'UNLOAD', 'REFRESH') NOT NULL,
    reason VARCHAR(255),
    memory_impact_mb DECIMAL(10,2),
    duration_seconds DECIMAL(6,3),
    status ENUM('SUCCESS', 'FAILED', 'IN_PROGRESS') DEFAULT 'SUCCESS',
    error_message TEXT,
    INDEX idx_operation_time (operation_time),
    INDEX idx_table_name (table_name),
    INDEX idx_operation_type (operation_type),
    INDEX idx_status (status)
) ENGINE=InnoDB 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
COMMENT='Track dynamic HeatWave loading operations';

SELECT 'Dynamic operations tracking table created' as tracking_status;

-- ===============================================================================================
-- STEP 3: ENHANCED MONITORING VIEWS
-- ===============================================================================================

SELECT 'Step 3: Creating enhanced monitoring views...' as step_info;

-- Enhanced monitoring view for dynamic tables
CREATE OR REPLACE VIEW vw_heatwave_dynamic_tables AS
SELECT 
    tsc.table_schema,
    tsc.table_name,
    CASE 
        WHEN tsc.table_name LIKE '%_current_%' THEN 'CURRENT_REPORTING'
        WHEN tsc.table_name LIKE '%_extended_%' THEN 'EXTENDED_ANALYSIS' 
        WHEN tsc.table_name LIKE '%_historical_%' THEN 'HISTORICAL_ANALYSIS'
        WHEN tsc.table_name LIKE '%_partitioned' THEN 'PARTITIONED_TABLE'
        ELSE 'STANDARD_TABLE'
    END as table_type,
    tsc.secondary_load,
    CASE 
        WHEN loaded.memory_mb IS NOT NULL THEN 'LOADED'
        ELSE 'NOT_LOADED'
    END as current_status,
    IFNULL(loaded.memory_mb, 0) as memory_mb,
    tsc.last_checked,
    (SELECT COUNT(*) FROM dynamic_load_operations dlo 
     WHERE dlo.table_name = CONCAT(tsc.table_schema, '.', tsc.table_name)
       AND dlo.operation_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)) as operations_24h
FROM table_state_current tsc
LEFT JOIN (
    SELECT 
        tid.SCHEMA_NAME,
        tid.NAME,
        ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2) as memory_mb
    FROM performance_schema.rpd_tables t_id
    JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
    WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
) loaded ON tsc.table_schema = loaded.SCHEMA_NAME AND tsc.table_name = loaded.NAME
WHERE tsc.secondary_engine = 'RAPID'
ORDER BY table_type, memory_mb DESC;

-- View recent dynamic operations
CREATE OR REPLACE VIEW vw_recent_dynamic_operations AS
SELECT 
    operation_time,
    table_name,
    operation_type,
    reason,
    CONCAT(ABS(memory_impact_mb), ' MB') as memory_change,
    CASE 
        WHEN memory_impact_mb > 0 THEN 'Memory Added'
        WHEN memory_impact_mb < 0 THEN 'Memory Freed'
        ELSE 'No Change'
    END as impact_type,
    CONCAT(duration_seconds, 's') as duration,
    status,
    error_message
FROM dynamic_load_operations 
WHERE operation_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY operation_time DESC;

SELECT 'Enhanced monitoring views created' as views_status;

-- ===============================================================================================
-- STEP 4: TRACKING PROCEDURES
-- ===============================================================================================

SELECT 'Step 4: Creating tracking procedures...' as step_info;

DELIMITER //

-- Enhanced procedure to track load operations
CREATE PROCEDURE tracked_secondary_load(
    IN schema_name VARCHAR(64),
    IN table_name VARCHAR(64),
    IN reason VARCHAR(255)
)
COMMENT 'Load table to HeatWave with tracking'
BEGIN
    DECLARE start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration_sec DECIMAL(6,3);
    DECLARE memory_before DECIMAL(10,2) DEFAULT 0;
    DECLARE memory_after DECIMAL(10,2) DEFAULT 0;
    DECLARE operation_status VARCHAR(10) DEFAULT 'SUCCESS';
    DECLARE error_msg TEXT DEFAULT NULL;
    DECLARE full_table_name VARCHAR(128);
    
    SET full_table_name = CONCAT(schema_name, '.', table_name);
    
    -- Get memory before operation
    SELECT IFNULL(
        (SELECT ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2)
         FROM performance_schema.rpd_tables t_id
         JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
         WHERE tid.SCHEMA_NAME = schema_name AND tid.NAME = table_name
           AND t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'), 0
    ) INTO memory_before;
    
    -- Perform the load operation with error handling
    BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET operation_status = 'FAILED';
            GET DIAGNOSTICS CONDITION 1
                error_msg = MESSAGE_TEXT;
        END;
        
        SET @sql = CONCAT('ALTER TABLE `', schema_name, '`.`', table_name, '` SECONDARY_LOAD');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END;
    
    SET end_time = CURRENT_TIMESTAMP;
    SET duration_sec = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000000;
    
    -- Wait for loading to complete and get memory after
    IF operation_status = 'SUCCESS' THEN
        SELECT SLEEP(3);
        SELECT IFNULL(
            (SELECT ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2)
             FROM performance_schema.rpd_tables t_id
             JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
             WHERE tid.SCHEMA_NAME = schema_name AND tid.NAME = table_name
               AND t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'), 0
        ) INTO memory_after;
    END IF;
    
    -- Log the operation
    INSERT INTO dynamic_load_operations 
    (table_name, operation_type, reason, memory_impact_mb, duration_seconds, status, error_message)
    VALUES (full_table_name, 'LOAD', reason, 
            memory_after - memory_before, duration_sec, operation_status, error_msg);
    
    -- Report results
    SELECT 
        full_table_name as table_loaded,
        reason as operation_reason,
        CONCAT(memory_after - memory_before, ' MB') as memory_added,
        CONCAT(duration_sec, ' seconds') as load_time,
        operation_status as status,
        IFNULL(error_msg, 'Success') as message;
END //

-- Enhanced procedure to track unload operations
CREATE PROCEDURE tracked_secondary_unload(
    IN schema_name VARCHAR(64),
    IN table_name VARCHAR(64),
    IN reason VARCHAR(255)
)
COMMENT 'Unload table from HeatWave with tracking'
BEGIN
    DECLARE start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration_sec DECIMAL(6,3);
    DECLARE memory_before DECIMAL(10,2) DEFAULT 0;
    DECLARE operation_status VARCHAR(10) DEFAULT 'SUCCESS';
    DECLARE error_msg TEXT DEFAULT NULL;
    DECLARE full_table_name VARCHAR(128);
    
    SET full_table_name = CONCAT(schema_name, '.', table_name);
    
    -- Get memory before operation
    SELECT IFNULL(
        (SELECT ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2)
         FROM performance_schema.rpd_tables t_id
         JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
         WHERE tid.SCHEMA_NAME = schema_name AND tid.NAME = table_name
           AND t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'), 0
    ) INTO memory_before;
    
    -- Perform the unload operation with error handling
    BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET operation_status = 'FAILED';
            GET DIAGNOSTICS CONDITION 1
                error_msg = MESSAGE_TEXT;
        END;
        
        SET @sql = CONCAT('ALTER TABLE `', schema_name, '`.`', table_name, '` SECONDARY_UNLOAD');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END;
    
    SET end_time = CURRENT_TIMESTAMP;
    SET duration_sec = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000000;
    
    -- Log the operation
    INSERT INTO dynamic_load_operations 
    (table_name, operation_type, reason, memory_impact_mb, duration_seconds, status, error_message)
    VALUES (full_table_name, 'UNLOAD', reason, 
            -memory_before, duration_sec, operation_status, error_msg);
    
    -- Report results
    SELECT 
        full_table_name as table_unloaded,
        reason as operation_reason,
        CONCAT(memory_before, ' MB') as memory_freed,
        CONCAT(duration_sec, ' seconds') as unload_time,
        operation_status as status,
        IFNULL(error_msg, 'Success') as message;
END //

DELIMITER ;

SELECT 'Tracking procedures created successfully' as procedures_status;

-- ===============================================================================================
-- STEP 5: VERIFICATION AND TESTING
-- ===============================================================================================

SELECT 'Step 5: Verifying deployment...' as step_info;

-- Test the views
SELECT 'Testing vw_heatwave_dynamic_tables:' as test_1;
SELECT COUNT(*) as dynamic_tables_found FROM vw_heatwave_dynamic_tables;

SELECT 'Testing vw_recent_dynamic_operations:' as test_2;  
SELECT COUNT(*) as recent_operations FROM vw_recent_dynamic_operations;

-- Verify the new table
SELECT 'Testing dynamic_load_operations table:' as test_3;
SELECT 
    COUNT(*) as operation_records,
    'Table structure verified' as status
FROM dynamic_load_operations;

-- ===============================================================================================
-- STEP 6: USAGE EXAMPLES AND DOCUMENTATION
-- ===============================================================================================

SELECT 'USAGE EXAMPLES:' as usage_header;

-- Insert sample usage documentation
INSERT INTO dynamic_load_operations 
(table_name, operation_type, reason, memory_impact_mb, duration_seconds, status)
VALUES 
('example_schema.sample_table', 'LOAD', 'System initialization - example record', 0, 0, 'SUCCESS');

SELECT 'Example usage commands:' as examples;
SELECT '-- Load a table with tracking:' as cmd1;
SELECT '-- CALL tracked_secondary_load("your_schema", "your_table", "Monthly analysis");' as cmd2;
SELECT '-- Unload a table with tracking:' as cmd3;
SELECT '-- CALL tracked_secondary_unload("your_schema", "your_table", "Analysis completed");' as cmd4;
SELECT '-- View recent operations:' as cmd5;
SELECT '-- SELECT * FROM vw_recent_dynamic_operations;' as cmd6;

-- ===============================================================================================
-- STEP 7: DEPLOYMENT COMPLETION
-- ===============================================================================================

SELECT 'DEPLOYMENT COMPLETED SUCCESSFULLY!' as deployment_final_status;
SELECT '==========================================' as separator1;
SELECT 'HeatWave Dynamic Monitoring v2.0' as system_name;
SELECT 'MySQL 9.x Compatible' as compatibility;
SELECT '==========================================' as separator2;

-- Final verification
SELECT 'FINAL VERIFICATION:' as final_verification;
SELECT 
    (SELECT COUNT(*) FROM dynamic_load_operations) as operation_records,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = 'support_heatwave' AND TABLE_NAME LIKE 'vw_%dynamic%') as dynamic_views,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = 'support_heatwave' AND ROUTINE_NAME LIKE 'tracked_%') as tracking_procedures,
    'Dynamic monitoring features ready!' as status;

-- Clean up example record
DELETE FROM dynamic_load_operations WHERE table_name = 'example_schema.sample_table';

SELECT 'System ready for dynamic HeatWave table management!' as ready_status;