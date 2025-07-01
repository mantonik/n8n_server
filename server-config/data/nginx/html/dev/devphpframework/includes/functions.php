<?php
// ========================================
// functions.php - Reusable Functions with Database Tables
// Version: 1.0.0
// Created: 2025-07-01
// Framework: PHP Modular Development Framework
// Purpose: Core functions for database operations
// Table Prefixes: c_ (configuration), g_ (global), p_ (produced)
// ========================================

/**
 * Database connection manager - Updated for dev_phpframework
 */
class DatabaseManager {
    private static $connections = [];
    
    public static function getConnection($configName = 'db_ms_config_1') {
        if (!isset(self::$connections[$configName])) {
            $config = self::loadDbConfig($configName);
            
            try {
                $pdo = new PDO(
                    "mysql:host={$config['host']};dbname={$config['database']};charset=utf8mb4",
                    $config['username'],
                    $config['password'],
                    [
                        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                        PDO::ATTR_EMULATE_PREPARES => false,
                        PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
                    ]
                );
                
                self::$connections[$configName] = $pdo;
                
            } catch (PDOException $e) {
                error_log("Database connection failed: " . $e->getMessage());
                throw new Exception("Database connection failed: " . $e->getMessage());
            }
        }
        
        return self::$connections[$configName];
    }
    
    private static function loadDbConfig($configName) {
        $configFile = "conf/$configName.sql";
        
        if (!file_exists($configFile)) {
            throw new Exception("Database config file not found: $configFile");
        }
        
        // Parse SQL config file
        $content = file_get_contents($configFile);
        $config = [];
        
        if (preg_match('/-- HOST: (.+)/', $content, $matches)) {
            $config['host'] = trim($matches[1]);
        }
        if (preg_match('/-- DATABASE: (.+)/', $content, $matches)) {
            $config['database'] = trim($matches[1]);
        }
        if (preg_match('/-- USERNAME: (.+)/', $content, $matches)) {
            $config['username'] = trim($matches[1]);
        }
        if (preg_match('/-- PASSWORD: (.+)/', $content, $matches)) {
            $config['password'] = trim($matches[1]);
        }
        
        return $config;
    }
}

/**
 * Configuration manager for c_ tables
 */
class ConfigManager {
    private static $settings = [];
    
    public static function getSetting($key, $default = null) {
        if (empty(self::$settings)) {
            self::loadSettings();
        }
        
        return isset(self::$settings[$key]) ? self::$settings[$key] : $default;
    }
    
