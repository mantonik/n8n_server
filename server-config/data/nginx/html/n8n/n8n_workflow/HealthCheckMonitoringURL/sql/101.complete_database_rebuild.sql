-- =====================================================
-- File: complete_database_rebuild.sql
-- Version: 1.0
-- Date: 2025-01-12
-- Description: Complete clean database rebuild for website health monitoring system
-- =====================================================

-- Drop and recreate database for clean start
DROP DATABASE IF EXISTS n8n_url_healthcheck;
CREATE DATABASE n8n_url_healthcheck 
    DEFAULT CHARACTER SET = 'utf8mb4' 
    COLLATE = 'utf8mb4_unicode_ci';

USE n8n_url_healthcheck;

-- =====================================================
-- 1. DATABASE VERSION TRACKING
-- =====================================================
CREATE TABLE db_version (
    id INT PRIMARY KEY AUTO_INCREMENT,
    version_number VARCHAR(20) NOT NULL,
    file_name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    sql_executed TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(50) DEFAULT 'system',
    status ENUM('applied', 'failed', 'rolled_back') DEFAULT 'applied',
    INDEX idx_version (version_number),
    INDEX idx_applied_at (applied_at)
);

-- Log initial database creation
INSERT INTO db_version (version_number, file_name, description, sql_executed) VALUES 
('1.0', 'complete_database_rebuild.sql', 'Initial clean database creation with version tracking', 'DROP DATABASE, CREATE DATABASE, CREATE ALL TABLES');

-- =====================================================
-- 2. SYSTEM CONFIGURATION
-- =====================================================
CREATE TABLE config (
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
-- 3. ALERT CONFIGURATION SYSTEM (NEW DESIGN)
-- =====================================================

-- Alert Definitions (Universal alert configurations)
CREATE TABLE alert_definitions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    alert_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Alert behavior
    cooldown_minutes INT DEFAULT 60 COMMENT 'Minutes between similar alerts',
    escalation_enabled BOOLEAN DEFAULT FALSE,
    escalation_delay_minutes INT DEFAULT 30,
    
    -- Business hours (optional feature)
    business_hours_only BOOLEAN DEFAULT FALSE,
    timezone VARCHAR(50) DEFAULT 'UTC',
    business_start_hour INT DEFAULT 9,
    business_end_hour INT DEFAULT 17,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(50) DEFAULT 'system',
    
    INDEX idx_alert_name (alert_name),
    INDEX idx_active (is_active)
);

-- Alert Contacts (Multiple contacts per alert definition)
CREATE TABLE alert_contacts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    alert_definition_id INT NOT NULL,
    contact_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(20),
    notification_type ENUM('email', 'sms', 'webhook', 'slack', 'teams') DEFAULT 'email',
    priority_order INT DEFAULT 1 COMMENT '1=primary, 2=secondary, etc.',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (alert_definition_id) REFERENCES alert_definitions(id) ON DELETE CASCADE,
    INDEX idx_alert_definition (alert_definition_id),
    INDEX idx_priority (priority_order),
    INDEX idx_active (is_active)
);

-- =====================================================
-- 4. MONITORED URLS (CLEAN DESIGN)
-- =====================================================
CREATE TABLE monitored_urls (
    id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- Basic URL information
    url VARCHAR(500) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- HTTP configuration
    http_method ENUM('GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS') DEFAULT 'GET',
    expected_response TEXT COMMENT 'Text that should be present in response',
    expected_response_chars INT DEFAULT 200 COMMENT 'Number of chars to check in response',
    timeout_seconds INT DEFAULT 30,
    
    -- Monitoring configuration
    check_interval_minutes INT DEFAULT 5,
    priority ENUM('critical', 'high', 'normal', 'low') DEFAULT 'normal',
    
    -- Organization
    team_name VARCHAR(100),
    alert_definition_id INT COMMENT 'Links to alert_definitions table',
    
    -- Failure management
    failure_threshold INT DEFAULT 5 COMMENT 'Failures before alerting',
    current_failure_count INT DEFAULT 0,
    
    -- Current status
    last_checked_at TIMESTAMP NULL,
    last_status ENUM('up', 'down', 'timeout', 'error', 'unknown') DEFAULT 'unknown',
    
    -- Authentication (optional)
    auth_header VARCHAR(255) COMMENT 'Authorization header',
    auth_token VARCHAR(255) COMMENT 'Bearer token or API key', 
    auth_username VARCHAR(100) COMMENT 'Basic auth username',
    auth_password VARCHAR(255) COMMENT 'Basic auth password (encrypted)',
    custom_headers JSON COMMENT 'Additional custom headers',
    ignore_ssl_errors BOOLEAN DEFAULT FALSE,
    
    -- SSL monitoring
    check_ssl_expiry BOOLEAN DEFAULT FALSE,
    ssl_days_warning INT DEFAULT 30,
    ssl_expires_at DATETIME NULL,
    ssl_issuer VARCHAR(255),
    ssl_last_checked TIMESTAMP NULL,
    
    -- Performance thresholds
    response_time_warning_ms INT DEFAULT 5000,
    response_time_critical_ms INT DEFAULT 10000,
    
    -- System fields
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key
    FOREIGN KEY (alert_definition_id) REFERENCES alert_definitions(id) ON DELETE SET NULL,
    
    -- Indexes
    INDEX idx_active_lastcheck (is_active, last_checked_at),
    INDEX idx_priority (priority),
    INDEX idx_next_check (check_interval_minutes, last_checked_at),
    INDEX idx_ssl_monitoring (check_ssl_expiry, ssl_expires_at),
    INDEX idx_status_priority (last_status, priority),
    INDEX idx_team (team_name),
    INDEX idx_alert_definition (alert_definition_id),
    FULLTEXT idx_search (name, description, url)
);

