-- =====================================================
-- COMPLETE ENHANCED WEBSITE HEALTH MONITORING DATABASE
-- Version: 3.0 Enhanced - Single SQL File
-- Execute this file directly on your MySQL database
-- =====================================================

-- Create Database (if not exists)
CREATE DATABASE IF NOT EXISTS n8n_url_healthcheck 
    DEFAULT CHARACTER SET = 'utf8mb4' 
    COLLATE = 'utf8mb4_unicode_ci';

USE n8n_url_healthcheck;

-- =====================================================
-- 1. CORE CONFIGURATION TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS config (
    id INT PRIMARY KEY AUTO_INCREMENT,
    config_key VARCHAR(50) UNIQUE NOT NULL,
    config_value VARCHAR(255) NOT NULL,
    description TEXT,
    category ENUM('monitoring', 'alerts', 'performance', 'security', 'maintenance') DEFAULT 'monitoring',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_config_key (config_key)
);

-- =====================================================
-- 2. ENHANCED MONITORED URLS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS monitored_urls (
    id INT PRIMARY KEY AUTO_INCREMENT,
    url VARCHAR(500) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    expected_response TEXT,
    expected_response_chars INT DEFAULT 200,
    http_method ENUM('GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS') DEFAULT 'GET',
    timeout_seconds INT DEFAULT 30,
    check_interval_minutes INT DEFAULT 5,
    priority ENUM('critical', 'high', 'normal', 'low') DEFAULT 'normal',
    
    -- Contact Information
    contact_person VARCHAR(100),
    contact_email VARCHAR(255),
    team_name VARCHAR(100),
    
    -- Failure Management
    failure_threshold INT DEFAULT 5,
    current_failure_count INT DEFAULT 0,
    
    -- Status Tracking
    last_checked_at TIMESTAMP NULL,
    last_status ENUM('up', 'down', 'timeout', 'error', 'unknown') DEFAULT 'unknown',
    
    -- Security Features (NEW)
    auth_header VARCHAR(255) COMMENT 'Authorization header for authenticated requests',
    auth_token VARCHAR(255) COMMENT 'Bearer token or API key',
    auth_username VARCHAR(100) COMMENT 'Basic auth username',
    auth_password VARCHAR(255) COMMENT 'Basic auth password (encrypted)',
    custom_headers JSON COMMENT 'Additional custom headers',
    ignore_ssl_errors BOOLEAN DEFAULT FALSE COMMENT 'Skip SSL certificate validation',
    
    -- SSL Certificate Monitoring (NEW)
    check_ssl_expiry BOOLEAN DEFAULT FALSE COMMENT 'Monitor SSL certificate expiration',
    ssl_days_warning INT DEFAULT 30 COMMENT 'Days before expiry to start warning',
    ssl_expires_at DATETIME NULL COMMENT 'SSL certificate expiration date',
    ssl_issuer VARCHAR(255) COMMENT 'SSL certificate issuer',
    ssl_last_checked TIMESTAMP NULL COMMENT 'Last SSL check timestamp',
    
    -- Performance Thresholds (NEW)
    response_time_warning_ms INT DEFAULT 5000 COMMENT 'Response time warning threshold',
    response_time_critical_ms INT DEFAULT 10000 COMMENT 'Response time critical threshold',
    
    -- System Fields
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Enhanced Indexes
    INDEX idx_active_lastcheck (is_active, last_checked_at),
    INDEX idx_priority (priority),
    INDEX idx_next_check (check_interval_minutes, last_checked_at),
    INDEX idx_ssl_monitoring (check_ssl_expiry, ssl_expires_at),
    INDEX idx_status_priority (last_status, priority),
    INDEX idx_team (team_name),
    INDEX idx_team_priority (team_name, priority),
    FULLTEXT idx_search (name, description, url)
);

-- =====================================================
-- 3. ENHANCED HEALTH REPORTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS health_reports (
    id INT PRIMARY KEY AUTO_INCREMENT,
    url_id INT NOT NULL,
    status ENUM('up', 'down', 'timeout', 'error') NOT NULL,
    response_time_ms INT,
    http_status_code INT,
    response_body_preview TEXT,
    response_headers JSON,
    error_message TEXT,
    retry_attempt INT DEFAULT 1,
    
    -- SSL Information (NEW)
    ssl_valid BOOLEAN NULL COMMENT 'SSL certificate validity',
    ssl_expires_in_days INT NULL COMMENT 'Days until SSL expiry',
    ssl_error TEXT COMMENT 'SSL-related errors',
    
    -- Performance Classification (NEW)
    performance_status ENUM('excellent', 'good', 'warning', 'critical') NULL,
    
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (url_id) REFERENCES monitored_urls(id) ON DELETE CASCADE,
    INDEX idx_url_checked (url_id, checked_at),
    INDEX idx_checked_at (checked_at),
    INDEX idx_status_time (status, checked_at),
    INDEX idx_performance (performance_status, checked_at),
    INDEX idx_ssl_status (ssl_valid, checked_at),
    INDEX idx_url_time_desc (url_id, checked_at DESC)
);

-- =====================================================
-- 4. ENHANCED ALERT GROUPS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS alert_groups (
    id INT PRIMARY KEY AUTO_INCREMENT,
    group_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    escalation_level ENUM('primary', 'secondary', 'executive') DEFAULT 'primary',
    business_hours_only BOOLEAN DEFAULT FALSE,
    timezone VARCHAR(50) DEFAULT 'UTC',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_escalation (escalation_level),
    INDEX idx_active (is_active)
);

