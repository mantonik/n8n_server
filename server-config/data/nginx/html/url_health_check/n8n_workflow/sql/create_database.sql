-- Database: n8n_url_healthcheck

CREATE DATABASE n8n_url_healthcheck
    DEFAULT CHARACTER SET = 'utf8mb4';

-- Configuration table for global settings
CREATE TABLE config (
    id INT PRIMARY KEY AUTO_INCREMENT,
    config_key VARCHAR(50) UNIQUE NOT NULL,
    config_value VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- URLs to monitor with comprehensive settings
CREATE TABLE monitored_urls (
    id INT PRIMARY KEY AUTO_INCREMENT,
    url VARCHAR(500) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    expected_response TEXT,
    expected_response_chars INT DEFAULT 200, -- Number of chars to store from response
    http_method ENUM('GET', 'POST', 'PUT', 'DELETE', 'HEAD') DEFAULT 'GET',
    timeout_seconds INT DEFAULT 30,
    check_interval_minutes INT DEFAULT 5,
    priority ENUM('critical', 'high', 'normal', 'low') DEFAULT 'normal',
    contact_person VARCHAR(100),
    contact_email VARCHAR(255),
    team_name VARCHAR(100),
    failure_threshold INT DEFAULT 5, -- How many failures before alert
    current_failure_count INT DEFAULT 0,
    last_checked_at TIMESTAMP NULL,
    last_status ENUM('up', 'down', 'timeout', 'error', 'unknown') DEFAULT 'unknown',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_active_lastcheck (is_active, last_checked_at),
    INDEX idx_priority (priority),
    INDEX idx_next_check (check_interval_minutes, last_checked_at)
);

-- Health check reports with detailed information
CREATE TABLE health_reports (
    id INT PRIMARY KEY AUTO_INCREMENT,
    url_id INT NOT NULL,
    status ENUM('up', 'down', 'timeout', 'error') NOT NULL,
    response_time_ms INT,
    http_status_code INT,
    response_body_preview TEXT, -- First X characters of response
    response_headers JSON, -- Store important headers
    error_message TEXT,
    retry_attempt INT DEFAULT 1,
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (url_id) REFERENCES monitored_urls(id) ON DELETE CASCADE,
    INDEX idx_url_checked (url_id, checked_at),
    INDEX idx_checked_at (checked_at),
    INDEX idx_status_time (status, checked_at)
);

-- Alert groups for managing notification recipients
CREATE TABLE alert_groups (
    id INT PRIMARY KEY AUTO_INCREMENT,
    group_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Alert group members (emails, SMS numbers, etc.)
CREATE TABLE alert_group_members (
    id INT PRIMARY KEY AUTO_INCREMENT,
    group_id INT NOT NULL,
    notification_type ENUM('email', 'sms', 'telegram', 'webhook') NOT NULL,
    destination VARCHAR(255) NOT NULL, -- email, phone number, telegram chat_id, webhook URL
    member_name VARCHAR(100), -- Optional name for the recipient
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES alert_groups(id) ON DELETE CASCADE,
    INDEX idx_group_type (group_id, notification_type),
    INDEX idx_group_active (group_id, is_active)
);

-- Link URLs to alert groups instead of individual notifications
CREATE TABLE url_alert_groups (
    id INT PRIMARY KEY AUTO_INCREMENT,
    url_id INT NOT NULL,
    group_id INT NOT NULL,
    alert_on_down BOOLEAN DEFAULT TRUE,
    alert_on_up BOOLEAN DEFAULT TRUE, -- Recovery notifications
    alert_on_timeout BOOLEAN DEFAULT TRUE,
    alert_on_error BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (url_id) REFERENCES monitored_urls(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES alert_groups(id) ON DELETE CASCADE,
    UNIQUE KEY unique_url_group (url_id, group_id),
    INDEX idx_url_alerts (url_id, is_active),
    INDEX idx_group_urls (group_id, is_active)
);

-- Updated alert history to include group information
CREATE TABLE alert_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    url_id INT NOT NULL,
    group_id INT, -- Reference to alert group
    notification_type ENUM('email', 'sms', 'telegram', 'webhook') NOT NULL,
    destination VARCHAR(255) NOT NULL,
    alert_type ENUM('down', 'up', 'timeout', 'error') NOT NULL,
    message TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT TRUE,
    error_details TEXT,
    FOREIGN KEY (url_id) REFERENCES monitored_urls(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES alert_groups(id) ON DELETE SET NULL,
    INDEX idx_url_sent (url_id, sent_at),
    INDEX idx_group_sent (group_id, sent_at),
    INDEX idx_sent_at (sent_at)
);

-- Insert default configuration values
INSERT INTO config (config_key, config_value, description) VALUES
('default_timeout', '30', 'Default timeout in seconds for HTTP requests'),
('default_check_interval', '5', 'Default check interval in minutes'),
('default_failure_threshold', '5', 'Default number of failures before sending alert'),
('data_retention_days', '30', 'Number of days to keep health report data'),
('retry_delay_seconds', '30', 'Seconds to wait before retry'),
('max_response_preview_chars', '200', 'Maximum characters to store from response body'),
('notification_cooldown_minutes', '60', 'Minutes to wait between same type notifications for same URL');

-- Sample data for testing
INSERT INTO monitored_urls (url, name, description, priority, contact_person, contact_email) VALUES
('https://www.google.com', 'Google Search', 'Main Google search page', 'critical', 'Admin', 'admin@company.com'),
('https://httpstat.us/200', 'HTTP Status Test 200', 'Test endpoint that returns 200', 'normal', 'Dev Team', 'dev@company.com'),
('https://httpstat.us/500', 'HTTP Status Test 500', 'Test endpoint that returns 500 (for testing alerts)', 'low', 'Dev Team', 'dev@company.com');

-- Sample notification settings
INSERT INTO notification_settings (url_id, notification_type, destination) VALUES
(1, 'email', 'admin@company.com'),
(1, 'sms', '1234567890@vztext.com'),
(2, 'email', 'dev@company.com');

-- Create procedure to clean old data (run daily)
DELIMITER //
CREATE PROCEDURE CleanOldHealthReports()
BEGIN
    DECLARE retention_days INT DEFAULT 30;
    
    -- Get retention period from config
    SELECT CAST(config_value AS UNSIGNED) INTO retention_days 
    FROM config WHERE config_key = 'data_retention_days';
    
    -- Delete old health reports
    DELETE FROM health_reports 
    WHERE checked_at < DATE_SUB(NOW(), INTERVAL retention_days DAY);
    
    -- Delete old alert history
    DELETE FROM alert_history 
    WHERE sent_at < DATE_SUB(NOW(), INTERVAL retention_days DAY);
    
    SELECT ROW_COUNT() as deleted_records;
END //
DELIMITER ;

-- Create view for easy monitoring dashboard
CREATE VIEW url_status_summary AS
SELECT 
    u.id,
    u.name,
    u.url,
    u.priority,
    u.last_status,
    u.last_checked_at,
    u.current_failure_count,
    u.failure_threshold,
    u.check_interval_minutes,
    CASE 
        WHEN u.last_checked_at IS NULL THEN 'Never checked'
        WHEN u.last_checked_at < DATE_SUB(NOW(), INTERVAL (u.check_interval_minutes + 2) MINUTE) THEN 'Overdue'
        ELSE 'On schedule'
    END as check_status,
    (SELECT AVG(response_time_ms) 
     FROM health_reports hr 
     WHERE hr.url_id = u.id 
       AND hr.checked_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)
       AND hr.status = 'up'
    ) as avg_response_24h
FROM monitored_urls u
WHERE u.is_active = TRUE
ORDER BY 
    FIELD(u.priority, 'critical', 'high', 'normal', 'low'),
    u.name;