-- =====================================================
-- 5. HEALTH REPORTS (MONITORING RESULTS)
-- =====================================================
CREATE TABLE health_reports (
    id INT PRIMARY KEY AUTO_INCREMENT,
    url_id INT NOT NULL,
    
    -- Basic check results
    status ENUM('up', 'down', 'timeout', 'error') NOT NULL,
    response_time_ms INT,
    http_status_code INT,
    response_body_preview TEXT,
    response_headers JSON,
    error_message TEXT,
    retry_attempt INT DEFAULT 1,
    
    -- SSL information
    ssl_valid BOOLEAN NULL,
    ssl_expires_in_days INT NULL,
    ssl_error TEXT,
    
    -- Performance classification
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
-- 6. ALERT HISTORY (SENT ALERTS LOG)
-- =====================================================
CREATE TABLE alert_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    url_id INT NOT NULL,
    alert_definition_id INT,
    alert_contact_id INT,
    
    -- Alert details
    alert_type ENUM('down', 'up', 'timeout', 'error', 'ssl_expiry', 'performance_warning', 'performance_critical') NOT NULL,
    severity ENUM('info', 'warning', 'critical') DEFAULT 'warning',
    notification_type ENUM('email', 'sms', 'webhook', 'slack', 'teams') NOT NULL,
    destination VARCHAR(255) NOT NULL,
    
    -- Message content
    subject VARCHAR(255),
    message TEXT,
    
    -- Delivery tracking
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT TRUE,
    error_details TEXT,
    escalation_level INT DEFAULT 1,
    
    FOREIGN KEY (url_id) REFERENCES monitored_urls(id) ON DELETE CASCADE,
    FOREIGN KEY (alert_definition_id) REFERENCES alert_definitions(id) ON DELETE SET NULL,
    FOREIGN KEY (alert_contact_id) REFERENCES alert_contacts(id) ON DELETE SET NULL,
    
    INDEX idx_url_sent (url_id, sent_at),
    INDEX idx_alert_definition_sent (alert_definition_id, sent_at),
    INDEX idx_sent_at (sent_at),
    INDEX idx_alert_type (alert_type, sent_at),
    INDEX idx_severity (severity, sent_at)
);

-- =====================================================
-- 7. MAINTENANCE WINDOWS (OPTIONAL FEATURE)
-- =====================================================
CREATE TABLE maintenance_windows (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern VARCHAR(100) COMMENT 'Cron-like pattern',
    suppress_alerts BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_time_range (start_time, end_time),
    INDEX idx_active_windows (start_time, end_time, suppress_alerts)
);

CREATE TABLE maintenance_window_urls (
    id INT PRIMARY KEY AUTO_INCREMENT,
    maintenance_window_id INT NOT NULL,
    url_id INT NOT NULL,
    
    FOREIGN KEY (maintenance_window_id) REFERENCES maintenance_windows(id) ON DELETE CASCADE,
    FOREIGN KEY (url_id) REFERENCES monitored_urls(id) ON DELETE CASCADE,
    UNIQUE KEY unique_maintenance_url (maintenance_window_id, url_id)
);

-- =====================================================
-- 8. MONITORING VIEWS FOR DASHBOARD
-- =====================================================

