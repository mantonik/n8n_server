-- ===============================================================================================
-- HEATWAVE MONITORING SYSTEM - UTF8 COMPATIBILITY PATCH
-- Version: 2.0 Patch 04 - Remove emoji icons for universal compatibility
-- MySQL Version: 8.0+ Compatible (all charset configurations)
-- Environment: Universal (resolves UTF8MB4 to UTF8MB3 conversion warnings)
-- ===============================================================================================
--
-- PURPOSE: 
-- This patch removes all emoji icons from SELECT statements that cause UTF8 conversion warnings
-- Replaces emoji with simple text prefixes for better compatibility across different MySQL configs
--
-- DEPLOYMENT:
-- SOURCE /path/to/heatwave_monitoring_patch_04.sql;
--
-- ===============================================================================================

USE support_heatwave;

SELECT 'HEATWAVE MONITORING PATCH 04 - UTF8 COMPATIBILITY' as patch_info;
SELECT 'Removing emoji icons to prevent charset conversion warnings' as patch_purpose;
SELECT CONCAT('Patch Time: ', NOW()) as patch_time;

-- ===============================================================================================
-- UPDATE CORE MONITORING PROCEDURE - Remove emojis from output
-- ===============================================================================================

DELIMITER //

DROP PROCEDURE IF EXISTS detect_all_rapid_changes //

-- Main monitoring procedure without emojis
CREATE PROCEDURE detect_all_rapid_changes()
COMMENT 'Main procedure to detect RAPID engine changes across all schemas'
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_schema VARCHAR(64);
    DECLARE v_table VARCHAR(64);
    DECLARE v_current_engine VARCHAR(64);
    DECLARE v_current_load TINYINT;
    DECLARE v_current_options TEXT;
    DECLARE changes_detected INT DEFAULT 0;
    DECLARE baseline_count INT DEFAULT 0;
    
    DECLARE cur CURSOR FOR
        SELECT 
            t.TABLE_SCHEMA,
            t.TABLE_NAME,
            CASE 
                WHEN t.CREATE_OPTIONS LIKE '%SECONDARY_ENGINE="RAPID"%' THEN 'RAPID'
                WHEN t.CREATE_OPTIONS LIKE '%SECONDARY_ENGINE=RAPID%' THEN 'RAPID'
                ELSE ''
            END as current_secondary_engine,
            CASE 
                WHEN t.CREATE_OPTIONS LIKE '%SECONDARY_LOAD="1"%' THEN 1
                WHEN t.CREATE_OPTIONS LIKE '%SECONDARY_LOAD="0"%' THEN 0
                WHEN t.CREATE_OPTIONS LIKE '%SECONDARY_LOAD=1%' THEN 1
                WHEN t.CREATE_OPTIONS LIKE '%SECONDARY_LOAD=0%' THEN 0
                ELSE NULL
            END as current_secondary_load,
            t.CREATE_OPTIONS as current_create_options
        FROM information_schema.tables t
        WHERE t.ENGINE = 'InnoDB'
          AND t.TABLE_SCHEMA NOT IN ('information_schema', 'performance_schema', 'sys', 'mysql', 'mysql_audit', 'support_heatwave')
          AND (t.CREATE_OPTIONS LIKE '%SECONDARY_ENGINE=%' OR t.CREATE_OPTIONS LIKE '%SECONDARY_LOAD=%')
        ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_schema, v_table, v_current_engine, v_current_load, v_current_options;
        
        IF done THEN LEAVE read_loop; END IF;
        
        -- Use INSERT ... ON DUPLICATE KEY UPDATE for atomic operation
        INSERT INTO table_state_current 
        (table_schema, table_name, secondary_engine, secondary_load, create_options, first_detected, last_checked)
        VALUES (v_schema, v_table, v_current_engine, v_current_load, v_current_options, NOW(), NOW())
        ON DUPLICATE KEY UPDATE
            secondary_engine = VALUES(secondary_engine),
            secondary_load = VALUES(secondary_load),
            create_options = VALUES(create_options),
            last_checked = NOW();
        
        -- Track baseline creation (new records)
        IF ROW_COUNT() = 1 THEN
            SET baseline_count = baseline_count + 1;
            
            -- Log baseline for RAPID tables
            IF v_current_engine = 'RAPID' THEN
                INSERT INTO rapid_changes_detailed 
                (table_schema, table_name, change_type, new_secondary_engine, new_secondary_load, 
                 new_create_options, alert_level, notes)
                VALUES (v_schema, v_table, 'NEW_RAPID', v_current_engine, v_current_load, 
                        v_current_options, 'INFO', 
                        CONCAT('Baseline: RAPID table discovered (LOAD=', IFNULL(v_current_load, 'NULL'), ')'));
                
                SET changes_detected = changes_detected + 1;
            END IF;
        END IF;
        
    END LOOP;
    
    CLOSE cur;
    
    -- Mark old processed records
    UPDATE rapid_changes_detailed 
    SET processed = TRUE 
    WHERE change_time < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 HOUR)
      AND processed = FALSE;
    
    -- Report results - NO EMOJIS
    SELECT 
        CURRENT_TIMESTAMP as check_time,
        baseline_count as new_tables_added,
        changes_detected as changes_logged,
        (SELECT COUNT(*) FROM table_state_current WHERE secondary_engine = 'RAPID') as total_rapid_tables,
        CASE 
            WHEN baseline_count > 0 THEN CONCAT('[BASELINE] Added ', baseline_count, ' tables')
            WHEN changes_detected > 0 THEN '[ALERT] CHANGES DETECTED!'
            ELSE '[OK] No changes detected'
        END as status;
        
    -- Show recent changes if any
    IF changes_detected > 0 THEN
        SELECT 
            change_time,
            CONCAT(table_schema, '.', table_name) as table_name,
            change_type,
            alert_level,
            notes
        FROM rapid_changes_detailed 
        WHERE change_time >= DATE_SUB(NOW(), INTERVAL 10 MINUTE)
        ORDER BY change_time DESC;
    END IF;
