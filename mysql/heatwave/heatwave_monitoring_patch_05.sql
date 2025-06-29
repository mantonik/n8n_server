-- ===============================================================================================
-- HEATWAVE MONITORING SYSTEM - RESTORE MISSING VIEWS PATCH
-- Version: 2.0 Patch 05 - Restore all missing critical views
-- Purpose: Restore vw_monitoring_dashboard and other essential views that got dropped
-- ===============================================================================================

USE support_heatwave;

SELECT '[PATCH 05] Restoring Missing Critical Views' as patch_info;
SELECT '[INFO] Recreating vw_monitoring_dashboard and 8 other essential views' as patch_purpose;
SELECT CONCAT('Patch Time: ', NOW()) as patch_time;

-- ===============================================================================================
-- RESTORE MAIN MONITORING DASHBOARD (Most Important)
-- ===============================================================================================

CREATE OR REPLACE VIEW vw_monitoring_dashboard AS
SELECT 
    'System Info' as section,
    'Version' as metric,
    get_config_value('system_version') as value,
    'Monitoring system version' as description
UNION ALL
SELECT 
    'System Info',
    'MySQL Version',
    VERSION(),
    'Database version'
UNION ALL
SELECT 
    'Configuration',
    'Cluster Memory',
    CONCAT(get_config_value('cluster_memory_gb'), ' GB'),
    'HeatWave cluster capacity'
UNION ALL
SELECT 
    'Configuration',
    'Data Retention',
    CONCAT(get_config_value('retention_days'), ' days'),
    'Data retention period'
UNION ALL
SELECT 
    'Current State',
    'Schemas Monitored',
    CAST(COUNT(DISTINCT table_schema) AS CHAR),
    'Number of schemas tracked'
FROM table_state_current
UNION ALL
SELECT 
    'Current State',
    'Total Tables',
    CAST(COUNT(*) AS CHAR),
    'All monitored tables'
FROM table_state_current
UNION ALL
SELECT 
    'RAPID Engine',
    'RAPID Tables',
    CAST(COUNT(*) AS CHAR),
    'Tables with SECONDARY_ENGINE=RAPID'
FROM table_state_current 
WHERE secondary_engine = 'RAPID'
UNION ALL
SELECT 
    'Memory Usage',
    'Actually Loaded',
    CAST(IFNULL((
        SELECT COUNT(*) 
        FROM performance_schema.rpd_tables t_id
        JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
        WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
    ), 0) AS CHAR),
    'Tables loaded in HeatWave memory'
UNION ALL
SELECT 
    'Memory Usage',
    'Memory Used',
    CONCAT(IFNULL((
        SELECT ROUND(SUM(t_id.SIZE_BYTES) / (1024 * 1024 * 1024), 2)
        FROM performance_schema.rpd_tables t_id
        JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
        WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
    ), 0), ' GB'),
    'Actual memory consumption'
UNION ALL
SELECT 
    'Memory Usage',
    'Utilization',
    CONCAT(IFNULL((
        SELECT ROUND(
            (SUM(t_id.SIZE_BYTES) / (1024 * 1024 * 1024)) / 
            CAST(get_config_value('cluster_memory_gb') AS DECIMAL(10,2)) * 100, 1
        )
        FROM performance_schema.rpd_tables t_id
        JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
        WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
    ), 0), '%'),
    'Cluster memory utilization'
UNION ALL
SELECT 
    'Activity (24h)',
    'Total Changes',
    CAST(COUNT(*) AS CHAR),
    'Changes detected today'
FROM rapid_changes_detailed 
WHERE change_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR);

-- ===============================================================================================
-- RESTORE MONITORING SUMMARY VIEW
-- ===============================================================================================

CREATE OR REPLACE VIEW vw_monitoring_summary AS
SELECT 
    'System Status' as metric_category,
    'Monitoring Version' as metric_name,
    get_config_value('system_version') as metric_value,
    'Current system version' as description

UNION ALL

SELECT 
    'System Status',
    'Last Monitoring Run',
    IFNULL(CAST(MAX(last_checked) AS CHAR), 'Never') as metric_value,
    'When monitoring last executed'
FROM table_state_current

UNION ALL

