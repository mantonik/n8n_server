<?php
// ========================================
// debug_php_framework.php - PHP Framework Debug Script
// Version: 1.0.0
// Created: 2025-07-01
// Framework: PHP Modular Development Framework
// Purpose: Debug and test framework components step by step
// ========================================

error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '/tmp/php_debug.log');

echo "<h1>PHP Framework Debug Script</h1>";
echo "<p>Testing framework components step by step...</p>";

echo "<h2>1. Basic PHP Test</h2>";
echo "✓ PHP is working<br>";
echo "PHP Version: " . phpversion() . "<br>";
echo "Current time: " . date('Y-m-d H:i:s') . "<br>";

echo "<h2>2. File System Check</h2>";
$webroot = '/data/nginx/html/dev/devphpframework';
echo "Document root: $webroot<br>";
echo "Current directory: " . getcwd() . "<br>";
echo "Script filename: " . $_SERVER['SCRIPT_FILENAME'] . "<br>";

// Check if required directories exist
$directories = ['includes', 'conf', 'pages', 'template'];
foreach ($directories as $dir) {
    $path = $webroot . '/' . $dir;
    if (is_dir($path)) {
        echo "✓ Directory exists: $dir<br>";
    } else {
        echo "✗ Directory missing: $dir<br>";
    }
}

echo "<h2>3. Required Files Check</h2>";
$requiredFiles = [
    'includes/functions.php',
    'conf/config.php',
    'pages/info.php'
];

foreach ($requiredFiles as $file) {
    $path = $webroot . '/' . $file;
    if (file_exists($path)) {
        echo "✓ File exists: $file<br>";
        if (is_readable($path)) {
            echo "&nbsp;&nbsp;✓ File is readable<br>";
        } else {
            echo "&nbsp;&nbsp;✗ File is not readable<br>";
        }
    } else {
        echo "✗ File missing: $file<br>";
    }
}

echo "<h2>4. Database Connection Test</h2>";
try {
    // Test if we can include functions.php
    $functionsPath = $webroot . '/includes/functions.php';
    if (file_exists($functionsPath)) {
        echo "Attempting to include functions.php...<br>";
        include_once $functionsPath;
        echo "✓ functions.php included successfully<br>";
        
        // Test database connection
        echo "Testing database connection...<br>";
        try {
            $db = DatabaseManager::getConnection();
            echo "✓ Database connection successful<br>";
            
            // Test a simple query
            $stmt = $db->query("SELECT 1 as test");
            $result = $stmt->fetch();
            echo "✓ Database query test: " . $result['test'] . "<br>";
            
        } catch (Exception $e) {
            echo "✗ Database connection failed: " . $e->getMessage() . "<br>";
            echo "This might be expected if database isn't configured yet.<br>";
        }
        
    } else {
        echo "✗ functions.php not found - cannot test database<br>";
    }
} catch (Exception $e) {
    echo "✗ Error including functions.php: " . $e->getMessage() . "<br>";
    echo "Stack trace:<br>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
}

echo "<h2>5. Session Test</h2>";
try {
    session_start();
    echo "✓ Session started successfully<br>";
    echo "Session ID: " . session_id() . "<br>";
} catch (Exception $e) {
    echo "✗ Session start failed: " . $e->getMessage() . "<br>";
}

echo "<h2>6. Template System Test</h2>";
$templatePath = $webroot . '/template/template1';
if (is_dir($templatePath)) {
    echo "✓ Template1 directory exists<br>";
    
    $templateFiles = ['layout.php', 'header.php', 'footer.php'];
    foreach ($templateFiles as $file) {
        $path = $templatePath . '/' . $file;
        if (file_exists($path)) {
            echo "&nbsp;&nbsp;✓ $file exists<br>";
        } else {
            echo "&nbsp;&nbsp;✗ $file missing<br>";
        }
    }
} else {
    echo "✗ Template1 directory missing<br>";
}

echo "<h2>7. Framework Class Test</h2>";
try {
    // Test if we can create the framework class
    if (class_exists('ModularFramework')) {
        echo "✓ ModularFramework class exists<br>";
        
        // Try to create an instance (but don't call handleRequest)
        $framework = new ModularFramework();
        echo "✓ ModularFramework instance created<br>";
        
    } else {
        echo "✗ ModularFramework class not found<br>";
    }
} catch (Exception $e) {
    echo "✗ Error creating framework instance: " . $e->getMessage() . "<br>";
    echo "Stack trace:<br>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
}

echo "<h2>8. Request Information</h2>";
echo "Request Method: " . ($_SERVER['REQUEST_METHOD'] ?? 'Unknown') . "<br>";
echo "Request URI: " . ($_SERVER['REQUEST_URI'] ?? 'Unknown') . "<br>";
echo "Query String: " . ($_SERVER['QUERY_STRING'] ?? 'None') . "<br>";
echo "GET Parameters:<br>";
echo "<pre>" . print_r($_GET, true) . "</pre>";

echo "<h2>9. Error Log Check</h2>";
if (file_exists('/tmp/php_debug.log')) {
    echo "Recent PHP errors:<br>";
    echo "<pre>" . file_get_contents('/tmp/php_debug.log') . "</pre>";
} else {
    echo "No PHP error log found at /tmp/php_debug.log<br>";
}

// Check system error log
if (file_exists('/var/log/php_errors.log')) {
    echo "System PHP errors (last 10 lines):<br>";
    $lines = file('/var/log/php_errors.log');
    $lastLines = array_slice($lines, -10);
    echo "<pre>" . implode('', $lastLines) . "</pre>";
} else {
    echo "No system PHP error log found<br>";
}

echo "<h2>10. Recommendations</h2>";
echo "<p>Based on the tests above:</p>";
echo "<ul>";
echo "<li>If database connection failed, that's normal - configure your database first</li>";
echo "<li>If any files are missing, create them according to the framework structure</li>";
echo "<li>If class errors occurred, check the PHP syntax in your files</li>";
echo "<li>Check the error logs above for specific PHP errors</li>";
echo "</ul>";

echo "<hr>";
echo "<p><strong>Debug completed at:</strong> " . date('Y-m-d H:i:s') . "</p>";
?>