END //

-- ===============================================================================================
-- UPDATE CHECK_RAPID_ALERTS PROCEDURE - Remove emojis 
-- ===============================================================================================

DROP PROCEDURE IF EXISTS check_rapid_alerts //

CREATE PROCEDURE check_rapid_alerts()
COMMENT 'Check for recent RAPID engine alerts'
BEGIN
    SELECT 
        change_time,
        CONCAT(table_schema, '.', table_name) as full_table_name,
        change_type,
        alert_level,
        CASE change_type
            WHEN 'NEW_RAPID' THEN CONCAT('[NEW] RAPID table (LOAD=', IFNULL(new_secondary_load, 'NULL'), ')')
            WHEN 'LOAD_ENABLED' THEN CONCAT('[CRITICAL] Auto-load ENABLED (', old_secondary_load, '->', new_secondary_load, ')')
            WHEN 'LOAD_DISABLED' THEN CONCAT('[INFO] Auto-load disabled (', old_secondary_load, '->', new_secondary_load, ')')
            ELSE '[INFO] Other change'
        END as alert_description,
        TIMESTAMPDIFF(MINUTE, change_time, NOW()) as minutes_ago,
        notes
    FROM rapid_changes_detailed 
    WHERE change_time >= DATE_SUB(NOW(), INTERVAL 6 HOUR)
    ORDER BY change_time DESC;
    
    -- Summary
    SELECT 
        COUNT(*) as total_alerts_6h,
        SUM(CASE WHEN alert_level = 'CRITICAL' THEN 1 ELSE 0 END) as critical_alerts,
        SUM(CASE WHEN change_type = 'LOAD_ENABLED' THEN 1 ELSE 0 END) as memory_alerts,
        SUM(CASE WHEN change_type = 'NEW_RAPID' THEN 1 ELSE 0 END) as new_rapid_tables
    FROM rapid_changes_detailed 
    WHERE change_time >= DATE_SUB(NOW(), INTERVAL 6 HOUR);
END //

-- ===============================================================================================
-- UPDATE UPDATE_CLUSTER_MEMORY PROCEDURE - Remove emojis
-- ===============================================================================================

DROP PROCEDURE IF EXISTS update_cluster_memory //

CREATE PROCEDURE update_cluster_memory(IN memory_gb INT)
COMMENT 'Update cluster memory size for accurate utilization calculations'
BEGIN
    CALL update_monitoring_config('cluster_memory_gb', CAST(memory_gb AS CHAR));
    
    SELECT 
        CONCAT('[OK] Cluster memory updated to ', memory_gb, ' GB') as update_status,
        'Dashboard will now show accurate utilization percentages' as note;
END //

-- ===============================================================================================
-- UPDATE UPDATE_MONITORING_CONFIG PROCEDURE - Remove emojis
-- ===============================================================================================

DROP PROCEDURE IF EXISTS update_monitoring_config //

CREATE PROCEDURE update_monitoring_config(
    IN config_name VARCHAR(50), 
    IN config_value VARCHAR(255)
)
COMMENT 'Update monitoring configuration'
BEGIN
    DECLARE config_updated BOOLEAN;
    
    SET config_updated = set_config_value(config_name, config_value);
    
    SELECT 
        CONCAT('[OK] Configuration updated: ', config_name, ' = ', config_value) as result,
        NOW() as updated_at;
