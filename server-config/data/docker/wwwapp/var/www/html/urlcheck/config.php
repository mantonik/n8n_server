<?php
// config.php - Database and application configuration

// Database configuration
define('DB_HOST', '10.20.2.34');
define('DB_NAME', 'n8n_url_healthcheck');
define('DB_USER', 'n8nheathcheckusr');
define('DB_PASS', 'Edcvfr5687#9ikjJhsg');
define('DB_CHARSET', 'utf8mb4');

// Application configuration
define('APP_NAME', 'Website Health Monitor');
define('APP_VERSION', '1.0');
define('TIMEZONE', 'America/New_York');

// Authentication
define('ADMIN_USERNAME', 'admin');
define('ADMIN_PASSWORD', 'monitor123!'); // Change this in production
define('SESSION_TIMEOUT', 3600); // 1 hour

// Security
define('CSRF_TOKEN_NAME', 'csrf_token');
define('LOGIN_ATTEMPTS_LIMIT', 5);
define('LOGIN_LOCKOUT_TIME', 900); // 15 minutes

// Dashboard settings
define('REFRESH_INTERVAL', 30); // seconds
define('ITEMS_PER_PAGE', 20);
define('CHART_DAYS', 7);

// Public dashboard access
define('PUBLIC_DASHBOARD_ENABLED', true);
define('PUBLIC_DASHBOARD_URL', '/urlcheck/public.php');

// Set timezone
date_default_timezone_set(TIMEZONE);

// Database connection class
class Database {
    private $pdo;
    
    public function __construct() {
        try {
            $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET;
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ];
            $this->pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
        } catch (PDOException $e) {
            error_log("Database connection failed: " . $e->getMessage());
            die("Database connection failed. Please check your configuration.");
        }
    }
    
    public function getConnection() {
        return $this->pdo;
    }
    
    public function query($sql, $params = []) {
        try {
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute($params);
            return $stmt;
        } catch (PDOException $e) {
            error_log("Database query failed: " . $e->getMessage() . " SQL: " . $sql);
            throw $e;
        }
    }
    
    public function fetchAll($sql, $params = []) {
        return $this->query($sql, $params)->fetchAll();
    }
    
    public function fetchOne($sql, $params = []) {
        return $this->query($sql, $params)->fetch();
    }
    
    public function lastInsertId() {
        return $this->pdo->lastInsertId();
    }
}

// Utility functions
function formatDateTime($datetime) {
    if (!$datetime) return 'Never';
    return date('M j, Y g:i A', strtotime($datetime));
}

function formatDuration($seconds) {
    if ($seconds < 60) return $seconds . 's';
    if ($seconds < 3600) return round($seconds / 60) . 'm';
    return round($seconds / 3600, 1) . 'h';
}

function getStatusIcon($status) {
    switch ($status) {
        case 'up': return '✅';
        case 'down': return '❌';
        case 'error': return '⚠️';
        case 'timeout': return '⏰';
        default: return '❓';
    }
}

function getStatusClass($status) {
    switch ($status) {
        case 'up': return 'success';
        case 'down': return 'danger';
        case 'error': return 'warning';
        case 'timeout': return 'warning';
        default: return 'secondary';
    }
}

function getPriorityClass($priority) {
    switch ($priority) {
        case 'critical': return 'danger';
        case 'high': return 'warning';
        case 'normal': return 'info';
        case 'low': return 'secondary';
        default: return 'secondary';
    }
}

function generateCSRFToken() {
    if (empty($_SESSION[CSRF_TOKEN_NAME])) {
        $_SESSION[CSRF_TOKEN_NAME] = bin2hex(random_bytes(32));
    }
    return $_SESSION[CSRF_TOKEN_NAME];
}

function validateCSRFToken($token) {
    return isset($_SESSION[CSRF_TOKEN_NAME]) && hash_equals($_SESSION[CSRF_TOKEN_NAME], $token);
}

// Initialize session
session_start();

// Initialize database
$db = new Database();
?>