-- =====================================================
-- File: sample_data_insert.sql
-- Version: 1.0
-- Date: 2025-01-12
-- Description: Sample data population for clean database
-- =====================================================

USE n8n_url_healthcheck;

-- =====================================================
-- 1. SAMPLE ALERT DEFINITIONS
-- =====================================================
INSERT INTO alert_definitions (alert_name, description, cooldown_minutes, escalation_enabled, escalation_delay_minutes, business_hours_only) VALUES
-- Critical 24/7 operations
('critical-ops-24x7', 'Critical operations team - immediate 24/7 response for critical systems', 30, TRUE, 15, FALSE),

-- Development teams
('dev-team-business', 'Development team - business hours monitoring for development services', 60, FALSE, 0, TRUE),
('api-team-alerts', 'API team - specialized API and backend service monitoring', 45, TRUE, 20, FALSE),

-- Infrastructure and operations
('infrastructure-team', 'Infrastructure team - system and network monitoring', 45, TRUE, 30, FALSE),
('security-team', 'Security team - security, SSL, and compliance monitoring', 60, TRUE, 60, FALSE),

-- Support and business
('support-team', 'Support team - general application monitoring during business hours', 90, FALSE, 0, TRUE),
('executives-critical', 'Executive team - critical business impact alerts only', 120, FALSE, 0, FALSE),

-- Specialized teams
('mobile-team', 'Mobile development team - mobile app and API monitoring', 60, FALSE, 0, TRUE),
('qa-team', 'QA team - testing environment and quality assurance monitoring', 90, FALSE, 0, TRUE);

-- =====================================================
-- 2. SAMPLE ALERT CONTACTS
-- =====================================================

-- Critical Ops Team (24x7 - Immediate Response)
INSERT INTO alert_contacts (alert_definition_id, contact_name, contact_email, contact_phone, notification_type, priority_order) VALUES
(1, 'Primary On-Call Engineer', 'oncall-primary@yourcompany.com', '+1-555-0101', 'email', 1),
(1, 'Primary On-Call SMS', 'oncall-primary@yourcompany.com', '+1-555-0101', 'sms', 1),
(1, 'Secondary On-Call Engineer', 'oncall-secondary@yourcompany.com', '+1-555-0102', 'email', 2),
(1, 'Operations Manager', 'ops-manager@yourcompany.com', '+1-555-0103', 'email', 3),
(1, 'Critical Ops Team', 'critical-ops@yourcompany.com', NULL, 'email', 1);

-- Development Team (Business Hours)
INSERT INTO alert_contacts (alert_definition_id, contact_name, contact_email, contact_phone, notification_type, priority_order) VALUES
(2, 'Dev Team Lead', 'dev-lead@yourcompany.com', NULL, 'email', 1),
(2, 'Senior Developer', 'senior-dev@yourcompany.com', NULL, 'email', 2),
(2, 'Development Team', 'dev-team@yourcompany.com', NULL, 'email', 1);

-- API Team
INSERT INTO alert_contacts (alert_definition_id, contact_name, contact_email, contact_phone, notification_type, priority_order) VALUES
(3, 'API Team Lead', 'api-lead@yourcompany.com', '+1-555-0301', 'email', 1),
(3, 'Backend Engineers', 'backend-team@yourcompany.com', NULL, 'email', 2),
(3, 'API Team Slack', 'api-alerts@slack.yourcompany.com', NULL, 'slack', 1);

-- Infrastructure Team
INSERT INTO alert_contacts (alert_definition_id, contact_name, contact_email, contact_phone, notification_type, priority_order) VALUES
(4, 'Infrastructure Lead', 'infra-lead@yourcompany.com', '+1-555-0401', 'email', 1),
(4, 'Infrastructure Lead SMS', 'infra-lead@yourcompany.com', '+1-555-0401', 'sms', 1),
(4, 'System Administrator', 'sysadmin@yourcompany.com', '+1-555-0402', 'email', 2),
(4, 'Infrastructure Team', 'infrastructure@yourcompany.com', NULL, 'email', 1);

