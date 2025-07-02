-- ========================================
-- db_ms_config_1.sql - Database Configuration File 1
-- Version: 1.0.0
-- Created: 2025-07-01
-- Framework: PHP Modular Development Framework
-- Purpose: Primary database configuration with table structure
-- Table Prefixes: c_ (configuration), g_ (global), p_ (produced)
-- ========================================

-- HOST: localhost
-- DATABASE: dev_phpframework
-- USERNAME: db_user1
-- PASSWORD: secure_password1

/*
create database dev_phpframework
create user devusrphpfrm@'%' identified by  'Edcvfr1928345!';
grant all privileges on dev_phpframework.* to devusrphpfrm@'%';

cd /data/nginx/html/dev/devphpframework/conf
mdl

drop database dev_phpframework;

source db_ms_cofnig_1.sql
*/

CREATE DATABASE IF NOT EXISTS dev_phpframework;
USE dev_phpframework;

-- ========================================
-- CONFIGURATION TABLES (c_ prefix)
-- ========================================

-- Site configuration settings
CREATE TABLE IF NOT EXISTS c_site_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type ENUM('string', 'int', 'float', 'boolean', 'json') DEFAULT 'string',
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Template configurations
CREATE TABLE IF NOT EXISTS c_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    template_name VARCHAR(50) UNIQUE NOT NULL,
    template_version VARCHAR(20) DEFAULT '1.0.0',
    template_path VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    config_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Database connection configurations
CREATE TABLE IF NOT EXISTS c_database_configs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    config_name VARCHAR(50) UNIQUE NOT NULL,
    host VARCHAR(255) NOT NULL,
    database_name VARCHAR(100) NOT NULL,
    username VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    port INT DEFAULT 3306,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Page metadata configurations
CREATE TABLE IF NOT EXISTS c_page_meta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    page_path VARCHAR(255) UNIQUE NOT NULL,
    title VARCHAR(255),
    description TEXT,
    keywords TEXT,
    template_name VARCHAR(50),
    custom_meta JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (template_name) REFERENCES c_templates(template_name) ON UPDATE CASCADE
);

-- ========================================
-- GLOBAL TABLES (g_ prefix)
-- ========================================

-- User accounts and authentication
CREATE TABLE IF NOT EXISTS g_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    role ENUM('admin', 'editor', 'user') DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- User sessions management
CREATE TABLE IF NOT EXISTS g_user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES g_users(id) ON DELETE CASCADE,
    INDEX idx_session_token (session_token),
    INDEX idx_expires_at (expires_at)
);

-- System logs
CREATE TABLE IF NOT EXISTS g_system_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_type ENUM('error', 'warning', 'info', 'debug') DEFAULT 'info',
    message TEXT NOT NULL,
    context JSON,
    user_id INT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES g_users(id) ON DELETE SET NULL,
    INDEX idx_log_type (log_type),
    INDEX idx_created_at (created_at)
);

-- File uploads tracking
CREATE TABLE IF NOT EXISTS g_file_uploads (
    id INT AUTO_INCREMENT PRIMARY KEY,
    original_filename VARCHAR(255) NOT NULL,
    stored_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT NOT NULL,
    mime_type VARCHAR(100),
    uploaded_by INT,
    upload_context VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (uploaded_by) REFERENCES g_users(id) ON DELETE SET NULL,
    INDEX idx_uploaded_by (uploaded_by),
    INDEX idx_upload_context (upload_context)
);

-- ========================================
-- PRODUCED TABLES (p_ prefix)
-- ========================================

-- Page content (dynamically produced)
CREATE TABLE IF NOT EXISTS p_page_content (
    id INT AUTO_INCREMENT PRIMARY KEY,
    page_path VARCHAR(255) NOT NULL,
    content_type ENUM('html', 'markdown', 'json') DEFAULT 'html',
    content LONGTEXT,
    meta_data JSON,
    created_by INT,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    published_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES g_users(id) ON DELETE SET NULL,
    INDEX idx_page_path (page_path),
    INDEX idx_status (status),
    INDEX idx_published_at (published_at)
);

-- Blog posts (if using blog functionality)
CREATE TABLE IF NOT EXISTS p_blog_posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    slug VARCHAR(255) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    excerpt TEXT,
    content LONGTEXT,
    featured_image VARCHAR(500),
    author_id INT,
    category VARCHAR(100),
    tags JSON,
    view_count INT DEFAULT 0,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    published_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES g_users(id) ON DELETE SET NULL,
    INDEX idx_slug (slug),
    INDEX idx_status (status),
    INDEX idx_published_at (published_at),
    INDEX idx_category (category)
);

-- Comments for blog posts or pages
CREATE TABLE IF NOT EXISTS p_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT,
    parent_comment_id INT NULL,
    author_name VARCHAR(100),
    author_email VARCHAR(100),
    author_user_id INT NULL,
    comment_content TEXT NOT NULL,
    ip_address VARCHAR(45),
    status ENUM('pending', 'approved', 'rejected', 'spam') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES p_blog_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES p_comments(id) ON DELETE CASCADE,
    FOREIGN KEY (author_user_id) REFERENCES g_users(id) ON DELETE SET NULL,
    INDEX idx_post_id (post_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Form submissions (contact forms, etc.)
CREATE TABLE IF NOT EXISTS p_form_submissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    form_name VARCHAR(100) NOT NULL,
    form_data JSON NOT NULL,
    submitter_ip VARCHAR(45),
    submitter_user_id INT NULL,
    status ENUM('new', 'processed', 'archived') DEFAULT 'new',
    processed_by INT NULL,
    processed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (submitter_user_id) REFERENCES g_users(id) ON DELETE SET NULL,
    FOREIGN KEY (processed_by) REFERENCES g_users(id) ON DELETE SET NULL,
    INDEX idx_form_name (form_name),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- ========================================
-- INITIAL DATA INSERTS
-- ========================================

-- Insert default site settings
INSERT IGNORE INTO c_site_settings (setting_key, setting_value, setting_type, description) VALUES
('site_name', 'My Modular Site', 'string', 'Main site title'),
('site_description', 'A modular PHP framework website', 'string', 'Site description for meta tags'),
('debug_mode', 'true', 'boolean', 'Enable/disable debug mode'),
('default_template', 'template1', 'string', 'Default template to use'),
('timezone', 'America/New_York', 'string', 'Site timezone'),
('max_upload_size', '5242880', 'int', 'Maximum file upload size in bytes'),
('admin_email', 'admin@example.com', 'string', 'Administrator email address');

-- Insert default template
INSERT IGNORE INTO c_templates (template_name, template_version, template_path, is_default, config_data) VALUES
('template1', '1.0.0', 'template/template1', TRUE, '{"colors": {"primary": "#007cba", "secondary": "#6c757d"}, "features": {"responsive": true, "dark_mode": false}}');

-- Create default admin user (password: admin123 - CHANGE IN PRODUCTION!)
INSERT IGNORE INTO g_users (username, email, password_hash, first_name, last_name, role) VALUES
('admin', 'admin@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'User', 'admin');

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================

-- Additional indexes for better performance
CREATE INDEX idx_g_users_role ON g_users(role);
CREATE INDEX idx_g_users_active ON g_users(is_active);
CREATE INDEX idx_c_site_settings_key ON c_site_settings(setting_key);
CREATE INDEX idx_c_templates_active ON c_templates(is_active);
CREATE INDEX idx_p_page_content_path_status ON p_page_content(page_path, status);

-- final parent_comment_id
commit;