-- =====================================================
-- 5. ENHANCED ALERT GROUP MEMBERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS alert_group_members (
    id INT PRIMARY KEY AUTO_INCREMENT,
    group_id INT NOT NULL,
    notification_type ENUM('email', 'sms', 'telegram', 'webhook', 'slack', 'teams') NOT NULL,
    destination VARCHAR(255) NOT NULL,
    member_name VARCHAR(100),
    role VARCHAR(50) COMMENT 'Team role of the member',
    priority INT DEFAULT 1 COMMENT 'Notification priority within group',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES alert_groups(id) ON DELETE CASCADE,
    INDEX idx_group_type (group_id, notification_type),
    INDEX idx_group_active (group_id, is_active),
    INDEX idx_priority (priority)
);

-- =====================================================
-- 6. ENHANCED URL ALERT GROUPS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS url_alert_groups (
    id INT PRIMARY KEY AUTO_INCREMENT,
    url_id INT NOT NULL,
    group_id INT NOT NULL,
    alert_on_down BOOLEAN DEFAULT TRUE,
    alert_on_up BOOLEAN DEFAULT TRUE,
    alert_on_timeout BOOLEAN DEFAULT TRUE,
    alert_on_error BOOLEAN DEFAULT TRUE,
    alert_on_ssl_expiry BOOLEAN DEFAULT FALSE,
    alert_on_performance_warning BOOLEAN DEFAULT FALSE,
    alert_on_performance_critical BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (url_id) REFERENCES monitored_urls(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES alert_groups(id) ON DELETE CASCADE,
    UNIQUE KEY unique_url_group (url_id, group_id),
    INDEX idx_url_alerts (url_id, is_active),
    INDEX idx_group_urls (group_id, is_active)
);

-- =====================================================
-- 7. ENHANCED ALERT HISTORY TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS alert_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    url_id INT NOT NULL,
    group_id INT,
    notification_type ENUM('email', 'sms', 'telegram', 'webhook', 'slack', 'teams') NOT NULL,
    destination VARCHAR(255) NOT NULL,
    alert_type ENUM('down', 'up', 'timeout', 'error', 'ssl_expiry', 'performance_warning', 'performance_critical') NOT NULL,
    severity ENUM('info', 'warning', 'critical') DEFAULT 'warning',
    message TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT TRUE,
    error_details TEXT,
    escalation_level INT DEFAULT 1,
    FOREIGN KEY (url_id) REFERENCES monitored_urls(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES alert_groups(id) ON DELETE SET NULL,
    INDEX idx_url_sent (url_id, sent_at),
    INDEX idx_group_sent (group_id, sent_at),
    INDEX idx_sent_at (sent_at),
    INDEX idx_alert_type (alert_type, sent_at),
    INDEX idx_severity (severity, sent_at),
    INDEX idx_type_time (alert_type, sent_at)
);

-- =====================================================
-- 8. MAINTENANCE WINDOWS TABLES (NEW)
-- =====================================================
CREATE TABLE IF NOT EXISTS maintenance_windows (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern VARCHAR(100) COMMENT 'Cron-like pattern for recurring maintenance',
    suppress_alerts BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_time_range (start_time, end_time),
    INDEX idx_active_windows (start_time, end_time, suppress_alerts)
);

CREATE TABLE IF NOT EXISTS maintenance_window_urls (
    id INT PRIMARY KEY AUTO_INCREMENT,
    maintenance_window_id INT NOT NULL,
    url_id INT NOT NULL,
    FOREIGN KEY (maintenance_window_id) REFERENCES maintenance_windows(id) ON DELETE CASCADE,
    FOREIGN KEY (url_id) REFERENCES monitored_urls(id) ON DELETE CASCADE,
    UNIQUE KEY unique_maintenance_url (maintenance_window_id, url_id)
);

-- =====================================================
-- 9. ENHANCED CONFIGURATION DATA
-- =====================================================
INSERT IGNORE INTO config (config_key, config_value, description, category) VALUES
-- Monitoring Settings
('default_timeout', '30', 'Default timeout in seconds for HTTP requests', 'monitoring'),
('default_check_interval', '5', 'Default check interval in minutes', 'monitoring'),
('default_failure_threshold', '5', 'Default number of failures before sending alert', 'monitoring'),
('max_concurrent_checks', '10', 'Maximum concurrent health checks', 'monitoring'),
('batch_size', '20', 'Number of URLs to process in each batch', 'monitoring'),

-- Performance Settings
('response_time_warning_default', '5000', 'Default response time warning threshold (ms)', 'performance'),
('response_time_critical_default', '10000', 'Default response time critical threshold (ms)', 'performance'),
('ssl_warning_days_default', '30', 'Default days before SSL expiry to warn', 'performance'),

-- Alert Settings
('notification_cooldown_minutes', '60', 'Minutes to wait between same type notifications', 'alerts'),
('escalation_delay_minutes', '30', 'Minutes before escalating to next level', 'alerts'),
('alert_email_from', 'healthcheck@yourcompany.com', 'Default from email for alerts', 'alerts'),
('max_alerts_per_hour', '20', 'Maximum alerts per URL per hour', 'alerts'),

-- Security Settings
('enable_ssl_monitoring', 'true', 'Enable SSL certificate monitoring', 'security'),
('default_user_agent', 'HealthCheck-Monitor/3.0', 'Default User-Agent header', 'security'),
('encrypt_auth_tokens', 'true', 'Encrypt stored authentication tokens', 'security'),

-- Maintenance Settings
('data_retention_days', '90', 'Number of days to keep health report data', 'maintenance'),
('cleanup_batch_size', '1000', 'Number of records to delete per cleanup batch', 'maintenance'),
('optimize_tables_weekly', 'true', 'Run OPTIMIZE TABLE weekly', 'maintenance');

-- =====================================================
-- 10. SAMPLE DATA WITH ENHANCED FEATURES
-- =====================================================
INSERT IGNORE INTO monitored_urls (
    id, url, name, description, priority, contact_person, contact_email, team_name,
    check_interval_minutes, response_time_warning_ms, response_time_critical_ms,
    check_ssl_expiry, ssl_days_warning, timeout_seconds
) VALUES
(1, 'https://www.google.com', 'Google Search', 'Main Google search page - always available', 
 'critical', 'System Admin', 'admin@yourcompany.com', 'Infrastructure', 2, 2000, 5000, TRUE, 30, 15),

(2, 'https://httpstat.us/200', 'HTTP Test - Success', 'Test endpoint that returns HTTP 200', 
 'normal', 'DevOps Team', 'devops@yourcompany.com', 'DevOps', 5, 3000, 8000, FALSE, 30, 30),

(3, 'https://httpstat.us/500', 'HTTP Test - Error', 'Test endpoint that returns HTTP 500 (for testing alerts)', 
 'low', 'DevOps Team', 'devops@yourcompany.com', 'DevOps', 5, 3000, 8000, FALSE, 30, 30),

(4, 'https://www.github.com', 'GitHub', 'GitHub main website', 
 'high', 'Development Team', 'dev@yourcompany.com', 'Development', 3, 4000, 10000, TRUE, 14, 25),

(5, 'https://api.github.com', 'GitHub API', 'GitHub REST API endpoint', 
 'high', 'Development Team', 'dev@yourcompany.com', 'Development', 2, 1000, 3000, TRUE, 30, 20);

-- Enhanced Alert Groups
INSERT IGNORE INTO alert_groups (group_name, description, escalation_level, business_hours_only, timezone) VALUES
('critical-ops', 'Critical operations team - 24/7 monitoring', 'primary', FALSE, 'UTC'),
('dev-team', 'Development team alerts', 'primary', TRUE, 'UTC'),
('business-hours', 'Business hours support team', 'secondary', TRUE, 'UTC'),
('executives', 'Executive level alerts for critical issues', 'executive', FALSE, 'UTC'),
('security-team', 'Security and SSL monitoring alerts', 'primary', FALSE, 'UTC');

-- Enhanced Alert Group Members
INSERT IGNORE INTO alert_group_members (group_id, notification_type, destination, member_name, role, priority) VALUES
-- Critical Ops Team
(1, 'email', 'ops-critical@yourcompany.com', 'Critical Ops Team', 'Operations', 1),
(1, 'sms', '1234567890@vztext.com', 'Ops Manager', 'Manager', 1),
(1, 'email', 'oncall@yourcompany.com', 'On-Call Engineer', 'Engineer', 2),

-- Development Team
(2, 'email', 'dev-team@yourcompany.com', 'Development Team', 'Development', 1),
(2, 'slack', '#dev-alerts', 'Dev Team Slack', 'Team Channel', 1),

-- Business Hours
(3, 'email', 'support@yourcompany.com', 'Support Team', 'Support', 1),

-- Executives
(4, 'email', 'cto@yourcompany.com', 'Chief Technology Officer', 'Executive', 1),
(4, 'email', 'admin@yourcompany.com', 'System Administrator', 'Administrator', 2),

-- Security Team
(5, 'email', 'security@yourcompany.com', 'Security Team', 'Security', 1),
(5, 'email', 'ssl-monitor@yourcompany.com', 'SSL Monitor', 'Monitoring', 1);

-- Enhanced URL Alert Group Links
INSERT IGNORE INTO url_alert_groups (
    url_id, group_id, alert_on_down, alert_on_up, alert_on_timeout, alert_on_error,
    alert_on_ssl_expiry, alert_on_performance_warning, alert_on_performance_critical
) VALUES
(1, 1, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE),  -- Google -> Critical Ops
(1, 4, TRUE, FALSE, TRUE, TRUE, TRUE, FALSE, FALSE), -- Google -> Executives (no recovery spam)
(1, 5, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE), -- Google -> Security (SSL only)

(2, 2, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE), -- HTTP Test 200 -> Dev Team
(3, 2, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE), -- HTTP Test 500 -> Dev Team

(4, 2, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),    -- GitHub -> Dev Team (all alerts)
(4, 3, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE), -- GitHub -> Business Hours (down only)
(4, 5, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE), -- GitHub -> Security (SSL only)

(5, 2, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),    -- GitHub API -> Dev Team (all alerts)
(5, 1, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE);  -- GitHub API -> Critical Ops (critical perf)

-- =====================================================
-- 11. COMPREHENSIVE MONITORING VIEWS FOR REPORTING WEBSITE
-- =====================================================

-- Dashboard Overview View - Real-time system summary
CREATE OR REPLACE VIEW dashboard_overview AS
SELECT 
    -- Overall Statistics
    COUNT(*) as total_sites,
    SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) as sites_up,
    SUM(CASE WHEN mu.last_status = 'down' THEN 1 ELSE 0 END) as sites_down,
    SUM(CASE WHEN mu.last_status = 'error' THEN 1 ELSE 0 END) as sites_error,
    SUM(CASE WHEN mu.last_status = 'timeout' THEN 1 ELSE 0 END) as sites_timeout,
    SUM(CASE WHEN mu.last_status = 'unknown' OR mu.last_status IS NULL THEN 1 ELSE 0 END) as sites_unknown,
    
    -- Critical Status
    SUM(CASE WHEN mu.current_failure_count >= mu.failure_threshold THEN 1 ELSE 0 END) as sites_alerting,
    SUM(CASE WHEN mu.priority = 'critical' AND mu.last_status != 'up' THEN 1 ELSE 0 END) as critical_sites_down,
    
    -- Performance Metrics
    ROUND(
        (SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 
        2
    ) as overall_uptime_percent,
    
    -- SSL Status
    SUM(CASE WHEN mu.check_ssl_expiry = TRUE THEN 1 ELSE 0 END) as ssl_monitored_sites,
    SUM(CASE WHEN mu.ssl_expires_at <= DATE_ADD(NOW(), INTERVAL mu.ssl_days_warning DAY) 
             AND mu.check_ssl_expiry = TRUE THEN 1 ELSE 0 END) as ssl_expiring_soon,
    
    -- Last Updated
    MAX(mu.last_checked_at) as last_system_check,
    NOW() as report_generated_at
FROM monitored_urls mu 
WHERE mu.is_active = TRUE;

-- URL Status Detailed View - Complete service status
CREATE OR REPLACE VIEW url_status_detailed AS
SELECT 
    mu.id as url_id,
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.team_name,
    mu.contact_person,
    mu.contact_email,
    
    -- Current Status
    mu.last_status as current_status,
    CASE 
        WHEN mu.last_status = 'up' THEN '✅ UP'
        WHEN mu.last_status = 'down' THEN '❌ DOWN'
        WHEN mu.last_status = 'error' THEN '⚠️ ERROR'
        WHEN mu.last_status = 'timeout' THEN '⏰ TIMEOUT'
        WHEN mu.last_status = 'unknown' THEN '❓ UNKNOWN'
        ELSE '❓ NOT CHECKED'
    END as status_display,
    
    -- Timing Information
    mu.last_checked_at,
    mu.check_interval_minutes,
    CASE 
        WHEN mu.last_checked_at IS NULL THEN '🔴 Never checked'
        WHEN mu.last_checked_at < DATE_SUB(NOW(), INTERVAL (mu.check_interval_minutes + 5) MINUTE) 
            THEN '🟡 Overdue for check'
        ELSE '🟢 On schedule'
    END as check_status,
    
    -- Failure Information
    mu.current_failure_count,
    mu.failure_threshold,
    CONCAT(mu.current_failure_count, '/', mu.failure_threshold) as failure_count_display,
    CASE 
        WHEN mu.current_failure_count >= mu.failure_threshold THEN '🚨 ALERTING'
        WHEN mu.current_failure_count > 0 THEN '⚠️ FAILING'
        ELSE '✅ HEALTHY'
    END as health_status,
    
    -- Performance Information
    hr.response_time_ms as last_response_time,
    hr.http_status_code as last_http_code,
    hr.error_message as last_error,
    CASE 
        WHEN hr.response_time_ms IS NULL THEN NULL
        WHEN hr.response_time_ms <= mu.response_time_warning_ms THEN '🟢 Excellent'
        WHEN hr.response_time_ms <= mu.response_time_critical_ms THEN '🟡 Warning'
        ELSE '🔴 Critical'
    END as performance_status,
    
    -- SSL Information
    mu.check_ssl_expiry as ssl_monitoring_enabled,
    mu.ssl_expires_at,
    CASE 
        WHEN mu.check_ssl_expiry = FALSE THEN 'Not Monitored'
        WHEN mu.ssl_expires_at IS NULL THEN 'Unknown'
        WHEN mu.ssl_expires_at <= NOW() THEN '🔴 Expired'
        WHEN mu.ssl_expires_at <= DATE_ADD(NOW(), INTERVAL mu.ssl_days_warning DAY) THEN '🟡 Expiring Soon'
        ELSE '🟢 Valid'
    END as ssl_status,
    CASE 
        WHEN mu.ssl_expires_at IS NOT NULL THEN DATEDIFF(mu.ssl_expires_at, NOW())
        ELSE NULL
    END as ssl_days_remaining,
    
    -- Alert Configuration
    (SELECT COUNT(*) FROM url_alert_groups uag 
     JOIN alert_groups ag ON uag.group_id = ag.id 
     WHERE uag.url_id = mu.id AND uag.is_active = TRUE AND ag.is_active = TRUE) as alert_groups_count,
    
    mu.is_active,
    mu.created_at,
    mu.updated_at

FROM monitored_urls mu
LEFT JOIN health_reports hr ON mu.id = hr.url_id AND hr.checked_at = mu.last_checked_at
ORDER BY 
    mu.is_active DESC,
    FIELD(mu.priority, 'critical', 'high', 'normal', 'low'),
    CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END,
    mu.current_failure_count DESC,
    mu.name;

-- SLA Report View (30-day rolling)
CREATE OR REPLACE VIEW sla_report_30day AS
SELECT 
    mu.id as url_id,
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.team_name,
    
    -- Check Statistics
    COUNT(hr.id) as total_checks,
    SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) as successful_checks,
    SUM(CASE WHEN hr.status = 'down' THEN 1 ELSE 0 END) as down_checks,
    SUM(CASE WHEN hr.status = 'error' THEN 1 ELSE 0 END) as error_checks,
    SUM(CASE WHEN hr.status = 'timeout' THEN 1 ELSE 0 END) as timeout_checks,
    
    -- SLA Calculation
    ROUND(
        (SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(hr.id)), 
        3
    ) as uptime_sla_percent,
    
    -- Performance Metrics
    ROUND(AVG(CASE WHEN hr.status = 'up' THEN hr.response_time_ms END), 2) as avg_response_time_ms,
    ROUND(MIN(CASE WHEN hr.status = 'up' THEN hr.response_time_ms END), 2) as min_response_time_ms,
    ROUND(MAX(CASE WHEN hr.status = 'up' THEN hr.response_time_ms END), 2) as max_response_time_ms,
    ROUND(STDDEV(CASE WHEN hr.status = 'up' THEN hr.response_time_ms END), 2) as response_time_stddev,
    
    -- SLA Classification
    CASE 
        WHEN (SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(hr.id)) >= 99.9 THEN '🟢 Excellent (99.9%+)'
        WHEN (SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(hr.id)) >= 99.5 THEN '🟡 Good (99.5%+)'
        WHEN (SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(hr.id)) >= 99.0 THEN '🟠 Fair (99.0%+)'
        ELSE '🔴 Poor (<99.0%)'
    END as sla_grade,
    
    -- Incident Statistics
    MAX(hr.checked_at) as last_check_time,
    (SELECT checked_at FROM health_reports hr2 
     WHERE hr2.url_id = mu.id AND hr2.status != 'up' 
     ORDER BY hr2.checked_at DESC LIMIT 1) as last_incident_time,
     
    -- Report Period
    DATE_SUB(NOW(), INTERVAL 30 DAY) as report_start_date,
    NOW() as report_end_date