-- Security Team
INSERT INTO alert_contacts (alert_definition_id, contact_name, contact_email, contact_phone, notification_type, priority_order) VALUES
(5, 'Security Lead', 'security-lead@yourcompany.com', '+1-555-0501', 'email', 1),
(5, 'Security Lead SMS', 'security-lead@yourcompany.com', '+1-555-0501', 'sms', 1),
(5, 'Security Team', 'security-team@yourcompany.com', NULL, 'email', 2),
(5, 'SSL Monitor', 'ssl-monitor@yourcompany.com', NULL, 'email', 3);

-- Support Team (Business Hours)
INSERT INTO alert_contacts (alert_definition_id, contact_name, contact_email, contact_phone, notification_type, priority_order) VALUES
(6, 'Support Manager', 'support-manager@yourcompany.com', NULL, 'email', 1),
(6, 'Support Team', 'support@yourcompany.com', NULL, 'email', 1);

-- Executives (Critical Only)
INSERT INTO alert_contacts (alert_definition_id, contact_name, contact_email, contact_phone, notification_type, priority_order) VALUES
(7, 'Chief Technology Officer', 'cto@yourcompany.com', NULL, 'email', 1),
(7, 'VP Engineering', 'vp-engineering@yourcompany.com', NULL, 'email', 2),
(7, 'Operations Director', 'ops-director@yourcompany.com', NULL, 'email', 3);

-- Mobile Team
INSERT INTO alert_contacts (alert_definition_id, contact_name, contact_email, contact_phone, notification_type, priority_order) VALUES
(8, 'Mobile Team Lead', 'mobile-lead@yourcompany.com', NULL, 'email', 1),
(8, 'Mobile Developers', 'mobile-team@yourcompany.com', NULL, 'email', 1);

-- QA Team
INSERT INTO alert_contacts (alert_definition_id, contact_name, contact_email, contact_phone, notification_type, priority_order) VALUES
(9, 'QA Manager', 'qa-manager@yourcompany.com', NULL, 'email', 1),
(9, 'QA Team', 'qa-team@yourcompany.com', NULL, 'email', 1);

-- =====================================================
-- 3. SAMPLE MONITORED URLS
-- =====================================================
INSERT INTO monitored_urls (
    url, name, description, priority, team_name, alert_definition_id,
    check_interval_minutes, response_time_warning_ms, response_time_critical_ms,
    check_ssl_expiry, ssl_days_warning, timeout_seconds, failure_threshold
) VALUES

-- Critical Production Services
('https://www.google.com', 'Google Search (Test)', 'External test - Google search page for connectivity testing', 
 'critical', 'Infrastructure', 1, 2, 2000, 5000, TRUE, 30, 15, 3),

('https://api.github.com', 'GitHub API (Test)', 'External API test - GitHub REST API endpoint', 
 'critical', 'Infrastructure', 1, 2, 1000, 3000, TRUE, 30, 20, 3),

-- High Priority Services
('https://www.github.com', 'GitHub Website (Test)', 'External test - GitHub main website', 
 'high', 'Development', 2, 3, 4000, 10000, TRUE, 14, 25, 4),

('https://httpstat.us/200', 'HTTP Status 200 (Test)', 'Test endpoint that returns HTTP 200 for testing success scenarios', 
 'high', 'Development', 3, 5, 3000, 8000, FALSE, 30, 30, 4),

-- Normal Priority Services  
('https://httpstat.us/404', 'HTTP Status 404 (Test)', 'Test endpoint that returns HTTP 404 for testing error scenarios', 
 'normal', 'QA', 9, 10, 5000, 15000, FALSE, 30, 30, 5),

('https://httpstat.us/503', 'HTTP Status 503 (Test)', 'Test endpoint that returns HTTP 503 for testing service unavailable scenarios', 
 'normal', 'QA', 9, 10, 5000, 15000, FALSE, 30, 30, 5),

-- Low Priority / Development Services
('https://httpstat.us/500', 'HTTP Status 500 (Test)', 'Test endpoint that returns HTTP 500 for testing server error scenarios', 
 'low', 'Development', 2, 15, 8000, 20000, FALSE, 30, 30, 5),

