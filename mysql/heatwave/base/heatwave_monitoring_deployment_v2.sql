-- ===============================================================================================
-- HEATWAVE MONITORING SYSTEM - DYNAMIC OPERATIONS TRACKING (CLEAN VERSION)
-- Version: 2.0 - UTF8 Compatible (No Emoji Icons)
-- Integration with your existing monitoring system
-- ===============================================================================================

USE support_heatwave;

-- Track dynamic loading operations
CREATE TABLE dynamic_load_operations (
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
     WHERE dlo.table_name = tsc.table_name 
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

-- Enhanced procedure to track operations
DELIMITER //

CREATE PROCEDURE tracked_secondary_load(
    IN schema_name VARCHAR(64),
    IN table_name VARCHAR(64),
    IN reason VARCHAR(255)
)
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

CREATE PROCEDURE tracked_secondary_unload(
    IN schema_name VARCHAR(64),
    IN table_name VARCHAR(64),
    IN reason VARCHAR(255)
)
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

-- Usage examples with tracking:
-- CALL tracked_secondary_load('your_schema', 'p_trx_extended_24m', 'Monthly analysis request');
-- CALL tracked_secondary_unload('your_schema', 'p_trx_extended_24m', 'Analysis completed');

-- View recent dynamic operations (NO EMOJIS)
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
        ELSE '[NONE] No Change'
    END as impact_type,
    CONCAT(duration_seconds, 's') as duration,
    status
FROM dynamic_load_operations 
WHERE operation_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY operation_time DESC;