FROM monitored_urls mu
LEFT JOIN health_reports hr ON mu.id = hr.url_id 
    AND hr.checked_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
WHERE mu.is_active = TRUE
GROUP BY mu.id, mu.name, mu.url, mu.priority, mu.team_name
HAVING COUNT(hr.id) > 0
ORDER BY uptime_sla_percent ASC, mu.priority DESC;

-- SSL Certificate Status View
CREATE OR REPLACE VIEW ssl_certificate_status AS
SELECT 
    mu.id as url_id,
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.team_name,
    mu.contact_email,
    
    mu.check_ssl_expiry as monitoring_enabled,
    mu.ssl_expires_at as expiry_date,
    mu.ssl_issuer,
    mu.ssl_last_checked,
    
    CASE 
        WHEN mu.check_ssl_expiry = FALSE THEN 'Not Monitored'
        WHEN mu.ssl_expires_at IS NULL THEN 'Unknown'
        WHEN mu.ssl_expires_at <= NOW() THEN 'Expired'
        ELSE 'Valid'
    END as ssl_status,
    
    CASE 
        WHEN mu.ssl_expires_at IS NOT NULL THEN DATEDIFF(mu.ssl_expires_at, NOW())
        ELSE NULL
    END as days_until_expiry,
    
    CASE 
        WHEN mu.check_ssl_expiry = FALSE THEN '⚪ Not Monitored'
        WHEN mu.ssl_expires_at IS NULL THEN '❓ Unknown'
        WHEN mu.ssl_expires_at <= NOW() THEN '🔴 Expired'
        WHEN mu.ssl_expires_at <= DATE_ADD(NOW(), INTERVAL 7 DAY) THEN '🔴 Critical (≤7 days)'
        WHEN mu.ssl_expires_at <= DATE_ADD(NOW(), INTERVAL mu.ssl_days_warning DAY) THEN '🟡 Warning'
        ELSE '🟢 Valid'
    END as ssl_status_display,
    
    -- Alert Status
    CASE 
        WHEN mu.check_ssl_expiry = TRUE 
             AND mu.ssl_expires_at <= DATE_ADD(NOW(), INTERVAL mu.ssl_days_warning DAY)
             AND EXISTS (SELECT 1 FROM url_alert_groups uag 
                        WHERE uag.url_id = mu.id 
                        AND uag.alert_on_ssl_expiry = TRUE 
                        AND uag.is_active = TRUE) THEN 'Alerting Enabled'
        WHEN mu.check_ssl_expiry = TRUE THEN 'Monitoring Only'
        ELSE 'Not Monitored'
    END as alert_configuration

