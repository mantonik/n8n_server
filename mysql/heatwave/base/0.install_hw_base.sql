- 1. Drop everything and start fresh
DROP DATABASE IF EXISTS support_heatwave;

-- 2. Deploy original files in sequence
SOURCE db_support_heatwave.sql;
SOURCE heatwave_monitoring_deployment.sql;
SOURCE heatwave_monitoring_deployment_v1.sql;
-- SOURCE heatwave_monitoring_deployment_v2.sql; -- optional
-- Should show your dashboard
SELECT * FROM vw_monitoring_dashboard;

-- List all objects
SHOW TABLES IN support_heatwave;

