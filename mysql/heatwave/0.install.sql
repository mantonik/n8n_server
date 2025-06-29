-- Drop db 
drop database support_heatwave;

-- Step 1: Core system with universal charset
SOURCE heatwave_monitoring_patch_00.sql;

-- Step 2: Add missing advanced views  
SOURCE heatwave_monitoring_patch_01.sql;

-- Step 3: Add original basic views (for compatibility)
SOURCE heatwave_monitoring_patch_02.sql;

-- Step 4: Add dynamic operations tracking (optional)
SOURCE heatwave_monitoring_patch_03.sql;

-- List all objects
SHOW TABLES IN support_heatwave;

-- update to 16GB memory for FREE MySQL Heatwave
update c_monitoring_options set option_value=16 where id =4 and option_name ='cluster_memory_gb';
commit;

-- Should show your dashboard
SELECT * FROM vw_monitoring_dashboard;