FROM monitored_urls mu
WHERE mu.is_active = TRUE
ORDER BY 
    CASE WHEN mu.check_ssl_expiry = TRUE THEN 0 ELSE 1 END,
    mu.ssl_expires_at ASC,
    FIELD(mu.priority, 'critical', 'high', 'normal', 'low'),
    mu.name;

-- Team Performance Summary View
CREATE OR REPLACE VIEW team_performance_summary AS
SELECT 
    COALESCE(mu.team_name, 'Unassigned') as team_name,
    COUNT(*) as total_sites,
    
    -- Status Distribution
    SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) as sites_up,
    SUM(CASE WHEN mu.last_status = 'down' THEN 1 ELSE 0 END) as sites_down,
    SUM(CASE WHEN mu.last_status = 'error' THEN 1 ELSE 0 END) as sites_error,
    SUM(CASE WHEN mu.last_status = 'timeout' THEN 1 ELSE 0 END) as sites_timeout,
    
    -- Team SLA (30-day)
    ROUND(AVG(
        (SELECT (SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(hr.id))
         FROM health_reports hr 
         WHERE hr.url_id = mu.id 
         AND hr.checked_at > DATE_SUB(NOW(), INTERVAL 30 DAY))
    ), 2) as team_avg_uptime_30d,
    
    -- Performance Metrics
    ROUND(AVG(
        (SELECT AVG(hr.response_time_ms)
         FROM health_reports hr 
         WHERE hr.url_id = mu.id 
         AND hr.status = 'up'
         AND hr.checked_at > DATE_SUB(NOW(), INTERVAL 7 DAY))
    ), 2) as team_avg_response_time_7d,
    
    -- Alert Statistics
    (SELECT COUNT(*) 
     FROM alert_history ah 
     WHERE ah.url_id IN (SELECT id FROM monitored_urls WHERE team_name = mu.team_name)
     AND ah.sent_at > DATE_SUB(NOW(), INTERVAL 7 DAY)) as team_alerts_7d,
    
    -- Priority Distribution
    SUM(CASE WHEN mu.priority = 'critical' THEN 1 ELSE 0 END) as critical_sites,
    SUM(CASE WHEN mu.priority = 'high' THEN 1 ELSE 0 END) as high_sites,
    SUM(CASE WHEN mu.priority = 'normal' THEN 1 ELSE 0 END) as normal_sites,
    SUM(CASE WHEN mu.priority = 'low' THEN 1 ELSE 0 END) as low_sites,
    
    -- Team Health Score (0-100)
    ROUND(
        (SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 
        2
    ) as team_health_score

FROM monitored_urls mu
WHERE mu.is_active = TRUE
GROUP BY COALESCE(mu.team_name, 'Unassigned')
ORDER BY team_health_score DESC, team_avg_uptime_30d DESC;

-- Executive Dashboard View
CREATE OR REPLACE VIEW executive_dashboard AS
SELECT 
    'System Overview' as metric_category,
    
    -- Overall Health
    (SELECT COUNT(*) FROM monitored_urls WHERE is_active = TRUE) as total_monitored_sites,
    (SELECT COUNT(*) FROM monitored_urls WHERE is_active = TRUE AND last_status = 'up') as sites_operational,
    (SELECT COUNT(*) FROM monitored_urls WHERE is_active = TRUE AND current_failure_count >= failure_threshold) as sites_in_alert,
    (SELECT COUNT(*) FROM monitored_urls WHERE is_active = TRUE AND priority = 'critical' AND last_status != 'up') as critical_sites_down,
    
    -- SLA Performance (30-day)
    (SELECT ROUND(AVG(uptime_sla_percent), 2) FROM sla_report_30day) as overall_sla_30d,
    (SELECT ROUND(AVG(uptime_sla_percent), 2) FROM sla_report_30day WHERE priority = 'critical') as critical_sla_30d,
    
    -- Performance Metrics
    (SELECT ROUND(AVG(avg_response_time_ms), 2) FROM sla_report_30day) as avg_response_time_30d,
    (SELECT COUNT(*) FROM url_status_detailed WHERE performance_status = '🔴 Critical') as sites_performance_critical,
    
    -- Alert Volume
    (SELECT COUNT(*) FROM alert_history WHERE sent_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)) as alerts_24h,
    (SELECT COUNT(*) FROM alert_history WHERE sent_at > DATE_SUB(NOW(), INTERVAL 7 DAY)) as alerts_7d,
    
    -- SSL Security
    (SELECT COUNT(*) FROM ssl_certificate_status WHERE monitoring_enabled = TRUE) as ssl_monitored_sites,
    (SELECT COUNT(*) FROM ssl_certificate_status WHERE ssl_status = 'Expired' OR ssl_status_display LIKE '%Critical%') as ssl_critical_sites,
    
    -- Team Distribution
    (SELECT COUNT(DISTINCT team_name) FROM monitored_urls WHERE is_active = TRUE AND team_name IS NOT NULL) as active_teams,
    
    -- Report Timestamp
    NOW() as report_generated_at;

