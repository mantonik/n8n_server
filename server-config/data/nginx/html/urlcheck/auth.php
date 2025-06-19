<?php
// auth.php - Enhanced authentication system with demo user

require_once 'config.php';

class Auth {
    private $db;
    
    public function __construct($database) {
        $this->db = $database;
        $this->initializeDatabase();
    }
    
    private function initializeDatabase() {
        try {
            // Check if users table exists, if not create it
            $tableExists = $this->db->fetchOne("SHOW TABLES LIKE 'users'");
            
            if (!$tableExists) {
                $this->createUsersTable();
                $this->createDefaultUsers();
            } else {
                // Check if demo user exists, if not create it
                $demoUser = $this->db->fetchOne("SELECT id FROM users WHERE username = 'demo'");
                if (!$demoUser) {
                    $this->createDemoUser();
                }
            }
        } catch (Exception $e) {
            error_log("Auth initialization error: " . $e->getMessage());
        }
    }
    
    private function createUsersTable() {
        $sql = "CREATE TABLE users (
            id INT PRIMARY KEY AUTO_INCREMENT,
            username VARCHAR(50) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            full_name VARCHAR(100) NOT NULL,
            email VARCHAR(255) NOT NULL,
            role ENUM('admin', 'readonly') DEFAULT 'readonly',
            is_active BOOLEAN DEFAULT TRUE,
            
            -- Login tracking
            last_login_at TIMESTAMP NULL,
            login_count INT DEFAULT 0,
            failed_login_attempts INT DEFAULT 0,
            locked_until TIMESTAMP NULL,
            
            -- Password management
            password_changed_at TIMESTAMP NULL,
            must_change_password BOOLEAN DEFAULT FALSE,
            
            -- Demo user fields
            is_demo_user BOOLEAN DEFAULT FALSE,
            demo_session_duration INT DEFAULT 3600,
            
            -- Audit fields
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_by VARCHAR(50),
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            updated_by VARCHAR(50),
            deleted_at TIMESTAMP NULL,
            
            INDEX idx_username (username),
            INDEX idx_email (email),
            INDEX idx_role (role),
            INDEX idx_active (is_active),
            INDEX idx_demo (is_demo_user),
            INDEX idx_last_login (last_login_at)
        )";
        