('https://httpbin.org/delay/2', 'HTTP Delay Test', 'Test endpoint with 2-second delay for testing timeout scenarios', 
 'low', 'QA', 9, 15, 5000, 10000, FALSE, 30, 30, 5),

-- API and Backend Services
('https://api.github.com/users/octocat', 'GitHub User API (Test)', 'GitHub API user endpoint for API testing', 
 'normal', 'API Team', 3, 5, 2000, 5000, TRUE, 30, 20, 4),

('https://httpbin.org/json', 'HTTPBin JSON (Test)', 'JSON response test endpoint', 
 'normal', 'API Team', 3, 10, 3000, 8000, FALSE, 30, 30, 4);

-- =====================================================
-- 4. SAMPLE HEALTH REPORTS (RECENT HISTORY)
-- =====================================================
-- Insert some sample health report data for the last few hours

-- Google (mostly up)
INSERT INTO health_reports (url_id, status, response_time_ms, http_status_code, checked_at) VALUES
(1, 'up', 850, 200, DATE_SUB(NOW(), INTERVAL 5 MINUTE)),
(1, 'up', 920, 200, DATE_SUB(NOW(), INTERVAL 10 MINUTE)),
(1, 'up', 780, 200, DATE_SUB(NOW(), INTERVAL 15 MINUTE)),
(1, 'up', 1100, 200, DATE_SUB(NOW(), INTERVAL 20 MINUTE));

-- GitHub API (mostly up with one error)
INSERT INTO health_reports (url_id, status, response_time_ms, http_status_code, checked_at) VALUES
(2, 'up', 1200, 200, DATE_SUB(NOW(), INTERVAL 5 MINUTE)),
(2, 'error', NULL, 503, DATE_SUB(NOW(), INTERVAL 10 MINUTE)),
(2, 'up', 1050, 200, DATE_SUB(NOW(), INTERVAL 15 MINUTE)),
(2, 'up', 980, 200, DATE_SUB(NOW(), INTERVAL 20 MINUTE));

-- GitHub Website (good performance)
INSERT INTO health_reports (url_id, status, response_time_ms, http_status_code, checked_at) VALUES
(3, 'up', 2100, 200, DATE_SUB(NOW(), INTERVAL 5 MINUTE)),
(3, 'up', 1890, 200, DATE_SUB(NOW(), INTERVAL 10 MINUTE)),
(3, 'up', 2200, 200, DATE_SUB(NOW(), INTERVAL 15 MINUTE));

-- HTTP 200 Test (always up)
INSERT INTO health_reports (url_id, status, response_time_ms, http_status_code, checked_at) VALUES
(4, 'up', 450, 200, DATE_SUB(NOW(), INTERVAL 5 MINUTE)),
(4, 'up', 380, 200, DATE_SUB(NOW(), INTERVAL 10 MINUTE)),
(4, 'up', 520, 200, DATE_SUB(NOW(), INTERVAL 15 MINUTE));

-- HTTP 404 Test (expected errors)
INSERT INTO health_reports (url_id, status, response_time_ms, http_status_code, checked_at) VALUES
(5, 'down', 420, 404, DATE_SUB(NOW(), INTERVAL 5 MINUTE)),
(5, 'down', 380, 404, DATE_SUB(NOW(), INTERVAL 15 MINUTE)),
(5, 'down', 450, 404, DATE_SUB(NOW(), INTERVAL 25 MINUTE));

-- =====================================================
-- 5. UPDATE URL STATUS BASED ON RECENT REPORTS
-- =====================================================
-- Update the last_status and last_checked_at for URLs based on recent reports

UPDATE monitored_urls mu
JOIN (
    SELECT url_id, status, checked_at,
           ROW_NUMBER() OVER (PARTITION BY url_id ORDER BY checked_at DESC) as rn
    FROM health_reports
) latest_reports ON mu.id = latest_reports.url_id AND latest_reports.rn = 1
SET 
    mu.last_status = latest_reports.status,
    mu.last_checked_at = latest_reports.checked_at;

