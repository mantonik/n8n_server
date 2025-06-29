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

