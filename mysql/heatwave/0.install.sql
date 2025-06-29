-- Drop db 
drop database support_heatwave;

-- Step 1: Core system with universal charset
SOURCE heatwave_monitoring_patch_00.sql;
show tables;

-- Step 2: Add missing advanced views  
SOURCE heatwave_monitoring_patch_01.sql;
show tables;

-- Step 3: Add original basic views (for compatibility)
SOURCE heatwave_monitoring_patch_02.sql;
show tables;


-- Step 4: Add dynamic operations tracking (optional)
SOURCE heatwave_monitoring_patch_03.sql;
show tables;


-- Step 5: Remove icons which caused problem with charse between different db versions
SOURCE heatwave_monitoring_patch_04.sql;
show tables;


SOURCE heatwave_monitoring_patch_00.sql;
+------------------------------------+
| Tables_in_support_heatwave         |
+------------------------------------+
| c_monitoring_options               |
| monitoring_cleanup_log             |
| rapid_changes_detailed             |
| table_state_current                |
| vw_heatwave_secondary_load_summary |

SOURCE heatwave_monitoring_patch_01.sql;
+------------------------------------+
| Tables_in_support_heatwave         |
+------------------------------------+
| c_monitoring_options               |
| monitoring_cleanup_log             |
| rapid_changes_detailed             |
| table_state_current                |
| vw_heatwave_memory_by_schema       |
| vw_heatwave_secondary_load_summary |
| vw_heatwave_total_memory_usage     |
+------------------------------------+
7 rows in set (0.0021 sec)

SOURCE heatwave_monitoring_patch_02.sql;

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
| vw_heatwave_memory_by_schema       |
| vw_heatwave_memory_usage_summary   |
| vw_heatwave_secondary_load_details |
| vw_heatwave_secondary_load_summary |
| vw_heatwave_table_collation        |
| vw_heatwave_total_memory_usage     |
+---------------------------

SOURCE heatwave_monitoring_patch_03.sql;

uery OK, 0 rows affected, 2 warnings (0.0035 sec)
Warning (code 1300): Cannot convert string '\xF0\x9F\x93\x88 M...' from utf8mb4 to utf8mb3
Warning (code 1300): Cannot convert string '\xF0\x9F\x93\x89 M...' from utf8mb4 to utf8mb3

+------------------------------------+
| Tables_in_support_heatwave         |
+------------------------------------+
| c_monitoring_options               |
| db_version                         |
| dynamic_load_operations            |
| monitoring_cleanup_log             |
| rapid_changes_detailed             |
| table_state_current                |
| vw_heatwave_db_collation           |
| vw_heatwave_failed_to_load         |
| vw_heatwave_loaded_tables          |
| vw_heatwave_memory_by_schema       |
| vw_heatwave_memory_usage_summary   |
| vw_heatwave_secondary_load_details |
| vw_heatwave_secondary_load_summary |
| vw_heatwave_table_collation        |
| vw_heatwave_total_memory_usage     |
| vw_recent_dynamic_operations       |
+------------------------------------+
16 rows in set (0.0020 sec)


SOURCE heatwave_monitoring_patch_04.sql;
+------------------------------------+
| Tables_in_support_heatwave         |
+------------------------------------+
| c_monitoring_options               |
| db_version                         |
| dynamic_load_operations            |
| monitoring_cleanup_log             |
| rapid_changes_detailed             |
| table_state_current                |
| vw_heatwave_db_collation           |
| vw_heatwave_failed_to_load         |
| vw_heatwave_loaded_tables          |
| vw_heatwave_memory_by_schema       |
| vw_heatwave_memory_usage_summary   |
| vw_heatwave_secondary_load_details |
| vw_heatwave_secondary_load_summary |
| vw_heatwave_table_collation        |
| vw_heatwave_total_memory_usage     |
| vw_recent_dynamic_operations       |
+------------------------------------+
16 rows in set (0.0019 sec)

