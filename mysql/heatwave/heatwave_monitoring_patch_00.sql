-- Run script from mysql 
-- USE support_heatwave;
-- SOURCE /mnt/fs-share-devqa/server-config/mysqlendb/mysql_heatwave/db_support_heatwave.sql
--
-- Step 1: Create the monitoring database
CREATE DATABASE IF NOT EXISTS  support_heatwave ;

USE support_heatwave;

-- Step 2: Create a version tracking table
CREATE TABLE IF NOT EXISTS db_version (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(10) NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `desc` TEXT
);

-- Step 3: Insert initial version entry
INSERT INTO db_version (version, `desc`)
VALUES ('1.0', 'Initial version with monitoring views for HeatWave: loaded tables, failed loads, memory usage, collation checks, secondary_load status.');

-- Step 4: Create views

-- View 1: Tables loaded to HeatWave
CREATE OR REPLACE VIEW vw_heatwave_loaded_tables AS
SELECT
    tid.SCHEMA_NAME AS table_schema,
    tid.NAME AS table_name,
    t_id.POOL_TYPE,
    t_id.LOAD_STATUS,
    ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2) AS memory_used_mb,
    t_id.QUERY_COUNT,
    t_id.LAST_QUERIED,
    t_id.LOAD_END_TIMESTAMP
FROM performance_schema.rpd_tables AS t_id
JOIN performance_schema.rpd_table_id AS tid ON t_id.ID = tid.ID
WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE';

-- View 2: Tables marked for auto-load to HeatWave
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

-- View 3: Tables failed to load to HeatWave (not in AVAIL state)
CREATE OR REPLACE VIEW vw_heatwave_failed_to_load AS
SELECT
    tid.SCHEMA_NAME AS table_schema,
    tid.NAME AS table_name,
    t_id.POOL_TYPE,
    t_id.LOAD_STATUS,
    ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2) AS memory_used_mb,
    t_id.LAST_QUERIED,
    t_id.LOAD_END_TIMESTAMP
FROM performance_schema.rpd_tables AS t_id
JOIN performance_schema.rpd_table_id AS tid ON t_id.ID = tid.ID
WHERE t_id.LOAD_STATUS != 'AVAIL_RPDGSTABSTATE';

-- View 4: Total memory usage by HeatWave tables
CREATE OR REPLACE VIEW vw_heatwave_memory_usage_summary AS
SELECT 
    tid.SCHEMA_NAME AS table_schema,
    tid.NAME AS table_name,
    ROUND(t_id.SIZE_BYTES / (1024 * 1024), 2) AS memory_used_mb
FROM performance_schema.rpd_tables AS t_id
JOIN performance_schema.rpd_table_id AS tid ON t_id.ID = tid.ID;

-- View 5: Tables eligible for HeatWave but not marked to auto-load
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

-- View 6: Eligible tables not marked AND not currently loaded
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

-- View 7: Collation of each database
CREATE OR REPLACE VIEW vw_heatwave_db_collation AS
SELECT 
    SCHEMA_NAME AS database_name,
    DEFAULT_COLLATION_NAME AS collation
FROM information_schema.schemata;

-- View 8: Collation of each table
CREATE OR REPLACE VIEW vw_heatwave_table_collation AS
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_COLLATION
FROM information_schema.tables
WHERE TABLE_TYPE = 'BASE TABLE';

-- -------------
CREATE OR REPLACE VIEW vw_heatwave_total_memory_usage AS
SELECT 
    NOW() AS collected_at,
    ROUND(SUM(t_id.SIZE_BYTES) / (1024 * 1024 * 1024), 2) AS total_memory_used_gb
FROM performance_schema.rpd_tables AS t_id
JOIN performance_schema.rpd_table_id AS tid ON t_id.ID = tid.ID
WHERE t_id.LOAD_STATUS = 'AVAIL_RPDGSTABSTATE';

INSERT INTO db_version (version, `desc`)
VALUES ('1.1', 'Added view vw_heatwave_total_memory_usage to show total memory used by HeatWave engine for loaded tables.');


-- --
CREATE OR REPLACE VIEW vw_heatwave_secondary_load_details AS
SELECT *
FROM INFORMATION_SCHEMA.TABLES
WHERE CREATE_OPTIONS LIKE '%SECONDARY_LOAD=%';


CREATE OR REPLACE VIEW vw_heatwave_secondary_load_summary AS
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    CREATE_OPTIONS
FROM INFORMATION_SCHEMA.TABLES
WHERE CREATE_OPTIONS LIKE '%SECONDARY_LOAD=%';


INSERT INTO db_version (version, `desc`)
VALUES ('1.2', 'Added views vw_heatwave_secondary_load_details and vw_heatwave_secondary_load_summary to show tables with explicit SECONDARY_LOAD setting.');