-- Set failure counts based on recent status
UPDATE monitored_urls SET current_failure_count = 0 WHERE last_status = 'up';
UPDATE monitored_urls SET current_failure_count = 2 WHERE last_status IN ('down', 'error', 'timeout') AND id IN (2, 5);

-- =====================================================
-- 6. SAMPLE ALERT HISTORY
-- =====================================================
-- Insert some sample alert history to show the system in action

INSERT INTO alert_history (url_id, alert_definition_id, alert_contact_id, alert_type, severity, notification_type, destination, subject, message, sent_at, success) VALUES
-- Alert for GitHub API error
(2, 1, 1, 'error', 'warning', 'email', 'oncall-primary@yourcompany.com', 
 '⚠️ CRITICAL Alert: GitHub API (Test)', 
 'Website Health Alert\n\n⚠️ Status: ERROR\n📍 Site: GitHub API (Test)\n🔗 URL: https://api.github.com\n⚠️ Priority: CRITICAL\n❌ Error: HTTP 503\n🕐 Time: ' || DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 10 MINUTE), '%Y-%m-%d %H:%i:%s'),
 DATE_SUB(NOW(), INTERVAL 9 MINUTE), TRUE),

-- Recovery alert for GitHub API
(2, 1, 1, 'up', 'info', 'email', 'oncall-primary@yourcompany.com',
 '✅ RECOVERY: GitHub API (Test)', 
 'Website Recovery Alert\n\n✅ Status: UP\n📍 Site: GitHub API (Test)\n🔗 URL: https://api.github.com\n⚠️ Priority: CRITICAL\n📊 Response Time: 1050ms\n🕐 Time: ' || DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 5 MINUTE), '%Y-%m-%d %H:%i:%s'),
 DATE_SUB(NOW(), INTERVAL 4 MINUTE), TRUE);

-- =====================================================
-- 7. SAMPLE MAINTENANCE WINDOW
-- =====================================================
-- Add a sample maintenance window for weekend maintenance

INSERT INTO maintenance_windows (name, description, start_time, end_time, is_recurring, recurrence_pattern, suppress_alerts, created_by) VALUES
('Weekly Server Maintenance', 'Regular weekly server maintenance and updates', 
 DATE_ADD(DATE_ADD(CURDATE(), INTERVAL (7 - WEEKDAY(CURDATE())) DAY), INTERVAL '02:00:00' HOUR_SECOND),
 DATE_ADD(DATE_ADD(CURDATE(), INTERVAL (7 - WEEKDAY(CURDATE())) DAY), INTERVAL '04:00:00' HOUR_SECOND),
 TRUE, '0 2 * * 0', TRUE, 'system');

-- Link some URLs to the maintenance window
INSERT INTO maintenance_window_urls (maintenance_window_id, url_id) VALUES
(1, 1), (1, 2), (1, 3);

-- =====================================================
-- 8. VERIFICATION QUERIES
-- =====================================================

-- Show sample data summary
SELECT 'SAMPLE DATA SUMMARY' as section;

SELECT 
    'Alert Definitions' as item,
    COUNT(*) as count
FROM alert_definitions
UNION ALL
SELECT 
    'Alert Contacts' as item,
    COUNT(*) as count
FROM alert_contacts
UNION ALL
SELECT 
    'Monitored URLs' as item,
    COUNT(*) as count
FROM monitored_urls
UNION ALL
SELECT 
    'Health Reports' as item,
    COUNT(*) as count
FROM health_reports
UNION ALL
SELECT 
    'Alert History' as item,
    COUNT(*) as count
FROM alert_history
UNION ALL
SELECT 
    'Maintenance Windows' as item,
    COUNT(*) as count
FROM maintenance_windows;

-- Show current status overview
SELECT 'CURRENT STATUS OVERVIEW' as section;

SELECT * FROM dashboard_overview;

-- Show alert configuration overview
SELECT 'ALERT CONFIGURATION OVERVIEW' as section;

SELECT 
    alert_name,
    total_contacts,
    assigned_urls,
    alert_active
FROM alert_configuration_overview
ORDER BY alert_name;

