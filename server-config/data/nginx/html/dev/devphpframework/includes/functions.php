// ========================================
// includes/functions.php - Reusable Functions
// ========================================

/**
 * Database connection manager
 */
class DatabaseManager {
    private static $connections = [];
    
    public static function getConnection($configName = 'db_ms_config_1') {
        if (!isset(self::$connections[$configName])) {
            $config = self::loadDbConfig($configName);
            
            try {
                $pdo = new PDO(
                    "mysql:host={$config['host']};dbname={$config['database']};charset=utf8",
                    $config['username'],
                    $config['password'],
                    [
                        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                        PDO::ATTR_EMULATE_PREPARES => false
                    ]
                );
                
                self::$connections[$configName] = $pdo;
                
            } catch (PDOException $e) {
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
        
        // Parse SQL config file (basic implementation)
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
 * Authentication manager
 */
class AuthManager {
    private static $saltClient = 'client_salt_key_2025';
    private static $saltServer = 'server_salt_key_2025';
    
    public static function authenticate($username, $password) {
        // Hash password with both salts
        $hashedPassword = self::hashPassword($password);
        
        // Check against database
        $db = DatabaseManager::getConnection();
        $stmt = $db->prepare("SELECT id, username, password_hash FROM users WHERE username = ?");
        $stmt->execute([$username]);
        $user = $stmt->fetch();
        
        if ($user && password_verify($hashedPassword, $user['password_hash'])) {
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['username'] = $user['username'];
            $_SESSION['authenticated'] = true;
            return true;
        }
        
        return false;
    }
    
    public static function hashPassword($password) {
        return hash('sha256', self::$saltClient . $password . self::$saltServer);
    }
    
    public static function isAuthenticated() {
        return isset($_SESSION['authenticated']) && $_SESSION['authenticated'] === true;
    }
    
    public static function logout() {
        session_destroy();
    }
    
    public static function getCurrentUser() {
        if (self::isAuthenticated()) {
            return [
                'id' => $_SESSION['user_id'],
                'username' => $_SESSION['username']
            ];
        }
        return null;
    }
}

/**
 * Utility functions
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