        $this->db->query($sql);
    }
    
    private function createDefaultUsers() {
        // Create default admin user
        $adminPassword = password_hash(ADMIN_PASSWORD, PASSWORD_DEFAULT);
        
        $sql = "INSERT INTO users (username, password_hash, full_name, email, role, created_by) 
                VALUES (?, ?, 'System Administrator', 'admin@yourcompany.com', 'admin', 'system')";
        
        $this->db->query($sql, [ADMIN_USERNAME, $adminPassword]);
        
        // Create demo user
        $this->createDemoUser();
    }
    
    private function createDemoUser() {
        // Demo user with simple password
        $demoPassword = password_hash('demo', PASSWORD_DEFAULT);
        
        $sql = "INSERT INTO users (username, password_hash, full_name, email, role, is_demo_user, 
                demo_session_duration, created_by) 
                VALUES (?, ?, 'Demo User', 'demo@example.com', 'readonly', TRUE, 1800, 'system')";
        
        $this->db->query($sql, ['demo', $demoPassword]);
    }
    
    public function login($username, $password) {
        // Check if account is locked
        if ($this->isAccountLocked($username)) {
            return ['success' => false, 'message' => 'Account is temporarily locked. Please try again later.'];
        }
        
        // Get user from database
        $user = $this->db->fetchOne("
            SELECT id, username, password_hash, full_name, email, role, is_active, 
                   must_change_password, failed_login_attempts, is_demo_user, demo_session_duration
            FROM users 
            WHERE username = ? AND deleted_at IS NULL", [$username]);
        
        if (!$user) {
            // Check for legacy admin authentication (fallback)
            if ($username === ADMIN_USERNAME && $password === ADMIN_PASSWORD) {
                // Create user record for legacy admin if not exists
                $existingAdmin = $this->db->fetchOne("SELECT id FROM users WHERE username = ?", [ADMIN_USERNAME]);
                if (!$existingAdmin) {
                    $this->createDefaultUsers();
                    $user = $this->db->fetchOne("SELECT * FROM users WHERE username = ?", [ADMIN_USERNAME]);
                }
            }
            
            if (!$user) {
                $this->recordFailedAttempt($username);
                return ['success' => false, 'message' => 'Invalid username or password'];
            }
        }
        
        // Check if account is active
        if (!$user['is_active']) {
            return ['success' => false, 'message' => 'Account is deactivated. Please contact administrator.'];
        }
        
        // Verify password
        $passwordValid = false;
        
        if (password_verify($password, $user['password_hash'])) {
            $passwordValid = true;
        } elseif ($username === ADMIN_USERNAME && $password === ADMIN_PASSWORD) {
            // Legacy admin fallback
            $passwordValid = true;
        }
        
        if (!$passwordValid) {
            $this->recordFailedLoginAttempt($user['id'], $username);
            return ['success' => false, 'message' => 'Invalid username or password'];
        }
        
        // Successful login
        $this->recordSuccessfulLogin($user['id']);
        
        // Set session variables
        $_SESSION['authenticated'] = true;
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['username'] = $user['username'];
        $_SESSION['full_name'] = $user['full_name'];
        $_SESSION['email'] = $user['email'];
        $_SESSION['role'] = $user['role'];
        $_SESSION['is_demo_user'] = $user['is_demo_user'];
        $_SESSION['login_time'] = time();
        $_SESSION['last_activity'] = time();
        $_SESSION['must_change_password'] = $user['must_change_password'];
        
        // Set session timeout based on user type
        if ($user['is_demo_user']) {
            $_SESSION['session_timeout'] = $user['demo_session_duration'];
        } else {
            $_SESSION['session_timeout'] = SESSION_TIMEOUT;
        }
        
        // Clear failed attempts
        unset($_SESSION['failed_attempts']);
        unset($_SESSION['lockout_time']);
        
        // Log successful login
        $this->logActivity('login_success', $username, $user['id']);
        
        $message = 'Login successful';
        if ($user['is_demo_user']) {
            $sessionMinutes = round($user['demo_session_duration'] / 60);
            $message .= " (Demo session expires in {$sessionMinutes} minutes)";
        }
        
        return [
            'success' => true, 
            'message' => $message,
            'must_change_password' => $user['must_change_password'],
            'is_demo_user' => $user['is_demo_user']
        ];
    }
    
    private function isAccountLocked($username) {
        $user = $this->db->fetchOne("
            SELECT locked_until FROM users 
            WHERE username = ? AND locked_until > NOW()", [$username]);
        
        return $user !== false;
    }
    
    private function recordFailedLoginAttempt($userId, $username) {
        // Increment failed attempts
        $this->db->query("
            UPDATE users 
            SET failed_login_attempts = failed_login_attempts + 1,
                locked_until = CASE 
                    WHEN failed_login_attempts + 1 >= ? THEN DATE_ADD(NOW(), INTERVAL ? MINUTE)
                    ELSE locked_until
                END
            WHERE id = ?", [LOGIN_ATTEMPTS_LIMIT, LOGIN_LOCKOUT_TIME / 60, $userId]);
        
        $this->logActivity('login_failed', $username, $userId);
    }
    
    private function recordFailedAttempt($username) {
        // For non-existent users, still record in session to prevent enumeration
        if (!isset($_SESSION['failed_attempts'])) {
            $_SESSION['failed_attempts'] = 0;
        }
        $_SESSION['failed_attempts']++;
        
        if ($_SESSION['failed_attempts'] >= LOGIN_ATTEMPTS_LIMIT) {
            $_SESSION['lockout_time'] = time();
        }
        
        $this->logActivity('login_failed', $username);
    }
    
    private function recordSuccessfulLogin($userId) {
        $this->db->query("
            UPDATE users 
            SET last_login_at = NOW(), 
                login_count = login_count + 1,
                failed_login_attempts = 0,
                locked_until = NULL
            WHERE id = ?", [$userId]);
    }
    
    public function logout() {
        $username = $_SESSION['username'] ?? 'unknown';
        $userId = $_SESSION['user_id'] ?? null;
        
        // Log logout
        $this->logActivity('logout', $username, $userId);
        
        // Destroy session
        session_unset();
        session_destroy();
        
        return true;
    }
    
    public function isAuthenticated() {
        if (!isset($_SESSION['authenticated']) || !$_SESSION['authenticated']) {
            return false;
        }
        
        // Get session timeout (different for demo users)
        $sessionTimeout = $_SESSION['session_timeout'] ?? SESSION_TIMEOUT;
        
        // Check session timeout
        if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity']) > $sessionTimeout) {
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
    
    public function isAdmin() {
        return $this->isAuthenticated() && ($_SESSION['role'] ?? '') === 'admin';
    }
    
    public function isReadOnly() {
        return $this->isAuthenticated() && ($_SESSION['role'] ?? '') === 'readonly';
    }
    
    public function isDemoUser() {
        return $this->isAuthenticated() && ($_SESSION['is_demo_user'] ?? false);
    }
    
    public function requireAdmin() {
        $this->requireAuth();
        if (!$this->isAdmin()) {
            header('HTTP/1.0 403 Forbidden');
            die('Access denied. Administrator privileges required.');
        }
    }
    
    public function canModify() {
        return $this->isAdmin();
    }
    
    public function canView() {
        return $this->isAuthenticated();
    }
    
    private function logActivity($action, $username, $userId = null) {
        try {
            // Create activity_log table if it doesn't exist
            $tableExists = $this->db->fetchOne("SHOW TABLES LIKE 'activity_log'");
            if (!$tableExists) {
                $this->createActivityLogTable();
            }
            
            $sql = "INSERT INTO activity_log (user_id, action, username, ip_address, user_agent, created_at) 
                    VALUES (?, ?, ?, ?, ?, NOW())";
            $this->db->query($sql, [
                $userId,
                $action,
                $username,
                $_SERVER['REMOTE_ADDR'] ?? 'unknown',
                $_SERVER['HTTP_USER_AGENT'] ?? 'unknown'
            ]);
        } catch (Exception $e) {
            error_log("Activity logging failed: " . $e->getMessage());
        }
    }
    
    private function createActivityLogTable() {
        $sql = "CREATE TABLE activity_log (
            id INT PRIMARY KEY AUTO_INCREMENT,
            user_id INT,
            action VARCHAR(50) NOT NULL,
            username VARCHAR(100),
            ip_address VARCHAR(45),
            user_agent TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
            INDEX idx_user_id (user_id),
            INDEX idx_action_time (action, created_at),
            INDEX idx_username_time (username, created_at)
        )";
        $this->db->query($sql);
    }
    
    public function getSessionInfo() {
        if (!$this->isAuthenticated()) {
            return null;
        }
        
        $sessionTimeout = $_SESSION['session_timeout'] ?? SESSION_TIMEOUT;
        
        return [
            'user_id' => $_SESSION['user_id'] ?? null,
            'username' => $_SESSION['username'] ?? 'unknown',
            'full_name' => $_SESSION['full_name'] ?? 'Unknown User',
            'email' => $_SESSION['email'] ?? '',
            'role' => $_SESSION['role'] ?? 'readonly',
            'is_demo_user' => $_SESSION['is_demo_user'] ?? false,
            'login_time' => $_SESSION['login_time'] ?? time(),
            'last_activity' => $_SESSION['last_activity'] ?? time(),
            'session_expires' => ($_SESSION['last_activity'] ?? time()) + $sessionTimeout,
            'session_timeout' => $sessionTimeout,
            'must_change_password' => $_SESSION['must_change_password'] ?? false
        ];
    }
    
    public function getUserPermissions() {
        if (!$this->isAuthenticated()) {
            return [
                'can_view' => false,
                'can_modify' => false,
                'can_admin' => false,
                'is_demo' => false
            ];
        }
        
        $role = $_SESSION['role'] ?? 'readonly';
        $isDemoUser = $_SESSION['is_demo_user'] ?? false;
        
        return [
            'can_view' => true,
            'can_modify' => $role === 'admin' && !$isDemoUser,
            'can_admin' => $role === 'admin' && !$isDemoUser,
            'is_demo' => $isDemoUser,
            'role' => $role
        ];
    }
    
    public function getRemainingSessionTime() {
        if (!$this->isAuthenticated()) {
            return 0;
        }
        
        $sessionTimeout = $_SESSION['session_timeout'] ?? SESSION_TIMEOUT;
        $lastActivity = $_SESSION['last_activity'] ?? time();
        $remaining = $sessionTimeout - (time() - $lastActivity);
        
        return max(0, $remaining);
    }
    
    public function changePassword($userId, $oldPassword, $newPassword) {
        // Get current user
        $user = $this->db->fetchOne("SELECT password_hash FROM users WHERE id = ?", [$userId]);
        
        if (!$user) {
            throw new Exception('User not found');
        }
        
        // Verify old password
        if (!password_verify($oldPassword, $user['password_hash'])) {
            throw new Exception('Current password is incorrect');
        }
        
        // Validate new password
        if (strlen($newPassword) < 8) {
            throw new Exception('New password must be at least 8 characters long');
        }
        
        // Update password
        $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
        $this->db->query("
            UPDATE users 
            SET password_hash = ?, 
                password_changed_at = NOW(), 
                must_change_password = FALSE,
                updated_at = NOW()
            WHERE id = ?", [$hashedPassword, $userId]);
        
        // Clear must_change_password from session
        $_SESSION['must_change_password'] = false;
        
        $this->logActivity('password_changed', $_SESSION['username'], $userId);
        
        return true;
    }
    
    public function getRecentActivity($limit = 10) {
        if (!$this->isAdmin()) {
            return [];
        }
        
        try {
            return $this->db->fetchAll("
                SELECT al.*, u.full_name 
                FROM activity_log al
                LEFT JOIN users u ON al.user_id = u.id
                ORDER BY al.created_at DESC 
                LIMIT ?", [$limit]);
        } catch (Exception $e) {
            return [];
        }
    }
}

// Initialize authentication
$auth = new Auth($db);