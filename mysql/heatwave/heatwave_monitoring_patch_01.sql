-- ===============================================================================================
-- MISSING VIEWS PATCH FOR HEATWAVE MONITORING SYSTEM
-- This patch adds views that were referenced but missing from the main deployment
--
--   SOURCE /mnt/fs-share-devqa/server-config/mysqlendb/mysql_heatwave/heatwave_monitoring_deployment_v1.sql;
-- ===============================================================================================

USE support_heatwave;

SELECT '🔧 Adding missing views to HeatWave Monitoring System...' as patch_status;

-- ===============================================================================================
-- VIEW: vw_heatwave_memory_by_schema
-- Memory usage breakdown by schema with rollup totals
-- ===============================================================================================

CREATE OR REPLACE VIEW vw_heatwave_memory_by_schema AS
SELECT 
    IFNULL(tid.SCHEMA_NAME, 'TOTAL') as schema_name,
    COUNT(*) as loaded_tables,
    ROUND(SUM(t_id.SIZE_BYTES) / (1024 * 1024), 2) as total_memory_mb,
    ROUND(SUM(t_id.SIZE_BYTES) / (1024 * 1024 * 1024), 2) as total_memory_gb,
    ROUND(
        (SUM(t_id.SIZE_BYTES) / (1024 * 1024 * 1024)) / 
        CAST(get_config_value('cluster_memory_gb') AS DECIMAL(10,2)) * 100, 1
    ) as memory_utilization_percent
FROM performance_schema.rpd_tables t_id
JOIN performance_schema.rpd_table_id tid ON t_id.ID = tid.ID
WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE'
GROUP BY tid.SCHEMA_NAME WITH ROLLUP
ORDER BY total_memory_gb DESC;

-- ===============================================================================================
-- VIEW: vw_heatwave_total_memory_usage  
-- Simple total memory usage view (was in original scripts)
-- ===============================================================================================

CREATE OR REPLACE VIEW vw_heatwave_total_memory_usage AS
SELECT 
    NOW() AS collected_at,
    ROUND(SUM(t_id.SIZE_BYTES) / (1024 * 1024 * 1024), 2) AS total_memory_used_gb,
    CAST(get_config_value('cluster_memory_gb') AS DECIMAL(10,2)) as cluster_capacity_gb,
    ROUND(
        (SUM(t_id.SIZE_BYTES) / (1024 * 1024 * 1024)) / 
        CAST(get_config_value('cluster_memory_gb') AS DECIMAL(10,2)) * 100, 1
    ) as utilization_percent
FROM performance_schema.rpd_tables AS t_id
JOIN performance_schema.rpd_table_id AS tid ON t_id.ID = tid.ID
WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE';

-- ===============================================================================================
-- VIEW: vw_heatwave_loaded_tables
-- Enhanced version of the original view with memory info
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
-- VIEW: vw_heatwave_config_vs_reality
-- Shows the disconnect between configuration and actual memory usage
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
-- VIEW: vw_monitoring_summary
-- High-level summary for quick status checks
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
-- VERIFICATION AND TESTING
-- ===============================================================================================

SELECT '✅ Missing views have been created successfully!' as patch_complete;

-- Test all the views
SELECT 'Testing vw_heatwave_memory_by_schema:' as test_1;
SELECT * FROM vw_heatwave_memory_by_schema;

SELECT 'Testing vw_heatwave_total_memory_usage:' as test_2;  
SELECT * FROM vw_heatwave_total_memory_usage;

SELECT 'Testing vw_monitoring_summary:' as test_3;
SELECT * FROM vw_monitoring_summary;

SELECT 'Testing vw_heatwave_config_vs_reality (sample):' as test_4;
SELECT category, COUNT(*) as table_count
FROM vw_heatwave_config_vs_reality 
GROUP BY category;

SELECT '🎉 All missing views are now available and tested!' as patch_final_status;