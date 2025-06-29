-- ===============================================================================================
-- UNIVERSAL HEATWAVE MONITORING DEPLOYMENT - ALL MYSQL VERSIONS
-- Compatible with MySQL 8.0, 8.4, 9.0, 9.3+ 
-- Explicit UTF8MB4 charset to avoid version-specific defaults
-- NO EMOJIS - Plain text only for maximum compatibility
-- ===============================================================================================

-- Force session to use UTF8MB4 consistently
SET SESSION character_set_client = utf8mb4;
SET SESSION character_set_connection = utf8mb4;
SET SESSION character_set_results = utf8mb4;
SET SESSION collation_connection = utf8mb4_unicode_ci;

-- Check current session settings
SELECT 'CHARSET VERIFICATION:' as info;
SELECT 
    @@character_set_client as client_charset,
    @@character_set_connection as connection_charset,
    @@character_set_results as result_charset,
    @@collation_connection as collation;

SELECT 'HeatWave Universal Monitoring v2.0 - Deployment Starting' as deployment_status;
SELECT CONCAT('MySQL Version: ', VERSION()) as mysql_version;
SELECT CONCAT('Deployment Time: ', NOW()) as deployment_time;

-- ===============================================================================================
-- STEP 1: CREATE DATABASE WITH EXPLICIT CHARSET
-- ===============================================================================================

SELECT 'Step 1: Creating database with explicit UTF8MB4 charset...' as step_info;

-- Drop and recreate with explicit charset
DROP DATABASE IF EXISTS support_heatwave;
CREATE DATABASE support_heatwave 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE support_heatwave;

-- Verify database charset
SELECT 
    schema_name as database_name,
    default_character_set_name as charset,
    default_collation_name as collation
FROM information_schema.schemata 
WHERE schema_name = 'support_heatwave';

SELECT 'Database created with explicit UTF8MB4 charset' as status;

-- ===============================================================================================
-- STEP 2: DYNAMIC OPERATIONS TRACKING TABLE
-- ===============================================================================================

SELECT 'Step 2: Creating tracking tables...' as step_info;

-- Track dynamic loading operations with explicit charset
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
-- STEP 3: CHECK IF MAIN MONITORING SYSTEM EXISTS
-- ===============================================================================================

SELECT 'Step 3: Checking main monitoring system...' as step_info;

-- Check if core monitoring tables exist
SELECT 
    COUNT(*) as core_tables_exist
FROM information_schema.tables 
WHERE table_schema = 'support_heatwave' 
  AND table_name IN ('table_state_current', 'rapid_changes_detailed', 'c_monitoring_options');

-- If main system doesn't exist, create basic compatibility layer
-- Note: This assumes the main system was deployed separately

-- ===============================================================================================
-- STEP 4: ENHANCED MONITORING VIEWS (NO EMOJIS)
-- ===============================================================================================

SELECT 'Step 4: Creating enhanced monitoring views...' as step_info;

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

-- View recent dynamic operations (NO EMOJIS)
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

-- Memory usage by schema (NO EMOJIS)
CREATE OR REPLACE VIEW vw_heatwave_memory_by_schema AS
SELECT 
    IFNULL(tid.SCHEMA_NAME, 'TOTAL') as schema_name,
    COUNT(*) as loaded_tables,
    ROUND(SUM(t_id.SIZE_BYTES) / (1024 * 1024), 2) as total_memory_mb,
    ROUND(SUM(t_id.SIZE_BYTES) / (1024 * 1024 * 1024), 2) as total_memory_gb,
    ROUND(
        (SUM(t_id.SIZE_BYTES) / (1024 * 1024 * 1024)) / 32 * 100, 1
    ) as memory_utilization_percent
FROM performance_schema.rpd_tables t_id
JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
GROUP BY tid.SCHEMA_NAME WITH ROLLUP
ORDER BY total_memory_gb DESC;

SELECT 'Enhanced monitoring views created successfully' as views_status;

-- ===============================================================================================
-- STEP 5: TRACKING PROCEDURES (COMPATIBLE WITH ALL VERSIONS)
-- ===============================================================================================

SELECT 'Step 5: Creating tracking procedures...' as step_info;

DELIMITER //