SELECT 
    'Table Counts',
    'Tables Monitored',
    CAST(COUNT(*) AS CHAR),
    'Total tables being tracked'
FROM table_state_current

UNION ALL

SELECT 
    'Table Counts',
    'RAPID Tables',
    CAST(COUNT(*) AS CHAR),
    'Tables with SECONDARY_ENGINE=RAPID'
FROM table_state_current 
WHERE secondary_engine = 'RAPID'

UNION ALL

SELECT 
    'Memory Status',
    'Tables Loaded',
    CAST(IFNULL((
        SELECT COUNT(*) 
        FROM performance_schema.rpd_tables t_id
        JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
        WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
    ), 0) AS CHAR),
    'Tables currently in HeatWave memory'

UNION ALL

SELECT 
    'Memory Status',
    'Memory Used (GB)',
    CAST(IFNULL((
        SELECT ROUND(SUM(t_id.SIZE_BYTES) / (1024 * 1024 * 1024), 2)
        FROM performance_schema.rpd_tables t_id
        JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
        WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
    ), 0) AS CHAR),
    'Actual memory consumption'

UNION ALL

SELECT 
    'Memory Status',
    'Cluster Utilization %',
    CAST(IFNULL((
        SELECT ROUND(
            (SUM(t_id.SIZE_BYTES) / (1024 * 1024 * 1024)) / 
            CAST(get_config_value('cluster_memory_gb') AS DECIMAL(10,2)) * 100, 1
        )
        FROM performance_schema.rpd_tables t_id
        JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
        WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
    ), 0) AS CHAR),
    'Percentage of cluster memory used'

UNION ALL

SELECT 
    'Configuration Issues',
    'Config Mismatches',
    CAST((
        -- Count tables loaded but not configured for auto-load
        SELECT COUNT(*)
        FROM performance_schema.rpd_tables t_id
        JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
        LEFT JOIN table_state_current tsc ON tid.SCHEMA_NAME = tsc.table_schema AND tid.NAME = tsc.table_name
        WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
          AND (tsc.secondary_load = 0 OR tsc.secondary_load IS NULL)
    ) AS CHAR),
    'Tables loaded but not configured for auto-load'

ORDER BY 
    CASE metric_category
        WHEN 'System Status' THEN 1
        WHEN 'Table Counts' THEN 2  
        WHEN 'Memory Status' THEN 3
        WHEN 'Configuration Issues' THEN 4
        ELSE 5
    END,
    metric_name;

-- ===============================================================================================
-- RESTORE MEMORY ANALYSIS VIEW
-- ===============================================================================================

CREATE OR REPLACE VIEW vw_heatwave_memory_analysis AS
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

-- ===============================================================================================
-- RESTORE CONFIG VS REALITY VIEW
-- ===============================================================================================

CREATE OR REPLACE VIEW vw_heatwave_config_vs_reality AS
-- Tables configured for auto-load but not actually loaded
SELECT 
    'CONFIGURED_NOT_LOADED' as category,
    tsc.table_schema,
    tsc.table_name,
    tsc.secondary_load,
    'Configured for auto-load but not loaded in memory' as status,
    NULL as memory_mb,
    tsc.last_checked
FROM table_state_current tsc
WHERE tsc.secondary_engine = 'RAPID' 
  AND tsc.secondary_load = 1
  AND NOT EXISTS (
      SELECT 1 FROM performance_schema.rpd_table_id tid 
      WHERE tid.SCHEMA_NAME = tsc.table_schema AND tid.NAME = tsc.table_name
  )

UNION ALL

-- Tables loaded in memory but not configured for auto-load  
SELECT 
    'LOADED_NOT_CONFIGURED' as category,
    tid.SCHEMA_NAME as table_schema,
    tid.NAME as table_name,
    IFNULL(tsc.secondary_load, 999) as secondary_load,
    'Loaded in memory but not configured for auto-load' as status,
    ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2) as memory_mb,
    IFNULL(tsc.last_checked, 'Not Monitored') as last_checked
FROM performance_schema.rpd_tables t_id
JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
LEFT JOIN table_state_current tsc ON tid.SCHEMA_NAME = tsc.table_schema AND tid.NAME = tsc.table_name
WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
  AND (tsc.secondary_load = 0 OR tsc.secondary_load IS NULL)

