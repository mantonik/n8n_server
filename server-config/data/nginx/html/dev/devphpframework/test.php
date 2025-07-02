<?php
// ========================================
// test.php - Super Simple PHP Test
// Version: 1.0.0
// Created: 2025-07-01
// Purpose: Test basic PHP functionality step by step
// ========================================

echo "PHP Test Started\n";
echo "Time: " . date('Y-m-d H:i:s') . "\n";
echo "PHP Version: " . phpversion() . "\n";

// Test 1: Basic file operations
echo "\n=== File System Test ===\n";
echo "Current directory: " . getcwd() . "\n";
echo "Script name: " . $_SERVER['SCRIPT_NAME'] . "\n";

// Check if directories exist
$dirs = ['includes', 'conf', 'pages', 'template'];
foreach ($dirs as $dir) {
    if (is_dir($dir)) {
        echo "✓ Directory exists: $dir\n";
    } else {
        echo "✗ Directory missing: $dir\n";
    }
}

// Test 2: Try to include functions.php
echo "\n=== Include Test ===\n";
if (file_exists('includes/functions.php')) {
    echo "✓ functions.php found\n";
    try {
        require_once 'includes/functions.php';
        echo "✓ functions.php included\n";
        
        // Check what classes are available
        $classes = get_declared_classes();
        $frameworkClasses = array_filter($classes, function($class) {
            return strpos(strtolower($class), 'framework') !== false || 
                   strpos(strtolower($class), 'database') !== false ||
                   strpos(strtolower($class), 'auth') !== false;
        });
        
        echo "Framework-related classes found: " . implode(', ', $frameworkClasses) . "\n";
        
    } catch (Exception $e) {
        echo "✗ Error including functions.php: " . $e->getMessage() . "\n";
    }
} else {
    echo "✗ functions.php not found\n";
}

// Test 3: Check what happens when we try to create the framework
echo "\n=== Framework Creation Test ===\n";
if (class_exists('ModularFramework')) {
    echo "✓ ModularFramework class exists\n";
    try {
        $framework = new ModularFramework();
        echo "✓ Framework created successfully\n";
    } catch (Exception $e) {
        echo "✗ Framework creation failed: " . $e->getMessage() . "\n";
        echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    }
} else {
    echo "✗ ModularFramework class not found\n";
}

echo "\nTest completed.\n";
?>