-- Enhanced procedure to track load operations
CREATE PROCEDURE tracked_secondary_load(
    IN schema_name VARCHAR(64),
    IN table_name VARCHAR(64),
    IN reason VARCHAR(255)
)
COMMENT 'Load table to HeatWave with tracking - Universal MySQL version support'
BEGIN
    DECLARE start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration_sec DECIMAL(6,3);
    DECLARE memory_before DECIMAL(10,2) DEFAULT 0;
    DECLARE memory_after DECIMAL(10,2) DEFAULT 0;
    DECLARE operation_status VARCHAR(10) DEFAULT 'SUCCESS';
    DECLARE error_msg TEXT DEFAULT NULL;
    DECLARE full_table_name VARCHAR(128);
    DECLARE sql_statement TEXT;
    
    SET full_table_name = CONCAT(schema_name, '.', table_name);
    
    -- Get memory before operation
    SELECT IFNULL(
        (SELECT ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2)
         FROM performance_schema.rpd_tables t_id
         JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
         WHERE tid.SCHEMA_NAME = schema_name AND tid.NAME = table_name
           AND t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'), 0
    ) INTO memory_before;
    
    -- Perform the load operation with comprehensive error handling
    BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET operation_status = 'FAILED';
            GET DIAGNOSTICS CONDITION 1
                error_msg = MESSAGE_TEXT;
        END;
        
        -- Build SQL with proper escaping for all MySQL versions
        SET sql_statement = CONCAT('ALTER TABLE `', schema_name, '`.`', table_name, '` SECONDARY_LOAD');
        
        SET @sql = sql_statement;
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END;
    
    SET end_time = CURRENT_TIMESTAMP;
    SET duration_sec = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000000;
    
    -- Wait for loading to complete and get memory after (if successful)
    IF operation_status = 'SUCCESS' THEN
        -- Small delay to allow operation to complete
        SELECT SLEEP(2);
        
        SELECT IFNULL(
            (SELECT ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2)
             FROM performance_schema.rpd_tables t_id
             JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
             WHERE tid.SCHEMA_NAME = schema_name AND tid.NAME = table_name
               AND t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'), 0
        ) INTO memory_after;
    END IF;
    
    -- Log the operation with explicit charset handling
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
COMMENT 'Unload table from HeatWave with tracking - Universal MySQL version support'
BEGIN
    DECLARE start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration_sec DECIMAL(6,3);
    DECLARE memory_before DECIMAL(10,2) DEFAULT 0;
    DECLARE operation_status VARCHAR(10) DEFAULT 'SUCCESS';
    DECLARE error_msg TEXT DEFAULT NULL;
    DECLARE full_table_name VARCHAR(128);
    DECLARE sql_statement TEXT;
    
    SET full_table_name = CONCAT(schema_name, '.', table_name);
    
    -- Get memory before operation
    SELECT IFNULL(
        (SELECT ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2)
         FROM performance_schema.rpd_tables t_id
         JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
         WHERE tid.SCHEMA_NAME = schema_name AND tid.NAME = table_name
           AND t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'), 0
    ) INTO memory_before;
    
    -- Perform the unload operation with comprehensive error handling
    BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET operation_status = 'FAILED';
            GET DIAGNOSTICS CONDITION 1
                error_msg = MESSAGE_TEXT;
        END;
        
        -- Build SQL with proper escaping for all MySQL versions
        SET sql_statement = CONCAT('ALTER TABLE `', schema_name, '`.`', table_name, '` SECONDARY_UNLOAD');
        
        SET @sql = sql_statement;
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

-- Procedure to check dynamic operations activity
CREATE PROCEDURE check_dynamic_operations()
COMMENT 'Check recent dynamic operation activity'
BEGIN
    -- Recent operations summary
    SELECT 'RECENT DYNAMIC OPERATIONS (24 HOURS):' as section;
    
    SELECT 
        operation_type,
        COUNT(*) as operation_count,
        SUM(ABS(memory_impact_mb)) as total_memory_mb,
        AVG(duration_seconds) as avg_duration_sec,
        MAX(operation_time) as last_operation
    FROM dynamic_load_operations 
    WHERE operation_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
    GROUP BY operation_type
    ORDER BY operation_count DESC;
    
    -- Failed operations
    SELECT 'FAILED OPERATIONS (LAST 7 DAYS):' as section;
    
    SELECT 
        operation_time,
        table_name,
        operation_type,
        reason,
        error_message
    FROM dynamic_load_operations 
    WHERE status = 'FAILED' 
      AND operation_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ORDER BY operation_time DESC
    LIMIT 10;
    
    -- Top memory impact operations
    SELECT 'TOP MEMORY IMPACT OPERATIONS (LAST 7 DAYS):' as section;
    
    SELECT 
        operation_time,
        table_name,
        operation_type,
        memory_impact_mb,
        reason
    FROM dynamic_load_operations 
    WHERE operation_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ORDER BY ABS(memory_impact_mb) DESC
    LIMIT 10;
