<?php
// setup_database.php - One-time database setup and verification
require_once 'config.php';

echo "<h2>Website Health Monitor - Database Setup</h2>\n";

try {
    $db = new Database();
    echo "<p style='color: green;'>✅ Database connection successful!</p>\n";
    
    // Check if we're using the clean database structure
    $tables = $db->fetchAll("SHOW TABLES");
    $tableNames = array_column($tables, 'Tables_in_' . DB_NAME);
    
    echo "<h3>Current Database Tables:</h3>\n";
    echo "<ul>\n";
    foreach ($tableNames as $table) {
        echo "<li>$table</li>\n";
    }
    echo "</ul>\n";
    
    // Check for required tables from the clean database structure
    $requiredTables = [
        'alert_definitions',
        'alert_contacts', 
        'monitored_urls',
        'health_reports',
        'alert_history',
        'config'
    ];
    
    $missingTables = array_diff($requiredTables, $tableNames);
    
    if (empty($missingTables)) {
        echo "<p style='color: green;'>✅ All required tables found! Database structure is correct.</p>\n";
        
        // Check if we have the dashboard views
        $views = $db->fetchAll("SHOW FULL TABLES WHERE Table_type = 'VIEW'");
        $viewNames = array_column($views, 'Tables_in_' . DB_NAME);
        
        echo "<h3>Available Views:</h3>\n";
        if (empty($viewNames)) {
            echo "<p style='color: orange;'>⚠️ No views found. You may need to run the complete database rebuild script.</p>\n";
        } else {
            echo "<ul>\n";
            foreach ($viewNames as $view) {
                echo "<li>$view</li>\n";
            }
            echo "</ul>\n";
        }
        
        // Test basic queries
        echo "<h3>Database Functionality Test:</h3>\n";
        
        // Test config table
        $configCount = $db->fetchOne("SELECT COUNT(*) as count FROM config");
        echo "<p>Config entries: " . $configCount['count'] . "</p>\n";
        
        // Test alert definitions
        $alertDefCount = $db->fetchOne("SELECT COUNT(*) as count FROM alert_definitions");
        echo "<p>Alert definitions: " . $alertDefCount['count'] . "</p>\n";
        
        // Test monitored URLs
        $urlCount = $db->fetchOne("SELECT COUNT(*) as count FROM monitored_urls");
        echo "<p>Monitored URLs: " . $urlCount['count'] . "</p>\n";
        
        // Test if dashboard_overview view exists and works
        try {
            $overview = $db->fetchOne("SELECT * FROM dashboard_overview");
            echo "<p style='color: green;'>✅ Dashboard overview view working</p>\n";
            echo "<p>Total sites: " . ($overview['total_sites'] ?? 0) . "</p>\n";
            echo "<p>Sites up: " . ($overview['sites_up'] ?? 0) . "</p>\n";
            echo "<p>Overall uptime: " . number_format($overview['overall_uptime_percent'] ?? 0, 1) . "%</p>\n";
        } catch (Exception $e) {
            echo "<p style='color: orange;'>⚠️ Dashboard overview view not found or not working</p>\n";
        }
        
        // Test if url_status_current view exists and works
        try {
            $statusCount = $db->fetchOne("SELECT COUNT(*) as count FROM url_status_current");
            echo "<p style='color: green;'>✅ URL status current view working (" . $statusCount['count'] . " records)</p>\n";
        } catch (Exception $e) {
            echo "<p style='color: orange;'>⚠️ URL status current view not found or not working</p>\n";
        }
        
    } else {
        echo "<h3 style='color: red;'>❌ Missing Required Tables:</h3>\n";
        echo "<ul>\n";
        foreach ($missingTables as $table) {
            echo "<li style='color: red;'>$table</li>\n";
        }
        echo "</ul>\n";
        echo "<p><strong>Action Required:</strong> Please run the complete database rebuild script (101.complete_database_rebuild.sql) to create the proper database structure.</p>\n";
    }
    
    // Check for sample data
    if (in_array('monitored_urls', $tableNames)) {
        $sampleUrls = $db->fetchAll("SELECT name, url, priority, last_status FROM monitored_urls LIMIT 5");
        if (!empty($sampleUrls)) {
            echo "<h3>Sample Monitored URLs:</h3>\n";
            echo "<table border='1' cellpadding='5' cellspacing='0'>\n";
            echo "<tr><th>Name</th><th>URL</th><th>Priority</th><th>Status</th></tr>\n";
            foreach ($sampleUrls as $url) {
                echo "<tr>\n";
                echo "<td>" . htmlspecialchars($url['name']) . "</td>\n";
                echo "<td>" . htmlspecialchars($url['url']) . "</td>\n";
                echo "<td>" . htmlspecialchars($url['priority']) . "</td>\n";
                echo "<td>" . htmlspecialchars($url['last_status'] ?: 'Unknown') . "</td>\n";
                echo "</tr>\n";
            }
            echo "</table>\n";
        } else {
            echo "<p style='color: orange;'>⚠️ No monitored URLs found. You may want to run the sample data script (102.Sample_date_insert.sql) or add URLs manually.</p>\n";
        }
    }
    
    echo "<h3>Next Steps:</h3>\n";
    echo "<ol>\n";
    echo "<li>If all tests passed, you can access the dashboard at: <a href='dashboard.php'>dashboard.php</a></li>\n";
    echo "<li>Default login credentials: admin / monitor123!</li>\n";
    echo "<li>Change the default password in config.php before production use</li>\n";
    echo "<li>Configure your alert definitions and contacts in the Management section</li>\n";
    echo "<li>Add your URLs to monitor</li>\n";
    echo "<li>Make sure your N8N workflow is running and pointing to this database</li>\n";
    echo "</ol>\n";
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Database connection failed: " . htmlspecialchars($e->getMessage()) . "</p>\n";
    echo "<p><strong>Check your database configuration in config.php:</strong></p>\n";
    echo "<ul>\n";
    echo "<li>DB_HOST: " . DB_HOST . "</li>\n";
    echo "<li>DB_NAME: " . DB_NAME . "</li>\n";
    echo "<li>DB_USER: " . DB_USER . "</li>\n";
    echo "<li>DB_PASS: [hidden]</li>\n";
    echo "</ul>\n";
}

echo "<hr>\n";
echo "<p><em>This setup script can be deleted after successful installation.</em></p>\n";
?>

<style>
body {
    font-family: Arial, sans-serif;
    max-width: 800px;
    margin: 20px auto;
    padding: 20px;
    line-height: 1.6;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin: 10px 0;
}

th {
    background-color: #f5f5f5;
    font-weight: bold;
}

td, th {
    text-align: left;
    padding: 8px;
    border: 1px solid #ddd;
}

tr:nth-child(even) {
    background-color: #f9f9f9;
}

h2 {
    color: #333;
    border-bottom: 2px solid #667eea;
    padding-bottom: 10px;
}

h3 {
    color: #555;
    margin-top: 25px;
}

a {
    color: #667eea;
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}
</style>