-- Real-time system overview
CREATE VIEW dashboard_overview AS
SELECT 
    COUNT(*) as total_sites,
    SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) as sites_up,
    SUM(CASE WHEN mu.last_status = 'down' THEN 1 ELSE 0 END) as sites_down,
    SUM(CASE WHEN mu.last_status = 'error' THEN 1 ELSE 0 END) as sites_error,
    SUM(CASE WHEN mu.last_status = 'timeout' THEN 1 ELSE 0 END) as sites_timeout,
    SUM(CASE WHEN mu.last_status = 'unknown' THEN 1 ELSE 0 END) as sites_unknown,
    SUM(CASE WHEN mu.current_failure_count >= mu.failure_threshold THEN 1 ELSE 0 END) as sites_alerting,
    SUM(CASE WHEN mu.priority = 'critical' AND mu.last_status != 'up' THEN 1 ELSE 0 END) as critical_sites_down,
    ROUND((SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as overall_uptime_percent,
    SUM(CASE WHEN mu.check_ssl_expiry = TRUE THEN 1 ELSE 0 END) as ssl_monitored_sites,
    SUM(CASE WHEN mu.ssl_expires_at <= DATE_ADD(NOW(), INTERVAL mu.ssl_days_warning DAY) 
             AND mu.check_ssl_expiry = TRUE THEN 1 ELSE 0 END) as ssl_expiring_soon,
    MAX(mu.last_checked_at) as last_system_check,
    NOW() as report_generated_at
FROM monitored_urls mu 
WHERE mu.is_active = TRUE;

-- Current status of all URLs
CREATE VIEW url_status_current AS
SELECT 
    mu.id as url_id,
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.team_name,
    mu.last_status as current_status,
    CASE 
        WHEN mu.last_status = 'up' THEN '✅ UP'
        WHEN mu.last_status = 'down' THEN '❌ DOWN'
        WHEN mu.last_status = 'error' THEN '⚠️ ERROR'
        WHEN mu.last_status = 'timeout' THEN '⏰ TIMEOUT'
        ELSE '❓ UNKNOWN'
    END as status_display,
    mu.last_checked_at,
    mu.current_failure_count,
    mu.failure_threshold,
    CASE 
        WHEN mu.current_failure_count >= mu.failure_threshold THEN '🚨 ALERTING'
        WHEN mu.current_failure_count > 0 THEN '⚠️ FAILING'
        ELSE '✅ HEALTHY'
    END as health_status,
    hr.response_time_ms as last_response_time,
    hr.http_status_code as last_http_code,
    hr.error_message as last_error,
    ad.alert_name,
    (SELECT COUNT(*) FROM alert_contacts ac 
     WHERE ac.alert_definition_id = ad.id AND ac.is_active = TRUE) as total_alert_contacts,
    mu.is_active
FROM monitored_urls mu
LEFT JOIN health_reports hr ON mu.id = hr.url_id AND hr.checked_at = mu.last_checked_at
LEFT JOIN alert_definitions ad ON mu.alert_definition_id = ad.id
ORDER BY 
    mu.is_active DESC,
    FIELD(mu.priority, 'critical', 'high', 'normal', 'low'),
    CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END,
    mu.current_failure_count DESC,
    mu.name;

-- Alert configuration overview
CREATE VIEW alert_configuration_overview AS
SELECT 
    ad.id as alert_definition_id,
    ad.alert_name,
    ad.description,
    ad.is_active as alert_active,
    ad.cooldown_minutes,
    ad.escalation_enabled,
    ad.escalation_delay_minutes,
    ad.business_hours_only,
    COUNT(ac.id) as total_contacts,
    COUNT(CASE WHEN ac.notification_type = 'email' THEN 1 END) as email_contacts,
    COUNT(CASE WHEN ac.notification_type = 'sms' THEN 1 END) as sms_contacts,
    COUNT(CASE WHEN ac.is_active = TRUE THEN 1 END) as active_contacts,
    COUNT(mu.id) as assigned_urls,
    GROUP_CONCAT(ac.contact_email ORDER BY ac.priority_order SEPARATOR ', ') as contact_emails
FROM alert_definitions ad
LEFT JOIN alert_contacts ac ON ad.id = ac.alert_definition_id
LEFT JOIN monitored_urls mu ON ad.id = mu.alert_definition_id AND mu.is_active = TRUE
GROUP BY ad.id, ad.alert_name, ad.description, ad.is_active, ad.cooldown_minutes, 
         ad.escalation_enabled, ad.escalation_delay_minutes, ad.business_hours_only
ORDER BY ad.alert_name;

-- =====================================================
-- 9. SYSTEM CONFIGURATION DATA
-- =====================================================
INSERT INTO config (config_key, config_value, description, category) VALUES
-- Monitoring settings
('default_timeout', '30', 'Default timeout in seconds for HTTP requests', 'monitoring'),
('default_check_interval', '5', 'Default check interval in minutes', 'monitoring'),
('default_failure_threshold', '5', 'Default number of failures before alerting', 'monitoring'),
('max_concurrent_checks', '10', 'Maximum concurrent health checks', 'monitoring'),
('batch_size', '20', 'Number of URLs to process per batch', 'monitoring'),

-- Performance settings
('response_time_warning_default', '5000', 'Default response time warning threshold (ms)', 'performance'),
('response_time_critical_default', '10000', 'Default response time critical threshold (ms)', 'performance'),
('ssl_warning_days_default', '30', 'Default days before SSL expiry to warn', 'performance'),

-- Alert settings
('notification_cooldown_minutes', '60', 'Minutes to wait between same type notifications', 'alerts'),
('escalation_delay_minutes', '30', 'Minutes before escalating to next level', 'alerts'),
('alert_email_from', 'healthcheck@yourcompany.com', 'Default from email for alerts', 'alerts'),
('max_alerts_per_hour', '20', 'Maximum alerts per URL per hour', 'alerts'),

-- Security settings
('enable_ssl_monitoring', 'true', 'Enable SSL certificate monitoring', 'security'),
('default_user_agent', 'HealthCheck-Monitor/1.0', 'Default User-Agent header', 'security'),
('encrypt_auth_tokens', 'true', 'Encrypt stored authentication tokens', 'security'),

-- Maintenance settings
('data_retention_days', '90', 'Number of days to keep health report data', 'maintenance'),
('cleanup_batch_size', '1000', 'Number of records to delete per cleanup batch', 'maintenance'),
('optimize_tables_weekly', 'true', 'Run OPTIMIZE TABLE weekly', 'maintenance');

-- =====================================================
-- 10. STORED PROCEDURES
-- =====================================================

DELIMITER //

-- Cleanup old data procedure
CREATE PROCEDURE CleanOldHealthReports()
BEGIN
    DECLARE retention_days INT DEFAULT 90;
    DECLARE cleanup_batch_size INT DEFAULT 1000;
    DECLARE total_deleted INT DEFAULT 0;
    DECLARE batch_deleted INT DEFAULT 0;
    
    -- Get retention settings
    SELECT CAST(config_value AS UNSIGNED) INTO retention_days 
    FROM config WHERE config_key = 'data_retention_days' LIMIT 1;
    
    SELECT CAST(config_value AS UNSIGNED) INTO cleanup_batch_size 
    FROM config WHERE config_key = 'cleanup_batch_size' LIMIT 1;
    
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
    
    SELECT total_deleted as total_health_reports_deleted;
END //

DELIMITER ;

-- =====================================================
-- 11. FINAL VERIFICATION
-- =====================================================
SELECT 
    '🎉 CLEAN DATABASE REBUILD COMPLETE!' as status,
    (SELECT COUNT(*) FROM information_schema.tables 
     WHERE table_schema = DATABASE() 
     AND table_type = 'BASE TABLE') as total_tables,
    (SELECT COUNT(*) FROM information_schema.views 
     WHERE table_schema = DATABASE()) as total_views,
    (SELECT COUNT(*) FROM information_schema.routines 
     WHERE routine_schema = DATABASE() 
     AND routine_type = 'PROCEDURE') as total_procedures,
    (SELECT COUNT(*) FROM config) as config_entries,
    NOW() as created_at;

-- Log completion
INSERT INTO db_version (version_number, file_name, description, sql_executed) VALUES 
('1.0-complete', 'complete_database_rebuild.sql', 'Clean database rebuild completed successfully', 'All tables, views, procedures, and configuration created');

/*
=====================================================
DATABASE REBUILD COMPLETE - CLEAN SLATE v1.0
=====================================================

TABLES CREATED:
- db_version: Database change tracking
- config: System configuration
- alert_definitions: Universal alert configurations  
- alert_contacts: Multiple contacts per alert
- monitored_urls: URLs to monitor (with alert_definition_id)
- health_reports: Monitoring results
- alert_history: Sent alerts log
- maintenance_windows: Maintenance scheduling
- maintenance_window_urls: URL maintenance assignments

VIEWS CREATED:
- dashboard_overview: Real-time system summary
- url_status_current: Current status of all URLs
- alert_configuration_overview: Alert config summary

PROCEDURES CREATED:
- CleanOldHealthReports(): Data cleanup

NEXT STEPS:
1. Run sample_data_insert.sql to populate with test data
2. Update N8N workflow to use new alert system
3. Customize alert definitions for your teams

The database is now ready for the monitoring system!
*/