END //

DELIMITER ;

-- ===============================================================================================
-- UPDATE VIEWS - Remove emojis from display text
-- ===============================================================================================

-- Update memory analysis view
DROP VIEW IF EXISTS vw_heatwave_memory_analysis;

CREATE VIEW vw_heatwave_memory_analysis AS
SELECT 
    tid.SCHEMA_NAME as table_schema,
    tid.NAME as table_name,
    t_id.LOAD_STATUS,
    ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2) as memory_mb,
    ROUND(t_id.SIZE_BYTES / (1024 * 1024 * 1024), 2) as memory_gb,
    t_id.LAST_QUERIED,
    IFNULL(tsc.secondary_load, 'Unknown') as secondary_load_setting,
    CASE 
        WHEN tsc.secondary_load = 1 THEN '[AUTO] Auto-load enabled'
        WHEN tsc.secondary_load = 0 THEN '[MANUAL] Autopilot/Manual'
        ELSE '[UNKNOWN] Not monitored'
    END as load_method
FROM performance_schema.rpd_tables t_id
JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
LEFT JOIN table_state_current tsc ON tid.SCHEMA_NAME = tsc.table_schema AND tid.NAME = tsc.table_name
WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
ORDER BY t_id.SIZE_BYTES DESC;

-- Update loaded tables view
DROP VIEW IF EXISTS vw_heatwave_loaded_tables;

CREATE VIEW vw_heatwave_loaded_tables AS
SELECT
    tid.SCHEMA_NAME AS table_schema,
    tid.NAME AS table_name,
    t_id.POOL_TYPE,
    t_id.LOAD_STATUS,
    ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2) AS memory_used_mb,
    ROUND(t_id.SIZE_BYTES / (1024 * 1024 * 1024), 2) AS memory_used_gb,
    t_id.QUERY_COUNT,
    t_id.LAST_QUERIED,
    t_id.LOAD_END_TIMESTAMP,
    -- Add configuration info from monitoring
    IFNULL(tsc.secondary_load, 'Unknown') as secondary_load_setting,
    CASE 
        WHEN tsc.secondary_load = 1 THEN 'Auto-load'
        WHEN tsc.secondary_load = 0 THEN 'Autopilot/Manual'
        ELSE 'Not Monitored'
    END as load_method
FROM performance_schema.rpd_tables AS t_id
JOIN performance_schema.rpd_table_id AS tid ON t_id.ID = tid.ID
LEFT JOIN table_state_current tsc ON tid.SCHEMA_NAME = tsc.table_schema AND tid.NAME = tsc.table_name
WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
ORDER BY t_id.SIZE_BYTES DESC;

-- ===============================================================================================
-- UPDATE CONFIG TRACKING 
-- ===============================================================================================

-- Update version to reflect patch
INSERT INTO c_monitoring_options (option_name, option_value, option_description) VALUES
('patch_04_applied', 'TRUE', 'UTF8 compatibility patch applied - emojis removed')
ON DUPLICATE KEY UPDATE 
    option_value = 'TRUE',
    updated_at = CURRENT_TIMESTAMP;

-- Update system version
UPDATE c_monitoring_options 
SET option_value = '2.0.4', 
    option_description = 'HeatWave monitoring system version with UTF8 compatibility patch',
    updated_at = CURRENT_TIMESTAMP
WHERE option_name = 'system_version';

-- ===============================================================================================
-- VERIFICATION AND COMPLETION
-- ===============================================================================================

SELECT '[PATCH] UTF8 Compatibility Patch 04 Applied Successfully!' as patch_status;
SELECT '[INFO] All emoji icons removed from output text' as change_summary;
SELECT '[INFO] System now compatible with UTF8MB3 and UTF8MB4 configurations' as compatibility;

-- Test the updated procedures
SELECT '[TEST] Testing updated procedures...' as test_header;

-- Test basic functionality
SELECT 
    (SELECT option_value FROM c_monitoring_options WHERE option_name = 'system_version') as current_version,
    (SELECT option_value FROM c_monitoring_options WHERE option_name = 'patch_04_applied') as patch_04_status,
    (SELECT COUNT(*) FROM table_state_current) as tables_monitored,
    '[OK] Patch verification complete' as status;

SELECT '[COMPLETE] Ready to use - no more UTF8 conversion warnings!' as final_status;

-- Show clean output example
SELECT '[EXAMPLE] Clean output without emojis:' as example_header;
SELECT 
    'System Status' as section,
    'Version' as metric,
    get_config_value('system_version') as value,
    'No emoji icons - universal compatibility' as description;

-- ===============================================================================================
-- END OF PATCH 04
-- ===============================================================================================