-- Show current URL status
SELECT 'CURRENT URL STATUS' as section;

SELECT 
    site_name,
    priority,
    status_display,
    health_status,
    alert_name,
    total_alert_contacts
FROM url_status_current
ORDER BY 
    FIELD(priority, 'critical', 'high', 'normal', 'low'),
    site_name;

-- =====================================================
-- 9. LOG SAMPLE DATA VERSION
-- =====================================================
INSERT INTO db_version (version_number, file_name, description, sql_executed) VALUES 
('1.0-sample-data', 'sample_data_insert.sql', 'Sample data population completed with alert definitions, contacts, URLs, and test data', 'INSERT INTO alert_definitions, alert_contacts, monitored_urls, health_reports, alert_history, maintenance_windows');

-- =====================================================
-- 10. QUICK TEST QUERIES FOR VALIDATION
-- =====================================================

-- Test alert system query (what N8N workflow will use)
SELECT 'ALERT SYSTEM TEST QUERY' as section;

SELECT 
    mu.id as url_id,
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.alert_definition_id,
    ad.alert_name,
    ad.cooldown_minutes,
    ac.contact_name,
    ac.contact_email,
    ac.notification_type,
    ac.priority_order
FROM monitored_urls mu
JOIN alert_definitions ad ON mu.alert_definition_id = ad.id
JOIN alert_contacts ac ON ad.id = ac.alert_definition_id
WHERE mu.id = 1 -- Test with Google URL
  AND mu.is_active = TRUE
  AND ad.is_active = TRUE  
  AND ac.is_active = TRUE
ORDER BY ac.priority_order;

-- Check for any configuration issues
SELECT 'CONFIGURATION HEALTH CHECK' as section;

-- URLs without alert assignment
SELECT 
    'URLs without alert assignment' as issue_type,
    COUNT(*) as count
FROM monitored_urls 
WHERE is_active = TRUE AND alert_definition_id IS NULL
UNION ALL
-- Alert definitions without contacts
SELECT 
    'Alert definitions without contacts' as issue_type,
    COUNT(*) as count
FROM alert_definitions ad
LEFT JOIN alert_contacts ac ON ad.id = ac.alert_definition_id AND ac.is_active = TRUE
WHERE ad.is_active = TRUE AND ac.id IS NULL
UNION ALL
-- Active URLs with inactive alert definitions
SELECT 
    'URLs with inactive alert definitions' as issue_type,
    COUNT(*) as count
FROM monitored_urls mu
JOIN alert_definitions ad ON mu.alert_definition_id = ad.id
WHERE mu.is_active = TRUE AND ad.is_active = FALSE;

SELECT 
    '✅ SAMPLE DATA INITIALIZATION COMPLETE!' as status,
    NOW() as completed_at,
    'Database is ready for monitoring with sample data' as message;

/*
=====================================================
SAMPLE DATA INITIALIZATION COMPLETE - v1.0
=====================================================

SAMPLE DATA CREATED:
- 9 Alert Definitions (various teams and priorities)
- 25+ Alert Contacts (with email/SMS options)
- 10 Monitored URLs (mix of real test endpoints)
- Recent Health Reports (last few checks)
- Sample Alert History (showing alerts sent)
- Maintenance Window (weekend maintenance)

TEST ENDPOINTS INCLUDED:
- External: Google, GitHub (for real connectivity tests)
- HTTPStat.us: Various HTTP status codes for testing
- HTTPBin.org: API testing endpoints

ALERT DEFINITIONS:
- critical-ops-24x7: 24/7 immediate response
- dev-team-business: Development team business hours
- api-team-alerts: API team specialized monitoring
- infrastructure-team: Infrastructure monitoring
- security-team: Security and SSL monitoring
- support-team: General support monitoring
- executives-critical: Executive critical alerts
- mobile-team: Mobile development team
- qa-team: QA team monitoring

NEXT STEPS:
1. Customize email addresses for your actual team
2. Add your real URLs to monitor
3. Update N8N workflow to use new alert system
4. Test the monitoring workflow

The system is ready for production use!
*/