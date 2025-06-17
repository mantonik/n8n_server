<?php
// index.php - Main entry point with error debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);

echo "<h2>Website Health Monitor - Debug Information</h2>";
echo "<p>Checking system components...</p>";

// Test 1: Check PHP version
echo "<h3>1. PHP Version Check</h3>";
echo "<p>PHP Version: " . phpversion() . "</p>";
if (version_compare(phpversion(), '7.4', '<')) {
    echo "<p style='color: red;'>❌ PHP version too old. Requires 7.4+</p>";
} else {
    echo "<p style='color: green;'>✅ PHP version OK</p>";
}

// Test 2: Check required extensions
echo "<h3>2. PHP Extensions Check</h3>";
$required_extensions = ['pdo', 'pdo_mysql', 'session', 'json'];
foreach ($required_extensions as $ext) {
    if (extension_loaded($ext)) {
        echo "<p style='color: green;'>✅ $ext extension loaded</p>";
    } else {
        echo "<p style='color: red;'>❌ $ext extension missing</p>";
    }
}

// Test 3: Check file permissions and existence
echo "<h3>3. File System Check</h3>";
$required_files = ['config.php', 'auth.php', 'login.php', 'dashboard.php'];
foreach ($required_files as $file) {
    if (file_exists($file)) {
        if (is_readable($file)) {
            echo "<p style='color: green;'>✅ $file exists and readable</p>";
        } else {
            echo "<p style='color: orange;'>⚠️ $file exists but not readable</p>";
        }
    } else {
        echo "<p style='color: red;'>❌ $file missing</p>";
    }
}

// Test 4: Try to include config.php
echo "<h3>4. Configuration File Test</h3>";
try {
    if (file_exists('config.php')) {
        echo "<p>Attempting to include config.php...</p>";
        require_once 'config.php';
        echo "<p style='color: green;'>✅ config.php included successfully</p>";
        
        // Check if constants are defined
        $constants = ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASS', 'APP_NAME'];
        foreach ($constants as $const) {
            if (defined($const)) {
                echo "<p style='color: green;'>✅ $const defined</p>";
            } else {
                echo "<p style='color: red;'>❌ $const not defined</p>";
            }
        }
    } else {
        echo "<p style='color: red;'>❌ config.php file not found</p>";
    }
} catch (ParseError $e) {
    echo "<p style='color: red;'>❌ Parse error in config.php: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<p>Line: " . $e->getLine() . "</p>";
    echo "<p>File: " . $e->getFile() . "</p>";
} catch (Error $e) {
    echo "<p style='color: red;'>❌ Fatal error in config.php: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<p>Line: " . $e->getLine() . "</p>";
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Exception in config.php: " . htmlspecialchars($e->getMessage()) . "</p>";
}

// Test 5: Try database connection
echo "<h3>5. Database Connection Test</h3>";
if (defined('DB_HOST') && defined('DB_NAME') && defined('DB_USER') && defined('DB_PASS')) {
    try {
        echo "<p>Attempting database connection...</p>";
        echo "<p>Host: " . DB_HOST . "</p>";
        echo "<p>Database: " . DB_NAME . "</p>";
        echo "<p>User: " . DB_USER . "</p>";
        
        $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];
        
        $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
        echo "<p style='color: green;'>✅ Database connection successful</p>";
        
        // Test a simple query
        $stmt = $pdo->query("SELECT VERSION() as version");
        $result = $stmt->fetch();
        echo "<p>MySQL Version: " . $result['version'] . "</p>";
        
        // Check if required tables exist
        $tables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
        echo "<p>Found " . count($tables) . " tables in database</p>";
        
        $required_tables = ['monitored_urls', 'alert_definitions', 'alert_contacts', 'health_reports', 'config'];
        foreach ($required_tables as $table) {
            if (in_array($table, $tables)) {
                echo "<p style='color: green;'>✅ Table '$table' exists</p>";
            } else {
                echo "<p style='color: red;'>❌ Table '$table' missing</p>";
            }
        }
        
    } catch (PDOException $e) {
        echo "<p style='color: red;'>❌ Database connection failed: " . htmlspecialchars($e->getMessage()) . "</p>";
        echo "<p>Error Code: " . $e->getCode() . "</p>";
    } catch (Exception $e) {
        echo "<p style='color: red;'>❌ Database error: " . htmlspecialchars($e->getMessage()) . "</p>";
    }
} else {
    echo "<p style='color: red;'>❌ Database constants not defined</p>";
}

// Test 6: Try to include auth.php
echo "<h3>6. Authentication System Test</h3>";
try {
    if (file_exists('auth.php')) {
        echo "<p>Attempting to include auth.php...</p>";
        require_once 'auth.php';
        echo "<p style='color: green;'>✅ auth.php included successfully</p>";
        
        if (class_exists('Auth')) {
            echo "<p style='color: green;'>✅ Auth class found</p>";
        } else {
            echo "<p style='color: red;'>❌ Auth class not found</p>";
        }
    } else {
        echo "<p style='color: red;'>❌ auth.php file not found</p>";
    }
} catch (ParseError $e) {
    echo "<p style='color: red;'>❌ Parse error in auth.php: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<p>Line: " . $e->getLine() . "</p>";
} catch (Error $e) {
    echo "<p style='color: red;'>❌ Fatal error in auth.php: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<p>Line: " . $e->getLine() . "</p>";
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Exception in auth.php: " . htmlspecialchars($e->getMessage()) . "</p>";
}

