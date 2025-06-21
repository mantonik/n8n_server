<?php
// debug_reports.php - Temporary debug page to diagnose the issue
require_once 'config.php';
require_once 'auth.php';

$auth->requireAuth();

echo "<h2>Debug: Most Problematic URLs Issue</h2>";

$dateRange = $_GET['range'] ?? '7';
$dateFilter = "DATE_SUB(NOW(), INTERVAL {$dateRange} DAY)";

try {
    // 1. Check all URLs and their current status
    echo "<h3>1. All Monitored URLs Status</h3>";
    $allUrls = $db->fetchAll("
        SELECT 
            id,
            name,
            url,
            last_status,
            current_failure_count,
            failure_threshold,
            last_checked_at,
            is_active,
            priority,
            team_name
        FROM monitored_urls 
        ORDER BY current_failure_count DESC, last_status
    ");
    
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Name</th><th>Status</th><th>Failures</th><th>Threshold</th><th>Priority</th><th>Active</th><th>Last Check</th></tr>";
    foreach ($allUrls as $url) {
        $rowColor = '';
        if ($url['last_status'] === 'down' || $url['last_status'] === 'error') {
            $rowColor = 'background-color: #ffcccc;';
        }
        if ($url['current_failure_count'] > 0) {
            $rowColor = 'background-color: #fff3cd;';
        }
        
        echo "<tr style='$rowColor'>";
        echo "<td>" . $url['id'] . "</td>";
        echo "<td>" . htmlspecialchars($url['name']) . "</td>";
        echo "<td><strong>" . strtoupper($url['last_status'] ?: 'NULL') . "</strong></td>";
        echo "<td><strong>" . $url['current_failure_count'] . "</strong></td>";
        echo "<td>" . $url['failure_threshold'] . "</td>";
        echo "<td>" . $url['priority'] . "</td>";
        echo "<td>" . ($url['is_active'] ? 'YES' : 'NO') . "</td>";
        echo "<td>" . ($url['last_checked_at'] ?: 'Never') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // 2. Check alert history
    echo "<h3>2. Recent Alert History (Last {$dateRange} days)</h3>";
    $alerts = $db->fetchAll("
        SELECT 
            ah.url_id,
            mu.name,
            ah.alert_type,
            ah.sent_at,
            ah.success
        FROM alert_history ah
        JOIN monitored_urls mu ON ah.url_id = mu.id
        WHERE ah.sent_at > {$dateFilter}
        ORDER BY ah.sent_at DESC
        LIMIT 20
    ");
    
    if (empty($alerts)) {
        echo "<p style='color: red;'><strong>NO ALERTS FOUND in the last {$dateRange} days!</strong></p>";
        echo "<p>This is why 'Most Problematic URLs' is empty - it only shows URLs with recent alerts.</p>";
    } else {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>URL ID</th><th>Site Name</th><th>Alert Type</th><th>Sent At</th><th>Success</th></tr>";
        foreach ($alerts as $alert) {
            echo "<tr>";
            echo "<td>" . $alert['url_id'] . "</td>";
            echo "<td>" . htmlspecialchars($alert['name']) . "</td>";
            echo "<td>" . $alert['alert_type'] . "</td>";
            echo "<td>" . $alert['sent_at'] . "</td>";
            echo "<td>" . ($alert['success'] ? 'YES' : 'NO') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
    // 3. Test the current problematic URLs query
    echo "<h3>3. Current 'Most Problematic URLs' Query Result</h3>";
    $currentQuery = $db->fetchAll("
        SELECT 
            mu.name as site_name,
            mu.url,
            mu.priority,
            mu.team_name,
            COUNT(ah.id) as total_alerts_{$dateRange}d,
            SUM(CASE WHEN ah.alert_type = 'down' THEN 1 ELSE 0 END) as down_alerts,
            SUM(CASE WHEN ah.alert_type = 'error' THEN 1 ELSE 0 END) as error_alerts,
            MAX(ah.sent_at) as last_alert_time,
            mu.current_failure_count,
            mu.failure_threshold
        FROM monitored_urls mu
        LEFT JOIN alert_history ah ON mu.id = ah.url_id 
            AND ah.sent_at > {$dateFilter}
        WHERE mu.is_active = TRUE
        GROUP BY mu.id, mu.name, mu.url, mu.priority, mu.team_name, mu.current_failure_count, mu.failure_threshold
        HAVING total_alerts_{$dateRange}d > 0
        ORDER BY total_alerts_{$dateRange}d DESC, mu.priority DESC
        LIMIT 20
    ");
    
    if (empty($currentQuery)) {
        echo "<p style='color: red;'><strong>CURRENT QUERY RETURNS EMPTY!</strong></p>";
        echo "<p>Reason: The HAVING clause requires total_alerts_{$dateRange}d > 0</p>";
    } else {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>Site Name</th><th>Priority</th><th>Alerts</th><th>Current Failures</th></tr>";
        foreach ($currentQuery as $result) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($result['site_name']) . "</td>";
            echo "<td>" . $result['priority'] . "</td>";
            echo "<td>" . $result["total_alerts_{$dateRange}d"] . "</td>";
            echo "<td>" . $result['current_failure_count'] . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
    // 4. Test the improved query
    echo "<h3>4. IMPROVED Query Result (Shows current failures even without alerts)</h3>";
    $improvedQuery = $db->fetchAll("
        SELECT 
            mu.name as site_name,
            mu.url,
            mu.priority,
            mu.team_name,
            mu.current_failure_count,
            mu.failure_threshold,
            mu.last_status,
            mu.last_checked_at,
            COALESCE(alert_counts.total_alerts_{$dateRange}d, 0) as total_alerts_{$dateRange}d,
            COALESCE(alert_counts.down_alerts, 0) as down_alerts,
            COALESCE(alert_counts.error_alerts, 0) as error_alerts,
            alert_counts.last_alert_time,
            (
                CASE 
                    WHEN mu.last_status IN ('down', 'error', 'timeout') THEN 50
                    ELSE 0 
                END +
                (mu.current_failure_count * 10) +
                COALESCE(alert_counts.total_alerts_{$dateRange}d, 0)
            ) as problem_score
        FROM monitored_urls mu
        LEFT JOIN (
            SELECT 
                ah.url_id,
                COUNT(ah.id) as total_alerts_{$dateRange}d,
                SUM(CASE WHEN ah.alert_type = 'down' THEN 1 ELSE 0 END) as down_alerts,
                SUM(CASE WHEN ah.alert_type = 'error' THEN 1 ELSE 0 END) as error_alerts,
                MAX(ah.sent_at) as last_alert_time
            FROM alert_history ah
            WHERE ah.sent_at > {$dateFilter}
            GROUP BY ah.url_id
        ) alert_counts ON mu.id = alert_counts.url_id
        WHERE mu.is_active = TRUE
          AND (
              mu.last_status IN ('down', 'error', 'timeout') OR
              mu.current_failure_count > 0 OR
              alert_counts.total_alerts_{$dateRange}d > 0
          )
        ORDER BY problem_score DESC, mu.priority DESC, mu.current_failure_count DESC
        LIMIT 20
    ");
    
    if (empty($improvedQuery)) {
        echo "<p style='color: red;'><strong>EVEN IMPROVED QUERY RETURNS EMPTY!</strong></p>";
        echo "<p>This means:</p>";
        echo "<ul>";
        echo "<li>No URLs have last_status = 'down', 'error', or 'timeout'</li>";
        echo "<li>No URLs have current_failure_count > 0</li>";
        echo "<li>No URLs have recent alerts</li>";
        echo "</ul>";
    } else {
        echo "<p style='color: green;'><strong>IMPROVED QUERY WORKS!</strong></p>";
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>Site Name</th><th>Status</th><th>Current Failures</th><th>Recent Alerts</th><th>Problem Score</th></tr>";
        foreach ($improvedQuery as $result) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($result['site_name']) . "</td>";
            echo "<td><strong>" . strtoupper($result['last_status']) . "</strong></td>";
            echo "<td>" . $result['current_failure_count'] . "/" . $result['failure_threshold'] . "</td>";
            echo "<td>" . $result["total_alerts_{$dateRange}d"] . "</td>";
            echo "<td>" . $result['problem_score'] . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
    // 5. Check if N8N workflow is updating the database
    echo "<h3>5. Recent Health Reports (Is N8N updating the database?)</h3>";
    $recentReports = $db->fetchAll("
        SELECT 
            hr.url_id,
            mu.name,
            hr.status,
            hr.checked_at,
            hr.response_time_ms,
            hr.error_message
        FROM health_reports hr
        JOIN monitored_urls mu ON hr.url_id = mu.id
        ORDER BY hr.checked_at DESC
        LIMIT 10
    ");
    
    if (empty($recentReports)) {
        echo "<p style='color: red;'><strong>NO RECENT HEALTH REPORTS!</strong></p>";
        echo "<p>Your N8N workflow may not be running or not writing to the database.</p>";
    } else {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>Site Name</th><th>Status</th><th>Checked At</th><th>Response Time</th><th>Error</th></tr>";
        foreach ($recentReports as $report) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($report['name']) . "</td>";
            echo "<td>" . strtoupper($report['status']) . "</td>";
            echo "<td>" . $report['checked_at'] . "</td>";
            echo "<td>" . ($report['response_time_ms'] ?: 'N/A') . "</td>";
            echo "<td>" . htmlspecialchars($report['error_message'] ?: '') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>Error: " . htmlspecialchars($e->getMessage()) . "</p>";
}

echo "<hr>";
echo "<h3>Summary & Next Steps:</h3>";
echo "<ol>";
echo "<li>Review the tables above to see what data exists</li>";
echo "<li>If 'Recent Health Reports' is empty, check your N8N workflow</li>";
echo "<li>If URLs show as DOWN but 'Recent Alert History' is empty, check your alert configuration</li>";
echo "<li>Use the improved query in reports.php to show currently failing URLs</li>";
echo "</ol>";

echo "<p><a href='reports.php'>← Back to Reports</a></p>";
?>

<style>
body { font-family: Arial, sans-serif; margin: 20px; }
table { border-collapse: collapse; margin: 10px 0; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #f2f2f2; }
h3 { color: #333; margin-top: 30px; }
</style>