-- Incident Timeline View (Last 48 Hours)
CREATE OR REPLACE VIEW incident_timeline_48h AS
SELECT 
    hr.checked_at as incident_time,
    mu.id as url_id,
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.team_name,
    hr.status as incident_type,
    hr.response_time_ms,
    hr.http_status_code,
    hr.error_message,
    
    CASE 
        WHEN hr.status = 'down' THEN '🔴 Site Down'
        WHEN hr.status = 'error' THEN '⚠️ Error'
        WHEN hr.status = 'timeout' THEN '⏰ Timeout'
        WHEN hr.status = 'up' AND LAG(hr.status) OVER (PARTITION BY mu.id ORDER BY hr.checked_at) != 'up' THEN '✅ Recovered'
        ELSE NULL
    END as incident_description,
    
    -- Duration calculation for outages
    CASE 
        WHEN hr.status = 'up' AND LAG(hr.status) OVER (PARTITION BY mu.id ORDER BY hr.checked_at) != 'up' THEN
            TIMESTAMPDIFF(MINUTE, 
                LAG(hr.checked_at) OVER (PARTITION BY mu.id ORDER BY hr.checked_at), 
                hr.checked_at)
        ELSE NULL
    END as outage_duration_minutes,
    
    -- Alert information
    (SELECT COUNT(*) 
     FROM alert_history ah 
     WHERE ah.url_id = mu.id 
     AND ah.sent_at BETWEEN hr.checked_at AND DATE_ADD(hr.checked_at, INTERVAL 5 MINUTE)) as alerts_sent