    public static function setSetting($key, $value, $type = 'string', $description = '') {
        $db = DatabaseManager::getConnection();
        
        $stmt = $db->prepare("
            INSERT INTO c_site_settings (setting_key, setting_value, setting_type, description) 
            VALUES (?, ?, ?, ?) 
            ON DUPLICATE KEY UPDATE 
            setting_value = VALUES(setting_value), 
            setting_type = VALUES(setting_type),
            updated_at = CURRENT_TIMESTAMP
        ");
        
        $stmt->execute([$key, $value, $type, $description]);
        self::$settings[$key] = $value;
        
        return true;
    }
    
    private static function loadSettings() {
        try {
            $db = DatabaseManager::getConnection();
            $stmt = $db->prepare("SELECT setting_key, setting_value, setting_type FROM c_site_settings WHERE is_active = 1");
            $stmt->execute();
            
            while ($row = $stmt->fetch()) {
                $value = $row['setting_value'];
                
                // Convert based on type
                switch ($row['setting_type']) {
                    case 'boolean':
                        $value = filter_var($value, FILTER_VALIDATE_BOOLEAN);
                        break;
                    case 'int':
                        $value = (int)$value;
                        break;
                    case 'float':
                        $value = (float)$value;
                        break;
                    case 'json':
                        $value = json_decode($value, true);
                        break;
                }
                
                self::$settings[$row['setting_key']] = $value;
            }
        } catch (Exception $e) {
            error_log("Failed to load settings: " . $e->getMessage());
            self::$settings = [];
        }
    }
}

/**
 * Template manager for c_templates table
 */
class TemplateManager {
    public static function getTemplate($templateName) {
        $db = DatabaseManager::getConnection();
        $stmt = $db->prepare("
            SELECT * FROM c_templates 
            WHERE template_name = ? AND is_active = 1
        ");
        $stmt->execute([$templateName]);
        
        return $stmt->fetch();
    }
    
    public static function getDefaultTemplate() {
        $db = DatabaseManager::getConnection();
        $stmt = $db->prepare("
            SELECT * FROM c_templates 
            WHERE is_default = 1 AND is_active = 1 
            LIMIT 1
        ");
        $stmt->execute();
        
        $template = $stmt->fetch();
        if (!$template) {
            // Fallback to first active template
            $stmt = $db->prepare("
                SELECT * FROM c_templates 
                WHERE is_active = 1 
                ORDER BY created_at ASC 
                LIMIT 1
            ");
            $stmt->execute();
            $template = $stmt->fetch();
        }
        
        return $template;
    }
    
    public static function getTemplateConfig($templateName) {
        $template = self::getTemplate($templateName);
        if ($template && $template['config_data']) {
            return json_decode($template['config_data'], true);
        }
        return [];
    }
}

/**
 * Authentication manager - Updated for g_users and g_user_sessions tables
 */
class AuthManager {
    private static $saltClient = 'client_salt_key_2025';
    private static $saltServer = 'server_salt_key_2025';
    
    public static function authenticate($username, $password) {
        // Hash password with both salts
        $hashedPassword = self::hashPassword($password);
        
        // Check against database
        $db = DatabaseManager::getConnection();
        $stmt = $db->prepare("
            SELECT id, username, password_hash, role, is_active 
            FROM g_users 
            WHERE username = ? AND is_active = 1
        ");
        $stmt->execute([$username]);
        $user = $stmt->fetch();
        
        if ($user && password_verify($hashedPassword, $user['password_hash'])) {
            // Update last login
            $updateStmt = $db->prepare("UPDATE g_users SET last_login = NOW() WHERE id = ?");
            $updateStmt->execute([$user['id']]);
            
            // Create session
            self::createSession($user);
            
            return true;
        }
        
        return false;
    }
    
    public static function createSession($user) {
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['username'] = $user['username'];
        $_SESSION['role'] = $user['role'];
        $_SESSION['authenticated'] = true;
        
        // Store session in database
        $db = DatabaseManager::getConnection();
        $sessionToken = bin2hex(random_bytes(32));
        $expiresAt = date('Y-m-d H:i:s', time() + 3600); // 1 hour
        
        $stmt = $db->prepare("
            INSERT INTO g_user_sessions 
            (user_id, session_token, ip_address, user_agent, expires_at) 
            VALUES (?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $user['id'],
            $sessionToken,
            $_SERVER['REMOTE_ADDR'] ?? 'unknown',
            $_SERVER['HTTP_USER_AGENT'] ?? 'unknown',
            $expiresAt
        ]);
        
        $_SESSION['session_token'] = $sessionToken;
    }
    
    public static function hashPassword($password) {
        return hash('sha256', self::$saltClient . $password . self::$saltServer);
    }
    
    public static function isAuthenticated() {
        if (!isset($_SESSION['authenticated']) || $_SESSION['authenticated'] !== true) {
            return false;
        }
        
        // Check if session is still valid in database
        if (isset($_SESSION['session_token'])) {
            $db = DatabaseManager::getConnection();
            $stmt = $db->prepare("
                SELECT id FROM g_user_sessions 
                WHERE session_token = ? AND expires_at > NOW()
            ");
            $stmt->execute([$_SESSION['session_token']]);
            
            return $stmt->fetch() !== false;
        }
        
        return true;
    }
    
    public static function logout() {
        // Remove session from database
        if (isset($_SESSION['session_token'])) {
            $db = DatabaseManager::getConnection();
            $stmt = $db->prepare("DELETE FROM g_user_sessions WHERE session_token = ?");
            $stmt->execute([$_SESSION['session_token']]);
        }
        
        session_destroy();
    }
    
    public static function getCurrentUser() {
        if (self::isAuthenticated()) {
            return [
                'id' => $_SESSION['user_id'],
                'username' => $_SESSION['username'],
                'role' => $_SESSION['role']
            ];
        }
        return null;
    }
    
    public static function hasRole($role) {
        $user = self::getCurrentUser();
        return $user && $user['role'] === $role;
    }
    
    public static function isAdmin() {
        return self::hasRole('admin');
    }
}

/**
 * Page metadata manager for c_page_meta table
 */
class PageMetaManager {
    public static function getPageMeta($pagePath) {
        $db = DatabaseManager::getConnection();
        $stmt = $db->prepare("
            SELECT * FROM c_page_meta 
            WHERE page_path = ? AND is_active = 1
        ");
        $stmt->execute([$pagePath]);
        
        $meta = $stmt->fetch();
        if ($meta) {
            $result = [
                'title' => $meta['title'],
                'description' => $meta['description'],
                'keywords' => $meta['keywords'],
                'template' => $meta['template_name']
            ];
            
            // Add custom meta if exists
            if ($meta['custom_meta']) {
                $customMeta = json_decode($meta['custom_meta'], true);
                if (is_array($customMeta)) {
                    $result = array_merge($result, $customMeta);
                }
            }
            
            return $result;
        }
        
        return null;
    }
    
    public static function setPageMeta($pagePath, $meta) {
        $db = DatabaseManager::getConnection();
        
        $customMeta = $meta;
        unset($customMeta['title'], $customMeta['description'], $customMeta['keywords'], $customMeta['template']);
        
        $stmt = $db->prepare("
            INSERT INTO c_page_meta 
            (page_path, title, description, keywords, template_name, custom_meta) 
            VALUES (?, ?, ?, ?, ?, ?) 
            ON DUPLICATE KEY UPDATE 
            title = VALUES(title),
            description = VALUES(description),
            keywords = VALUES(keywords),
            template_name = VALUES(template_name),
            custom_meta = VALUES(custom_meta),
            updated_at = CURRENT_TIMESTAMP
        ");
        
        $stmt->execute([
            $pagePath,
            $meta['title'] ?? null,
            $meta['description'] ?? null,
            $meta['keywords'] ?? null,
            $meta['template'] ?? null,
            !empty($customMeta) ? json_encode($customMeta) : null
        ]);
        
        return true;
    }
}

/**
 * Logging system for g_system_logs table
 */
class Logger {
    public static function log($message, $type = 'info', $context = null) {
        try {
            $db = DatabaseManager::getConnection();
            $stmt = $db->prepare("
                INSERT INTO g_system_logs 
                (log_type, message, context, user_id, ip_address, user_agent) 
                VALUES (?, ?, ?, ?, ?, ?)
            ");
            
            $user = AuthManager::getCurrentUser();
            $userId = $user ? $user['id'] : null;
            
            $stmt->execute([
                $type,
                $message,
                $context ? json_encode($context) : null,
                $userId,
                $_SERVER['REMOTE_ADDR'] ?? 'unknown',
                $_SERVER['HTTP_USER_AGENT'] ?? 'unknown'
            ]);
            
        } catch (Exception $e) {
            error_log("Failed to write to system log: " . $e->getMessage());
        }
    }
    
    public static function error($message, $context = null) {
        self::log($message, 'error', $context);
    }
    
    public static function warning($message, $context = null) {
        self::log($message, 'warning', $context);
    }
    
    public static function info($message, $context = null) {
        self::log($message, 'info', $context);
    }
    
    public static function debug($message, $context = null) {
        self::log($message, 'debug', $context);
    }
}

/**
 * Utility functions - Updated
 */
function sanitizeInput($input) {
    return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
}

function generateCSRFToken() {
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function validateCSRFToken($token) {
    return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
}

function redirectTo($url) {
    header("Location: $url");
    exit;
}

function getBaseUrl() {
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    $path = dirname($_SERVER['SCRIPT_NAME']);
    return $protocol . '://' . $host . $path;
}

// Load configuration from database on include
try {
    ConfigManager::getSetting('debug_mode', false); // This will trigger loading
} catch (Exception $e) {
    error_log("Failed to load configuration: " . $e->getMessage());
}
?>