-- ===============================================================================================
-- HEATWAVE MONITORING SYSTEM - DYNAMIC OPERATIONS TRACKING - FIXED VERSION
-- This patch adds dynamic loading operations tracking - NO EMOJIS
-- Purpose: Track dynamic load/unload operations with operation history
--
-- SOURCE /mnt/fs-share-devqa/server-config/mysqlendb/mysql_heatwave/heatwave_monitoring_patch_03_FIXED.sql;
-- ===============================================================================================

USE support_heatwave;

SELECT 'Adding dynamic operations tracking to HeatWave Monitoring System...' as patch_status;
SELECT 'This patch adds tracked load/unload procedures and operation history' as patch_purpose;
SELECT CONCAT('Patch Time: ', NOW()) as patch_time;

-- ===============================================================================================
-- ADD DYNAMIC OPERATIONS TRACKING TABLE
-- ===============================================================================================

-- Track dynamic loading operations
CREATE TABLE IF NOT EXISTS dynamic_load_operations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    operation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(64) NOT NULL,
    operation_type ENUM('LOAD', 'UNLOAD', 'REFRESH') NOT NULL,
    reason VARCHAR(255),
    memory_impact_mb DECIMAL(10,2),
    duration_seconds DECIMAL(6,3),
    status ENUM('SUCCESS', 'FAILED', 'IN_PROGRESS') DEFAULT 'SUCCESS',
    INDEX idx_operation_time (operation_time),
    INDEX idx_table_name (table_name)
) ENGINE=InnoDB COMMENT='Track dynamic HeatWave loading operations';

-- ===============================================================================================
-- ADD DYNAMIC TABLES MONITORING VIEW
-- ===============================================================================================

-- Enhanced monitoring view for dynamic tables (NO EMOJIS)
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

-- ===============================================================================================
-- ADD RECENT OPERATIONS VIEW (NO EMOJIS)
-- ===============================================================================================

-- View recent dynamic operations
CREATE OR REPLACE VIEW vw_recent_dynamic_operations AS
SELECT 
    operation_time,
    table_name,
    operation_type,
    reason,
    CONCAT(ABS(memory_impact_mb), ' MB') as memory_change,
    CASE 
        WHEN memory_impact_mb > 0 THEN '[ADDED] Memory Added'
        WHEN memory_impact_mb < 0 THEN '[FREED] Memory Freed'
        ELSE '[NOCHANGE] No Change'
    END as impact_type,
    CONCAT(duration_seconds, 's') as duration,
    status
FROM dynamic_load_operations 
WHERE operation_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY operation_time DESC;

-- ===============================================================================================
-- ADD TRACKED LOAD/UNLOAD PROCEDURES (NO EMOJIS)
-- ===============================================================================================

DELIMITER //

-- Enhanced procedure to track load operations
CREATE PROCEDURE tracked_secondary_load(
    IN schema_name VARCHAR(64),
    IN table_name VARCHAR(64),
    IN reason VARCHAR(255)
)
COMMENT 'Load table to HeatWave with operation tracking'
BEGIN
    DECLARE start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration_sec DECIMAL(6,3);
    DECLARE memory_before DECIMAL(10,2) DEFAULT 0;
    DECLARE memory_after DECIMAL(10,2) DEFAULT 0;
    DECLARE operation_status VARCHAR(10) DEFAULT 'SUCCESS';
    
    -- Get memory before
    SELECT IFNULL(
        (SELECT ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2)
         FROM performance_schema.rpd_tables t_id
         JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
         WHERE tid.SCHEMA_NAME = schema_name AND tid.NAME = table_name
           AND t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'), 0
    ) INTO memory_before;
    
    -- Perform the load operation
    BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET operation_status = 'FAILED';
            GET DIAGNOSTICS CONDITION 1
                @error_message = MESSAGE_TEXT;
        END;
        
        SET @sql = CONCAT('ALTER TABLE ', schema_name, '.', table_name, ' SECONDARY_LOAD');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END;
    
    SET end_time = CURRENT_TIMESTAMP;
    SET duration_sec = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000000;
    
    -- Get memory after (wait a moment for loading to complete)
    SELECT SLEEP(2);
    SELECT IFNULL(
        (SELECT ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2)
         FROM performance_schema.rpd_tables t_id
         JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
         WHERE tid.SCHEMA_NAME = schema_name AND tid.NAME = table_name
           AND t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'), 0
    ) INTO memory_after;
    
    -- Log the operation
    INSERT INTO dynamic_load_operations 
    (table_name, operation_type, reason, memory_impact_mb, duration_seconds, status)
    VALUES (CONCAT(schema_name, '.', table_name), 'LOAD', reason, 
            memory_after - memory_before, duration_sec, operation_status);
    
    -- Report results (NO EMOJIS)
    SELECT 
        CONCAT(schema_name, '.', table_name) as table_loaded,
        reason as operation_reason,
        CONCAT(memory_after - memory_before, ' MB') as memory_added,
        CONCAT(duration_sec, ' seconds') as load_time,
        operation_status as status;