FROM health_reports hr
JOIN monitored_urls mu ON hr.url_id = mu.id
WHERE hr.checked_at > DATE_SUB(NOW(), INTERVAL 48 HOUR)
  AND mu.is_active = TRUE
  AND (hr.status != 'up' OR 
       (hr.status = 'up' AND LAG(hr.status) OVER (PARTITION BY mu.id ORDER BY hr.checked_at) != 'up'))
ORDER BY hr.checked_at DESC;

-- =====================================================
-- 12. ENHANCED STORED PROCEDURES
-- =====================================================

DELIMITER //

-- Enhanced Cleanup Procedure with Better Performance
DROP PROCEDURE IF EXISTS CleanOldHealthReports//
CREATE PROCEDURE CleanOldHealthReports()
BEGIN
    DECLARE retention_days INT DEFAULT 90;
    DECLARE cleanup_batch_size INT DEFAULT 1000;
    DECLARE total_deleted INT DEFAULT 0;
    DECLARE batch_deleted INT DEFAULT 0;
    
    -- Get retention settings from config
    SELECT CAST(config_value AS UNSIGNED) INTO retention_days 
    FROM config WHERE config_key = 'data_retention_days' LIMIT 1;
    
    SELECT CAST(config_value AS UNSIGNED) INTO cleanup_batch_size 
    FROM config WHERE config_key = 'cleanup_batch_size' LIMIT 1;
    
    -- Create temporary summary table
    DROP TEMPORARY TABLE IF EXISTS cleanup_summary;
    CREATE TEMPORARY TABLE cleanup_summary (
        phase VARCHAR(20),
        total_health_reports INT,
        total_alert_history INT,
        old_health_reports INT,
        old_alert_history INT,
        retention_days INT,
        timestamp TIMESTAMP
    );
    
    -- Record before cleanup stats
    INSERT INTO cleanup_summary 
    SELECT 
        'Before Cleanup' as phase,
        (SELECT COUNT(*) FROM health_reports) as total_health_reports,
        (SELECT COUNT(*) FROM alert_history) as total_alert_history,
        (SELECT COUNT(*) FROM health_reports 
         WHERE checked_at < DATE_SUB(NOW(), INTERVAL retention_days DAY)) as old_health_reports,
        (SELECT COUNT(*) FROM alert_history 
         WHERE sent_at < DATE_SUB(NOW(), INTERVAL retention_days DAY)) as old_alert_history,
        retention_days as retention_days,
        NOW() as timestamp;
    
    -- Delete old health reports in batches
    REPEAT
        DELETE FROM health_reports 
        WHERE checked_at < DATE_SUB(NOW(), INTERVAL retention_days DAY)
        LIMIT cleanup_batch_size;
        
        SET batch_deleted = ROW_COUNT();
        SET total_deleted = total_deleted + batch_deleted;
    UNTIL batch_deleted = 0 END REPEAT;
    
    -- Delete old alert history in batches
    SET batch_deleted = 1;
    WHILE batch_deleted > 0 DO
        DELETE FROM alert_history 
        WHERE sent_at < DATE_SUB(NOW(), INTERVAL retention_days DAY)
        LIMIT cleanup_batch_size;
        
        SET batch_deleted = ROW_COUNT();
    END WHILE;
    
    -- Record after cleanup stats
    INSERT INTO cleanup_summary
    SELECT 
        'After Cleanup' as phase,
        (SELECT COUNT(*) FROM health_reports) as total_health_reports,
        (SELECT COUNT(*) FROM alert_history) as total_alert_history,
        0 as old_health_reports,
        0 as old_alert_history,
        retention_days as retention_days,
        NOW() as timestamp;
    
    -- Return cleanup summary
    SELECT * FROM cleanup_summary;
    
    -- Clean up temporary table
    DROP TEMPORARY TABLE cleanup_summary;
    
    -- Return total deleted count
    SELECT total_deleted as total_health_reports_deleted;
