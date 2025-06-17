<?php
// auth.php - Authentication and session management

require_once 'config.php';

class Auth {
    private $db;
    
    public function __construct($database) {
        $this->db = $database;
    }
    
    public function login($username, $password) {
        // Check login attempts
        if ($this->isLockedOut()) {
            return ['success' => false, 'message' => 'Too many failed attempts. Please try again later.'];
        }
        
        // Simple authentication - in production, use hashed passwords
        if ($username === ADMIN_USERNAME && $password === ADMIN_PASSWORD) {
            $_SESSION['authenticated'] = true;
            $_SESSION['username'] = $username;
            $_SESSION['login_time'] = time();
            $_SESSION['last_activity'] = time();
            
            // Clear failed attempts
            unset($_SESSION['failed_attempts']);
            unset($_SESSION['lockout_time']);
            
            // Log successful login
            $this->logActivity('login_success', $username);
            
            return ['success' => true, 'message' => 'Login successful'];
        } else {
            // Record failed attempt
            $this->recordFailedAttempt();
            
            // Log failed login
            $this->logActivity('login_failed', $username);
            
            return ['success' => false, 'message' => 'Invalid username or password'];
        }
    }
    
    public function logout() {
        $username = $_SESSION['username'] ?? 'unknown';
        
        // Log logout
        $this->logActivity('logout', $username);
        
        // Destroy session
        session_unset();
        session_destroy();
        
        return true;
    }
    
    public function isAuthenticated() {
        if (!isset($_SESSION['authenticated']) || !$_SESSION['authenticated']) {
            return false;
        }
        
        // Check session timeout
        if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity']) > SESSION_TIMEOUT) {
            $this->logout();
            return false;
        }
        
        // Update last activity
        $_SESSION['last_activity'] = time();
        
        return true;
    }
    
    public function requireAuth() {
        if (!$this->isAuthenticated()) {
            header('Location: login.php');
            exit;
        }
    }
    
    private function recordFailedAttempt() {
        if (!isset($_SESSION['failed_attempts'])) {
            $_SESSION['failed_attempts'] = 0;
        }
        $_SESSION['failed_attempts']++;
        
        if ($_SESSION['failed_attempts'] >= LOGIN_ATTEMPTS_LIMIT) {
            $_SESSION['lockout_time'] = time();
        }
    }
    
    private function isLockedOut() {
        if (!isset($_SESSION['lockout_time'])) {
            return false;
        }
        
        if ((time() - $_SESSION['lockout_time']) > LOGIN_LOCKOUT_TIME) {
            // Lockout expired
            unset($_SESSION['failed_attempts']);
            unset($_SESSION['lockout_time']);
            return false;
        }
        
        return true;
    }
    
    private function logActivity($action, $username) {
        try {
            $sql = "INSERT INTO activity_log (action, username, ip_address, user_agent, created_at) 
                    VALUES (?, ?, ?, ?, NOW())";
            $this->db->query($sql, [
                $action,
                $username,
                $_SERVER['REMOTE_ADDR'] ?? 'unknown',
                $_SERVER['HTTP_USER_AGENT'] ?? 'unknown'
            ]);
        } catch (Exception $e) {
            // Create activity_log table if it doesn't exist
            $this->createActivityLogTable();
        }
    }
    
    private function createActivityLogTable() {
        try {
            $sql = "CREATE TABLE IF NOT EXISTS activity_log (
                id INT PRIMARY KEY AUTO_INCREMENT,
                action VARCHAR(50) NOT NULL,
                username VARCHAR(100),
                ip_address VARCHAR(45),
                user_agent TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_action_time (action, created_at),
                INDEX idx_username_time (username, created_at)
            )";
            $this->db->query($sql);
        } catch (Exception $e) {
            error_log("Failed to create activity_log table: " . $e->getMessage());
        }
    }
    
    public function getSessionInfo() {
        if (!$this->isAuthenticated()) {
            return null;
        }
        
        return [
            'username' => $_SESSION['username'] ?? 'unknown',
            'login_time' => $_SESSION['login_time'] ?? time(),
            'last_activity' => $_SESSION['last_activity'] ?? time(),
            'session_expires' => ($_SESSION['last_activity'] ?? time()) + SESSION_TIMEOUT
        ];
    }
}

// Initialize authentication
$auth = new Auth($db);
?>