UNION ALL

-- Tables properly configured and loaded
SELECT 
    'PROPERLY_CONFIGURED' as category,
    tid.SCHEMA_NAME as table_schema,
    tid.NAME as table_name,
    tsc.secondary_load,
    'Configured for auto-load and loaded in memory' as status,
    ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2) as memory_mb,
    tsc.last_checked
FROM performance_schema.rpd_tables t_id
JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
JOIN table_state_current tsc ON tid.SCHEMA_NAME = tsc.table_schema AND tid.NAME = tsc.table_name
WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
  AND tsc.secondary_load = 1

ORDER BY category, memory_mb DESC;

-- ===============================================================================================
-- RESTORE LOADED TABLES VIEW
-- ===============================================================================================

CREATE OR REPLACE VIEW vw_heatwave_loaded_tables AS
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
-- RESTORE ADDITIONAL SUPPORTING VIEWS
-- ===============================================================================================

-- Tables marked for auto-load to HeatWave
CREATE OR REPLACE VIEW vw_heatwave_marked_for_load AS
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    ENGINE,
    SECONDARY_ENGINE,
    SECONDARY_LOAD
FROM information_schema.tables
WHERE ENGINE = 'InnoDB'
  AND SECONDARY_ENGINE = 'RAPID'
  AND SECONDARY_LOAD = 1;

-- Tables eligible for HeatWave but not marked to auto-load
CREATE OR REPLACE VIEW vw_heatwave_not_marked_for_load AS
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    ENGINE,
    SECONDARY_ENGINE,
    SECONDARY_LOAD
FROM information_schema.tables
WHERE ENGINE = 'InnoDB'
  AND SECONDARY_ENGINE = 'RAPID'
  AND SECONDARY_LOAD = 0;

-- Eligible tables not marked AND not currently loaded
CREATE OR REPLACE VIEW vw_heatwave_not_marked_and_not_loaded AS
SELECT 
    t.TABLE_SCHEMA,
    t.TABLE_NAME,
    t.SECONDARY_LOAD
FROM information_schema.tables t
LEFT JOIN performance_schema.rpd_table_id r 
    ON r.SCHEMA_NAME = t.TABLE_SCHEMA AND r.NAME = t.TABLE_NAME
WHERE t.ENGINE = 'InnoDB'
  AND t.SECONDARY_ENGINE = 'RAPID'
  AND t.SECONDARY_LOAD = 0
  AND r.ID IS NULL;

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

-- ===============================================================================================
-- UPDATE VERSION AND VERIFICATION
-- ===============================================================================================

-- Update version to reflect patch
INSERT INTO c_monitoring_options (option_name, option_value, option_description) VALUES
('patch_05_applied', 'TRUE', 'Missing views restoration patch applied')
ON DUPLICATE KEY UPDATE 
    option_value = 'TRUE',
    updated_at = CURRENT_TIMESTAMP;

-- Update system version
UPDATE c_monitoring_options 
SET option_value = '2.0.5', 
    option_description = 'HeatWave monitoring system with all critical views restored',
    updated_at = CURRENT_TIMESTAMP
WHERE option_name = 'system_version';

-- ===============================================================================================
-- VERIFICATION
-- ===============================================================================================

SELECT '[SUCCESS] All Missing Views Restored!' as patch_status;
SELECT '[INFO] vw_monitoring_dashboard is back and working' as dashboard_status;
SELECT '[INFO] 9 critical views have been recreated' as views_restored;

-- Test the main dashboard
SELECT '[TEST] Testing restored dashboard view...' as test_header;
SELECT * FROM vw_monitoring_dashboard ORDER BY 
    CASE section
        WHEN 'System Info' THEN 1
        WHEN 'Configuration' THEN 2
        WHEN 'Current State' THEN 3
        WHEN 'RAPID Engine' THEN 4
        WHEN 'Memory Usage' THEN 5
        WHEN 'Activity (24h)' THEN 6
        ELSE 7
    END, metric;

SELECT '[COMPLETE] Your dashboard is restored and ready to use!' as final_status;

-- ===============================================================================================
-- END OF PATCH 05
-- ===============================================================================================