END//

-- SSL Certificate Update Procedure
DROP PROCEDURE IF EXISTS UpdateSSLCertificateInfo//
CREATE PROCEDURE UpdateSSLCertificateInfo(
    IN p_url_id INT,
    IN p_ssl_expires_at DATETIME,
    IN p_ssl_issuer VARCHAR(255),
    IN p_ssl_valid BOOLEAN
)
BEGIN
    DECLARE ssl_monitoring_enabled BOOLEAN DEFAULT FALSE;
    
    -- Check if SSL monitoring is enabled for this URL
    SELECT check_ssl_expiry INTO ssl_monitoring_enabled
    FROM monitored_urls 
    WHERE id = p_url_id LIMIT 1;
    
    -- Update SSL information
    UPDATE monitored_urls 
    SET 
        ssl_expires_at = p_ssl_expires_at,
        ssl_issuer = p_ssl_issuer,
        ssl_last_checked = NOW()
    WHERE id = p_url_id;
    
    -- Log SSL status in health report if monitoring is enabled
    IF ssl_monitoring_enabled = TRUE THEN
        INSERT INTO health_reports (
            url_id, 
            status, 
            ssl_valid, 
            ssl_expires_in_days, 
            ssl_error,
            checked_at
        ) VALUES (
            p_url_id,
            CASE WHEN p_ssl_valid THEN 'up' ELSE 'error' END,
            p_ssl_valid,
            CASE WHEN p_ssl_expires_at IS NOT NULL 
                 THEN DATEDIFF(p_ssl_expires_at, NOW()) 
                 ELSE NULL END,
            CASE WHEN p_ssl_valid = FALSE THEN 'SSL Certificate Invalid' ELSE NULL END,
            NOW()
        );
    END IF;