// Test 7: Session functionality
echo "<h3>7. Session Test</h3>";
try {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
        echo "<p style='color: green;'>✅ Session started successfully</p>";
        echo "<p>Session ID: " . session_id() . "</p>";
    } else {
        echo "<p style='color: green;'>✅ Session already active</p>";
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Session error: " . htmlspecialchars($e->getMessage()) . "</p>";
}

// Test 8: Check server environment
echo "<h3>8. Server Environment</h3>";
echo "<p>Server Software: " . ($_SERVER['SERVER_SOFTWARE'] ?? 'Unknown') . "</p>";
echo "<p>Document Root: " . ($_SERVER['DOCUMENT_ROOT'] ?? 'Unknown') . "</p>";
echo "<p>Script Filename: " . ($_SERVER['SCRIPT_FILENAME'] ?? 'Unknown') . "</p>";
echo "<p>Current Working Directory: " . getcwd() . "</p>";
echo "<p>Script Directory: " . __DIR__ . "</p>";

// Test 9: Memory and error log info
echo "<h3>9. System Resources</h3>";
echo "<p>Memory Limit: " . ini_get('memory_limit') . "</p>";
echo "<p>Max Execution Time: " . ini_get('max_execution_time') . " seconds</p>";
echo "<p>Error Log: " . ini_get('error_log') . "</p>";
echo "<p>Display Errors: " . (ini_get('display_errors') ? 'On' : 'Off') . "</p>";

// Test 10: Try the normal redirect logic
echo "<h3>10. Normal Application Logic Test</h3>";
try {
    if (isset($auth) && class_exists('Auth')) {
        echo "<p>Testing authentication check...</p>";
        
        if ($auth->isAuthenticated()) {
            echo "<p style='color: green;'>✅ User is authenticated - would redirect to dashboard.php</p>";
            echo "<p><a href='dashboard.php'>Go to Dashboard</a></p>";
        } else {
            echo "<p style='color: green;'>✅ User not authenticated - would redirect to login.php</p>";
            echo "<p><a href='login.php'>Go to Login</a></p>";
        }
    } else {
        echo "<p style='color: red;'>❌ Auth system not available</p>";
        echo "<p><a href='login.php'>Try Login Page Directly</a></p>";
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error in application logic: " . htmlspecialchars($e->getMessage()) . "</p>";
}

// Display recent PHP error log entries if accessible
echo "<h3>11. Recent Error Log Entries</h3>";
$error_log = ini_get('error_log');
if ($error_log && file_exists($error_log) && is_readable($error_log)) {
    $log_lines = file($error_log);
    $recent_lines = array_slice($log_lines, -10); // Last 10 lines
    echo "<pre style='background: #f5f5f5; padding: 10px; border: 1px solid #ddd;'>";
    foreach ($recent_lines as $line) {
        echo htmlspecialchars($line);
    }
    echo "</pre>";
} else {
    echo "<p>Error log not accessible or not configured</p>";
}

echo "<hr>";
echo "<h3>Next Steps:</h3>";
echo "<ol>";
echo "<li>Review the errors above and fix any red ❌ items</li>";
echo "<li>Check your web server error logs for additional details</li>";
echo "<li>Verify file permissions (files should be readable by web server)</li>";
echo "<li>If database connection fails, verify credentials and database exists</li>";
echo "<li>Once all tests pass, remove this debug code and restore normal index.php</li>";
echo "</ol>";

echo "<p><strong>After fixing issues, restore the original index.php:</strong></p>";
echo "<pre style='background: #f0f0f0; padding: 10px;'>";
echo htmlspecialchars('<?php
// index.php - Main entry point
require_once \'config.php\';
require_once \'auth.php\';

// Check if user is authenticated
if ($auth->isAuthenticated()) {
    // Redirect to dashboard
    header(\'Location: dashboard.php\');
} else {
    // Redirect to login
    header(\'Location: login.php\');
}
exit;
?>');
echo "</pre>";
?>

<style>
body {
    font-family: Arial, sans-serif;
    max-width: 1000px;
    margin: 20px auto;
    padding: 20px;
    line-height: 1.6;
    background: #f9f9f9;
}

h2 {
    color: #333;
    border-bottom: 3px solid #667eea;
    padding-bottom: 10px;
}

h3 {
    color: #555;
    margin-top: 30px;
    padding: 10px;
    background: #e9ecef;
    border-left: 4px solid #667eea;
}

pre {
    font-size: 12px;
    overflow-x: auto;
    max-height: 200px;
}

a {
    color: #667eea;
    text-decoration: none;
    font-weight: bold;
}

a:hover {
    text-decoration: underline;
}

ol li {
    margin-bottom: 5px;
}
</style>