END //

-- Enhanced procedure to track unload operations
CREATE PROCEDURE tracked_secondary_unload(
    IN schema_name VARCHAR(64),
    IN table_name VARCHAR(64),
    IN reason VARCHAR(255)
)
COMMENT 'Unload table from HeatWave with operation tracking'
BEGIN
    DECLARE start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration_sec DECIMAL(6,3);
    DECLARE memory_before DECIMAL(10,2) DEFAULT 0;
    DECLARE operation_status VARCHAR(10) DEFAULT 'SUCCESS';
    
    -- Get memory before
    SELECT IFNULL(
        (SELECT ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2)
         FROM performance_schema.rpd_tables t_id
         JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
         WHERE tid.SCHEMA_NAME = schema_name AND tid.NAME = table_name
           AND t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'), 0
    ) INTO memory_before;
    
    -- Perform the unload operation
    BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET operation_status = 'FAILED';
        END;
        
        SET @sql = CONCAT('ALTER TABLE ', schema_name, '.', table_name, ' SECONDARY_UNLOAD');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END;
    
    SET end_time = CURRENT_TIMESTAMP;
    SET duration_sec = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000000;
    
    -- Log the operation
    INSERT INTO dynamic_load_operations 
    (table_name, operation_type, reason, memory_impact_mb, duration_seconds, status)
    VALUES (CONCAT(schema_name, '.', table_name), 'UNLOAD', reason, 
            -memory_before, duration_sec, operation_status);
    
    -- Report results (NO EMOJIS)
    SELECT 
        CONCAT(schema_name, '.', table_name) as table_unloaded,
        reason as operation_reason,
        CONCAT(memory_before, ' MB') as memory_freed,
        CONCAT(duration_sec, ' seconds') as unload_time,
        operation_status as status;
END //

DELIMITER ;

-- ===============================================================================================
-- VERIFICATION AND COMPLETION
-- ===============================================================================================

SELECT '[SUCCESS] Dynamic operations tracking added successfully!' as patch_complete;
SELECT '[INFO] Added tracked_secondary_load() and tracked_secondary_unload() procedures' as procedures_added;
SELECT '[INFO] Added vw_heatwave_dynamic_tables and vw_recent_dynamic_operations views' as views_added;
SELECT '[INFO] All output cleaned of emoji icons for UTF8 compatibility' as compatibility_note;

-- Usage examples (commented for reference)
SELECT '[USAGE] Example usage:' as usage_header;
SELECT '-- Load with tracking:' as example_1;
SELECT '-- CALL tracked_secondary_load("your_schema", "table_name", "Monthly analysis");' as example_1_code;
SELECT '-- Unload with tracking:' as example_2;
SELECT '-- CALL tracked_secondary_unload("your_schema", "table_name", "Analysis completed");' as example_2_code;
SELECT '-- View recent operations:' as example_3;
SELECT '-- SELECT * FROM vw_recent_dynamic_operations;' as example_3_code;

-- Test the new views
SELECT '[TEST] Testing new views...' as test_header;
SELECT 
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'support_heatwave' AND table_name = 'dynamic_load_operations') as operations_table_created,
    (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'support_heatwave' AND table_name = 'vw_heatwave_dynamic_tables') as dynamic_view_created,
    (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'support_heatwave' AND table_name = 'vw_recent_dynamic_operations') as recent_ops_view_created;

SELECT '[COMPLETE] Dynamic operations tracking is ready to use!' as final_status;

-- ===============================================================================================
-- END OF PATCH 03 - FIXED VERSION
-- ===============================================================================================