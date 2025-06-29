-- ===============================================================================================
-- HEATWAVE MONITORING SYSTEM - MISSING VIEWS RESTORATION PATCH
-- Purpose: Add ONLY the missing critical views that failed to create
-- This patch focuses ONLY on view creation with error checking
-- ===============================================================================================

USE support_heatwave;

SELECT '[PATCH] Restoring Missing Critical Views' as patch_info;
SELECT '[INFO] Adding 8 missing views including vw_monitoring_dashboard' as patch_purpose;
SELECT CONCAT('Patch Time: ', NOW()) as patch_time;

-- Check if functions exist first
SELECT '[CHECK] Verifying required functions exist...' as function_check;
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'support_heatwave' AND routine_name = 'get_config_value') > 0 
        THEN '[OK] get_config_value function exists'
        ELSE '[ERROR] get_config_value function missing!'
    END as get_config_check;

-- ===============================================================================================
-- 1. MAIN MONITORING DASHBOARD (Most Critical)
-- ===============================================================================================

SELECT '[CREATE] Creating vw_monitoring_dashboard...' as create_dashboard;

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

-- Verify dashboard was created
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'support_heatwave' AND table_name = 'vw_monitoring_dashboard') > 0 
        THEN '[SUCCESS] vw_monitoring_dashboard created'
        ELSE '[ERROR] vw_monitoring_dashboard FAILED to create'
    END as dashboard_result;

-- ===============================================================================================
-- 2. MONITORING SUMMARY VIEW
-- ===============================================================================================

SELECT '[CREATE] Creating vw_monitoring_summary...' as create_summary;

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
-- 3. MEMORY ANALYSIS VIEW (Might conflict with existing)
-- ===============================================================================================

SELECT '[CREATE] Creating vw_heatwave_memory_analysis...' as create_memory_analysis;

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

-- ===============================================================================================
-- 4. CONFIG VS REALITY VIEW
-- ===============================================================================================

SELECT '[CREATE] Creating vw_heatwave_config_vs_reality...' as create_config_reality;

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
-- 5. SUPPORTING VIEWS
-- ===============================================================================================

SELECT '[CREATE] Creating supporting views...' as create_supporting;

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

-- Enhanced monitoring view for dynamic tables (if not exists)
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
-- VERIFICATION
-- ===============================================================================================

SELECT '[VERIFICATION] Checking all views were created...' as verification_header;

SELECT 
    '[DASHBOARD]' as view_category,
    'vw_monitoring_dashboard' as view_name,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'support_heatwave' AND table_name = 'vw_monitoring_dashboard') > 0 
        THEN '[SUCCESS] Created'
        ELSE '[FAILED] Missing'
    END as status
UNION ALL
SELECT 
    '[SUMMARY]',
    'vw_monitoring_summary',
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'support_heatwave' AND table_name = 'vw_monitoring_summary') > 0 
        THEN '[SUCCESS] Created'
        ELSE '[FAILED] Missing'
    END
UNION ALL
SELECT 
    '[MEMORY]',
    'vw_heatwave_memory_analysis',
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'support_heatwave' AND table_name = 'vw_heatwave_memory_analysis') > 0 
        THEN '[SUCCESS] Created'
        ELSE '[FAILED] Missing'
    END
UNION ALL
SELECT 
    '[CONFIG]',
    'vw_heatwave_config_vs_reality',
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'support_heatwave' AND table_name = 'vw_heatwave_config_vs_reality') > 0 
        THEN '[SUCCESS] Created'
        ELSE '[FAILED] Missing'
    END;

-- Test the main dashboard if it exists
SELECT '[TEST] Testing main dashboard...' as test_header;

-- This should work now!
SELECT * FROM vw_monitoring_dashboard 
ORDER BY 
    CASE section
        WHEN 'System Info' THEN 1
        WHEN 'Configuration' THEN 2
        WHEN 'Current State' THEN 3
        WHEN 'RAPID Engine' THEN 4
        WHEN 'Memory Usage' THEN 5
        WHEN 'Activity (24h)' THEN 6
        ELSE 7
    END, metric
LIMIT 5;

SELECT '[SUCCESS] Missing views restoration completed!' as final_status;

-- ===============================================================================================
-- END OF MISSING VIEWS PATCH
-- ===============================================================================================