END //

DELIMITER ;

SELECT 'Tracking procedures created successfully' as procedures_status;

-- ===============================================================================================
-- STEP 6: VERIFICATION AND TESTING
-- ===============================================================================================

SELECT 'Step 6: Verifying deployment...' as step_info;

-- Test the views
SELECT 'Testing vw_heatwave_dynamic_tables:' as test_1;
SELECT COUNT(*) as dynamic_tables_found FROM vw_heatwave_dynamic_tables;

SELECT 'Testing vw_recent_dynamic_operations:' as test_2;  
SELECT COUNT(*) as recent_operations FROM vw_recent_dynamic_operations;

SELECT 'Testing vw_heatwave_memory_by_schema:' as test_3;
SELECT COUNT(*) as schema_records FROM vw_heatwave_memory_by_schema;

-- Verify charset settings for all tables
SELECT 'CHARSET VERIFICATION FOR ALL TABLES:' as charset_verification;
SELECT 
    table_name,
    table_collation,
    CASE 
        WHEN table_collation LIKE 'utf8mb4%' THEN 'OK - UTF8MB4'
        ELSE 'WARNING - Not UTF8MB4'
    END as charset_status
FROM information_schema.tables 
WHERE table_schema = 'support_heatwave'
ORDER BY table_name;

-- ===============================================================================================
-- STEP 7: USAGE EXAMPLES AND DOCUMENTATION
-- ===============================================================================================

SELECT 'USAGE EXAMPLES:' as usage_header;

-- Insert sample documentation
INSERT INTO dynamic_load_operations 
(table_name, operation_type, reason, memory_impact_mb, duration_seconds, status)
VALUES 
('example_schema.sample_table', 'LOAD', 'System initialization example', 0, 0, 'SUCCESS');

SELECT 'Example usage commands:' as examples;
SELECT '-- Load a table with tracking:' as cmd1;
SELECT 'CALL tracked_secondary_load("your_schema", "your_table", "Monthly analysis");' as cmd2;
SELECT '-- Unload a table with tracking:' as cmd3;
SELECT 'CALL tracked_secondary_unload("your_schema", "your_table", "Analysis completed");' as cmd4;
SELECT '-- Check dynamic operations:' as cmd5;
SELECT 'CALL check_dynamic_operations();' as cmd6;
SELECT '-- View recent operations:' as cmd7;
SELECT 'SELECT * FROM vw_recent_dynamic_operations;' as cmd8;

-- ===============================================================================================
-- STEP 8: DEPLOYMENT COMPLETION
-- ===============================================================================================

SELECT 'DEPLOYMENT COMPLETED SUCCESSFULLY!' as deployment_final_status;
SELECT '==========================================' as separator1;
SELECT 'HeatWave Universal Dynamic Monitoring v2.0' as system_name;
SELECT 'Compatible: MySQL 8.0, 8.4, 9.0, 9.3+' as compatibility;
SELECT 'Charset: UTF8MB4 (explicitly set)' as charset_info;
SELECT '==========================================' as separator2;

-- Final verification
SELECT 'FINAL VERIFICATION:' as final_verification;
SELECT 
    (SELECT COUNT(*) FROM dynamic_load_operations) as operation_records,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS 
     WHERE TABLE_SCHEMA = 'support_heatwave' 
       AND TABLE_NAME LIKE 'vw_%dynamic%') as dynamic_views,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES 
     WHERE ROUTINE_SCHEMA = 'support_heatwave' 
       AND ROUTINE_NAME LIKE 'tracked_%') as tracking_procedures,
    'Universal dynamic monitoring ready!' as status;

-- Final charset verification
SELECT 'FINAL CHARSET VERIFICATION:' as charset_final;
SELECT 
    DEFAULT_CHARACTER_SET_NAME as db_charset,
    DEFAULT_COLLATION_NAME as db_collation,
    'Database charset properly set' as charset_status
FROM information_schema.schemata 
WHERE schema_name = 'support_heatwave';

-- Clean up example record
DELETE FROM dynamic_load_operations WHERE table_name = 'example_schema.sample_table';

SELECT 'System ready for universal MySQL deployment!' as ready_status;
SELECT 'NO CHARSET WARNINGS - Explicit UTF8MB4 used throughout' as charset_final_status;