END//

-- Performance Status Update Procedure
DROP PROCEDURE IF EXISTS UpdatePerformanceStatus//
CREATE PROCEDURE UpdatePerformanceStatus(
    IN p_url_id INT,
    IN p_response_time_ms INT
)
BEGIN
    DECLARE warning_threshold INT DEFAULT 5000;
    DECLARE critical_threshold INT DEFAULT 10000;
    DECLARE perf_status ENUM('excellent', 'good', 'warning', 'critical');
    
    -- Get thresholds for this URL
    SELECT response_time_warning_ms, response_time_critical_ms 
    INTO warning_threshold, critical_threshold
    FROM monitored_urls 
    WHERE id = p_url_id LIMIT 1;
    
    -- Determine performance status
    IF p_response_time_ms <= warning_threshold THEN
        SET perf_status = 'excellent';
    ELSEIF p_response_time_ms <= critical_threshold THEN
        SET perf_status = 'warning';
    ELSE
        SET perf_status = 'critical';
    END IF;
    
    -- Update the latest health report with performance status
    UPDATE health_reports 
    SET performance_status = perf_status
    WHERE url_id = p_url_id 
    AND checked_at = (
        SELECT MAX(checked_at) FROM (
            SELECT checked_at FROM health_reports 
            WHERE url_id = p_url_id
        ) as latest
    )
    LIMIT 1;
END//

DELIMITER ;

-- =====================================================
-- 13. ADDITIONAL PERFORMANCE INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_config_category ON config(category, config_key);

-- =====================================================
-- 14. FINAL SETUP VERIFICATION
-- =====================================================
SELECT 
    '🎉 ENHANCED DATABASE SETUP COMPLETE!' as status,
    (SELECT COUNT(*) FROM information_schema.tables 
     WHERE table_schema = DATABASE() 
     AND table_type = 'BASE TABLE') as total_tables,
    (SELECT COUNT(*) FROM information_schema.views 
     WHERE table_schema = DATABASE()) as total_views,
    (SELECT COUNT(*) FROM information_schema.routines 
     WHERE routine_schema = DATABASE() 
     AND routine_type = 'PROCEDURE') as total_procedures,
    (SELECT COUNT(*) FROM config) as config_entries,
    (SELECT COUNT(*) FROM monitored_urls) as sample_urls,
    (SELECT COUNT(*) FROM alert_groups) as alert_groups,
    (SELECT COUNT(*) FROM alert_group_members) as alert_members,
    (SELECT COUNT(*) FROM url_alert_groups) as url_group_links,
    (SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) 
     FROM information_schema.tables 
     WHERE table_schema = DATABASE()) as database_size_mb,
    NOW() as setup_completed_at;

-- =====================================================
-- 15. QUICK TEST QUERIES FOR VERIFICATION
-- =====================================================

-- Test the main views
SELECT 'Dashboard Overview Test' as test_name, COUNT(*) as record_count FROM dashboard_overview
UNION ALL
SELECT 'URL Status Test' as test_name, COUNT(*) as record_count FROM url_status_detailed
UNION ALL
SELECT 'SSL Status Test' as test_name, COUNT(*) as record_count FROM ssl_certificate_status
UNION ALL
SELECT 'Team Performance Test' as test_name, COUNT(*) as record_count FROM team_performance_summary
UNION ALL
SELECT 'Executive Dashboard Test' as test_name, COUNT(*) as record_count FROM executive_dashboard;

-- =====================================================
-- SETUP COMPLETE! 
-- =====================================================

/*
🎉 CONGRATULATIONS! Your Enhanced Website Health Monitoring Database is ready!

✨ FEATURES INSTALLED:
• Security: Authentication, SSL monitoring, custom headers
• Performance: Response time thresholds, performance alerts
• Teams: Team-based organization and reporting
• Alerts: Multi-channel notifications with escalation
• Maintenance: Scheduled windows with alert suppression
• Reporting: 7 comprehensive views for dashboard websites

📊 DATABASE VIEWS CREATED:
• dashboard_overview - Real-time system summary
• url_status_detailed - Complete service status  
• sla_report_30day - 30-day SLA performance
• ssl_certificate_status - SSL certificate monitoring
• team_performance_summary - Team metrics
• executive_dashboard - Management KPIs
• incident_timeline_48h - Recent incidents

⚙️ STORED PROCEDURES:
• CleanOldHealthReports() - Data maintenance
• UpdateSSLCertificateInfo() - SSL updates
• UpdatePerformanceStatus() - Performance classification

🚀 NEXT STEPS:
1. Update alert emails with real addresses
2. Add your URLs with enhanced features
3. Configure SMTP for email alerts
4. Set up SSL monitoring for HTTPS sites
5. Build your reporting website using the views
6. Import the monitoring workflow to N8N

📋 QUICK VIEW EXAMPLES:
SELECT * FROM dashboard_overview;
SELECT * FROM url_status_detailed;
SELECT * FROM sla_report_30day;
SELECT * FROM ssl_certificate_status;

🌟 Your monitoring system is now enterprise-ready!
*/