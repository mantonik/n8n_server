- 1. Drop everything and start fresh
DROP DATABASE IF EXISTS support_heatwave;

-- 2. Deploy original files in sequence
SOURCE db_support_heatwave.sql;
SOURCE heatwave_monitoring_deployment.sql;
SOURCE heatwave_monitoring_deployment_v1.sql;
SOURCE heatwave_monitoring_deployment_v2.sql; -- optional
SOURCE heatwave_monitoring_deployment_v2_clean.sql; -
-- Should show your dashboard
SELECT * FROM vw_monitoring_dashboard;

-- update to 16GB memory for FREE MySQL Heatwave
update c_monitoring_options set option_value=16 where id =4 and option_name ='cluster_memory_gb';
commit;

-- List all objects
SHOW TABLES IN support_heatwave;

/*
SOURCE db_support_heatwave.sql;
+------------------------------------+
| Tables_in_support_heatwave         |
+------------------------------------+
| db_version                         |
| vw_heatwave_db_collation           |
| vw_heatwave_failed_to_load         |
| vw_heatwave_loaded_tables          |
| vw_heatwave_memory_usage_summary   |
| vw_heatwave_secondary_load_details |
| vw_heatwave_secondary_load_summary |
| vw_heatwave_table_collation        |
| vw_heatwave_total_memory_usage     |
+------------------------------------+
9 rows in set (0.0021 sec)

SOURCE heatwave_monitoring_deployment.sql;
+------------------------------------+
| Tables_in_support_heatwave         |
+------------------------------------+
| c_monitoring_options               |
| db_version                         |
| monitoring_cleanup_log             |
| rapid_changes_detailed             |
| table_state_current                |
| vw_heatwave_db_collation           |
| vw_heatwave_failed_to_load         |
| vw_heatwave_loaded_tables          |
| vw_heatwave_memory_analysis        |
| vw_heatwave_memory_usage_summary   |
| vw_heatwave_secondary_load_details |
| vw_heatwave_secondary_load_summary |
| vw_heatwave_table_collation        |
| vw_heatwave_total_memory_usage     |
| vw_monitoring_dashboard            |
+------------------------------------+

SOURCE heatwave_monitoring_deployment_v1.sql;

+------------------------------------+
| Tables_in_support_heatwave         |
+------------------------------------+
| c_monitoring_options               |
| db_version                         |
| monitoring_cleanup_log             |
| rapid_changes_detailed             |
| table_state_current                |
| vw_heatwave_config_vs_reality      |
| vw_heatwave_db_collation           |
| vw_heatwave_failed_to_load         |
| vw_heatwave_loaded_tables          |
| vw_heatwave_memory_analysis        |
| vw_heatwave_memory_by_schema       |
| vw_heatwave_memory_usage_summary   |
| vw_heatwave_secondary_load_details |
| vw_heatwave_secondary_load_summary |
| vw_heatwave_table_collation        |
| vw_heatwave_total_memory_usage     |
| vw_monitoring_dashboard            |
| vw_monitoring_summary              |
+------------------------------------+
18 rows in set (0.0026 sec)


SOURCE heatwave_monitoring_deployment_v2.sql; 
+------------------------------------+
| Tables_in_support_heatwave         |
+------------------------------------+
| c_monitoring_options               |
| db_version                         |
| dynamic_load_operations            |
| monitoring_cleanup_log             |
| rapid_changes_detailed             |
| table_state_current                |
| vw_heatwave_config_vs_reality      |
| vw_heatwave_db_collation           |
| vw_heatwave_dynamic_tables         |
| vw_heatwave_failed_to_load         |
| vw_heatwave_loaded_tables          |
| vw_heatwave_memory_analysis        |
| vw_heatwave_memory_by_schema       |
| vw_heatwave_memory_usage_summary   |
| vw_heatwave_secondary_load_details |
| vw_heatwave_secondary_load_summary |
| vw_heatwave_table_collation        |
| vw_heatwave_total_memory_usage     |
| vw_monitoring_dashboard            |
| vw_monitoring_summary              |
| vw_recent_dynamic_operations       |
+------------------------------------+
21 row

Query OK, 0 rows affected, 2 warnings (0.0043 sec)
Warning (code 1300): Cannot convert string '\xF0\x9F\x93\x88 M...' from utf8mb4 to utf8mb3
Warning (code 1300): Cannot convert string '\xF0\x9F\x93\x89 M...' from utf8mb4 to utf8mb3

*/