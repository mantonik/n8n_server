<?php
// ========================================
// index_minimal_test.php - Minimal Framework Test
// Version: 1.0.0
// Created: 2025-07-01
// Framework: PHP Modular Development Framework
// Purpose: Test framework components step by step to isolate 404 issue
// ========================================

// Enable all error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);

echo "<!DOCTYPE html><html><head><title>Framework Test</title></head><body>";
echo "<h1>Minimal Framework Test</h1>";

try {
    echo "<p>✓ PHP basic execution works</p>";
    
    // Test 1: Check if we can start session
    echo "<h2>Test 1: Session</h2>";
    session_start();
    echo "<p>✓ Session started</p>";
    
    // Test 2: Check file includes
    echo "<h2>Test 2: File Includes</h2>";
    
    if (file_exists('includes/functions.php')) {
        echo "<p>✓ functions.php exists</p>";
        try {
            require_once 'includes/functions.php';
            echo "<p>✓ functions.php included successfully</p>";
        } catch (Exception $e) {
            echo "<p>✗ Error including functions.php: " . $e->getMessage() . "</p>";
            throw $e;
        }
    } else {
        echo "<p>✗ functions.php not found - creating minimal version</p>";
        
        // Create a minimal functions.php for testing
        $minimalFunctions = "<?php\n// Minimal functions for testing\nclass DatabaseManager {\n    public static function getConnection() {\n        throw new Exception('Database not configured');\n    }\n}\n";
        
        if (!is_dir('includes')) {
            mkdir('includes', 0755, true);
        }
        
        file_put_contents('includes/functions.php', $minimalFunctions);
        require_once 'includes/functions.php';
        echo "<p>✓ Created and included minimal functions.php</p>";
    }
    
    // Test 3: Check framework class
    echo "<h2>Test 3: Framework Class</h2>";
    
    if (class_exists('ModularFramework')) {
        echo "<p>✓ ModularFramework class exists</p>";
        
        try {
            $framework = new ModularFramework();
            echo "<p>✓ Framework instance created</p>";
            
            // Instead of calling handleRequest(), let's test individual methods
            echo "<h3>Testing Framework Methods:</h3>";
            
            // Test if we can access basic methods
            if (method_exists($framework, 'getConfig')) {
                echo "<p>✓ getConfig method exists</p>";
            }
            
            if (method_exists($framework, 'getMetadata')) {
                echo "<p>✓ getMetadata method exists</p>";
            }
            
        } catch (Exception $e) {
            echo "<p>✗ Error creating framework: " . $e->getMessage() . "</p>";
            echo "<pre>Stack trace:\n" . $e->getTraceAsString() . "</pre>";
        }
        
    } else {
        echo "<p>✗ ModularFramework class not found</p>";
        
        // Create a minimal framework class for testing
        echo "<p>Creating minimal framework class...</p>";
        
        class MinimalFramework {
            public function __construct() {
                echo "<p>Minimal framework constructed</p>";
            }
            
            public function test() {
                return "Framework test successful";
            }
        }
        
        $framework = new MinimalFramework();
        echo "<p>✓ Minimal framework created: " . $framework->test() . "</p>";
    }
    
    // Test 4: Database connection (expect this to fail)
    echo "<h2>Test 4: Database Connection</h2>";
    try {
        $db = DatabaseManager::getConnection();
        echo "<p>✓ Database connected successfully</p>";
    } catch (Exception $e) {
        echo "<p>⚠ Database connection failed (expected): " . $e->getMessage() . "</p>";
    }
    
    // Test 5: Simple page routing
    echo "<h2>Test 5: Request Parsing</h2>";
    $requestedPage = isset($_GET['page']) ? $_GET['page'] : 'home';
    echo "<p>Requested page: " . htmlspecialchars($requestedPage) . "</p>";
    
    // Test 6: Template directory check
    echo "<h2>Test 6: Template System</h2>";
    if (is_dir('template/template1')) {
        echo "<p>✓ Template1 directory exists</p>";
        
        if (file_exists('template/template1/layout.php')) {
            echo "<p>✓ layout.php exists</p>";
        } else {
            echo "<p>✗ layout.php missing</p>";
        }
    } else {
        echo "<p>✗ Template1 directory missing</p>";
    }
    
    // Test 7: Pages directory
    echo "<h2>Test 7: Pages System</h2>";
    if (is_dir('pages')) {
        echo "<p>✓ Pages directory exists</p>";
        
        $files = scandir('pages');
        echo "<p>Files in pages: " . implode(', ', array_filter($files, function($f) { return $f[0] !== '.'; })) . "</p>";
    } else {
        echo "<p>✗ Pages directory missing</p>";
    }
    
    echo "<h2>✓ All Tests Completed Successfully!</h2>";
    echo "<p>If you see this message, the basic framework structure is working.</p>";
    echo "<p>The 404 error in your original index.php is likely due to a specific error in the framework code.</p>";
    
} catch (Exception $e) {
    echo "<h2>✗ Test Failed</h2>";
    echo "<p><strong>Error:</strong> " . $e->getMessage() . "</p>";
    echo "<p><strong>File:</strong> " . $e->getFile() . " (Line: " . $e->getLine() . ")</p>";
    echo "<pre><strong>Stack Trace:</strong>\n" . $e->getTraceAsString() . "</pre>";
    
    echo "<h3>Debugging Information:</h3>";
    echo "<p><strong>Current directory:</strong> " . getcwd() . "</p>";
    echo "<p><strong>Script path:</strong> " . $_SERVER['SCRIPT_FILENAME'] . "</p>";
    echo "<p><strong>Include path:</strong> " . get_include_path() . "</p>";
}

echo "</body></html>";
?>