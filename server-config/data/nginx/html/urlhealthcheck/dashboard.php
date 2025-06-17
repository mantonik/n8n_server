<?php
// dashboard.php - Main dashboard page
require_once 'config.php';
require_once 'auth.php';

// Require authentication
$auth->requireAuth();

// Get dashboard data
try {
    // System overview
    $overview = $db->fetchOne("SELECT * FROM dashboard_overview");
    
    // Current URL status
    $urls = $db->fetchAll("
        SELECT * FROM url_status_current 
        ORDER BY 
            is_active DESC,
            FIELD(priority, 'critical', 'high', 'normal', 'low'),
            CASE WHEN current_status = 'up' THEN 1 ELSE 0 END,
            current_failure_count DESC,
            site_name
        LIMIT 50
    ");
    
    // Recent alerts (last 24 hours)
    $recentAlerts = $db->fetchAll("
        SELECT ah.*, mu.name as site_name, mu.url, mu.priority
        FROM alert_history ah
        JOIN monitored_urls mu ON ah.url_id = mu.id
        WHERE ah.sent_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)
        ORDER BY ah.sent_at DESC
        LIMIT 10
    ");
    
    // Team performance
    $teams = $db->fetchAll("
        SELECT 
            COALESCE(team_name, 'Unassigned') as team_name,
            COUNT(*) as total_sites,
            SUM(CASE WHEN last_status = 'up' THEN 1 ELSE 0 END) as sites_up,
            SUM(CASE WHEN current_failure_count >= failure_threshold THEN 1 ELSE 0 END) as sites_alerting,
            ROUND((SUM(CASE WHEN last_status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 1) as uptime_percent
        FROM monitored_urls 
        WHERE is_active = TRUE
        GROUP BY team_name
        ORDER BY uptime_percent ASC
    ");
    
    // SSL certificates expiring soon
    $sslExpiring = $db->fetchAll("
        SELECT 
            name as site_name,
            url,
            priority,
            ssl_expires_at,
            DATEDIFF(ssl_expires_at, NOW()) as days_until_expiry
        FROM monitored_urls
        WHERE check_ssl_expiry = TRUE 
          AND ssl_expires_at IS NOT NULL
          AND DATEDIFF(ssl_expires_at, NOW()) <= 30
          AND is_active = TRUE
        ORDER BY days_until_expiry ASC
        LIMIT 10
    ");
    
} catch (Exception $e) {
    error_log("Dashboard data fetch error: " . $e->getMessage());
    $overview = ['total_sites' => 0, 'sites_up' => 0, 'sites_down' => 0, 'overall_uptime_percent' => 0];
    $urls = [];
    $recentAlerts = [];
    $teams = [];
    $sslExpiring = [];
}

$sessionInfo = $auth->getSessionInfo();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo APP_NAME; ?> - Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <meta http-equiv="refresh" content="<?php echo REFRESH_INTERVAL; ?>">
    <style>
        body {
            background-color: #f8f9fa;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        .navbar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .navbar-brand {
            font-weight: 700;
            font-size: 1.3rem;
        }
        
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            transition: transform 0.2s ease;
        }
        
        .card:hover {
            transform: translateY(-2px);
        }
        
        .card-header {
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            border-bottom: 1px solid #dee2e6;
            border-radius: 15px 15px 0 0 !important;
            font-weight: 600;
        }
        
        .metric-card {
            text-align: center;
            padding: 1.5rem;
        }
        
        .metric-value {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 0.5rem;
        }
        
        .metric-label {
            color: #6c757d;
            font-size: 0.9rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .status-badge {
            padding: 0.4rem 0.8rem;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
        }
        
        .priority-badge {
            padding: 0.3rem 0.6rem;
            border-radius: 15px;
            font-size: 0.7rem;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .table th {
            background-color: #f8f9fa;
            border-top: none;
            font-weight: 600;
            color: #495057;
        }
        
        .table-hover tbody tr:hover {
            background-color: rgba(0,123,255,0.05);
        }
        
        .progress {
            height: 8px;
            border-radius: 4px;
        }
        
        .auto-refresh {
            font-size: 0.8rem;
            color: #6c757d;
        }
        
        .system-status {
            padding: 1rem;
            border-radius: 10px;
            margin-bottom: 1rem;
        }
        
        .status-operational {
            background: linear-gradient(135deg, #28a745, #20c997);
            color: white;
        }
        
        .status-degraded {
            background: linear-gradient(135deg, #ffc107, #fd7e14);
            color: white;
        }
        
        .status-critical {
            background: linear-gradient(135deg, #dc3545, #e83e8c);
            color: white;
        }
        
        .quick-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }
        
        .team-card {
            padding: 1rem;
            border-left: 4px solid #dee2e6;
            background: white;
            border-radius: 0 10px 10px 0;
        }
        
        .uptime-good { border-left-color: #28a745; }
        .uptime-warning { border-left-color: #ffc107; }
        .uptime-critical { border-left-color: #dc3545; }
    </style>
</head>
<body>
    <!-- Navigation -->
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container-fluid">
            <a class="navbar-brand" href="dashboard.php">
                <i class="fas fa-shield-alt me-2"></i>
                <?php echo APP_NAME; ?>
            </a>
            
            <div class="navbar-nav ms-auto">
                <div class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown">
                        <i class="fas fa-user me-1"></i>
                        <?php echo htmlspecialchars($sessionInfo['username']); ?>
                    </a>
                    <ul class="dropdown-menu">
                        <li><a class="dropdown-item" href="manage.php"><i class="fas fa-cog me-2"></i>Management</a></li>
                        <li><a class="dropdown-item" href="reports.php"><i class="fas fa-chart-bar me-2"></i>Reports</a></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item" href="logout.php"><i class="fas fa-sign-out-alt me-2"></i>Logout</a></li>
                    </ul>
                </div>
            </div>
        </div>
    </nav>

    <div class="container-fluid py-4">
        <!-- System Status Header -->
        <?php
        $systemStatusClass = 'status-operational';
        $systemStatusText = 'All Systems Operational';
        $systemStatusIcon = 'fas fa-check-circle';
        
        if (($overview['critical_sites_down'] ?? 0) > 0) {
            $systemStatusClass = 'status-critical';
            $systemStatusText = 'Critical Issues Detected';
            $systemStatusIcon = 'fas fa-exclamation-triangle';
        } elseif (($overview['sites_alerting'] ?? 0) > 0) {
            $systemStatusClass = 'status-degraded';
            $systemStatusText = 'Some Issues Detected';
            $systemStatusIcon = 'fas fa-exclamation-circle';
        }
        ?>
        
        <div class="system-status <?php echo $systemStatusClass; ?>">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <h4 class="mb-1">
                        <i class="<?php echo $systemStatusIcon; ?> me-2"></i>
                        <?php echo $systemStatusText; ?>
                    </h4>
                    <p class="mb-0">
                        <?php echo ($overview['sites_up'] ?? 0); ?> of <?php echo ($overview['total_sites'] ?? 0); ?> services operational
                        (<?php echo number_format($overview['overall_uptime_percent'] ?? 0, 1); ?>% uptime)
                    </p>
                </div>
                <div class="text-end">
                    <div class="auto-refresh">
                        <i class="fas fa-sync-alt me-1"></i>
                        Auto-refresh: <?php echo REFRESH_INTERVAL; ?>s
                    </div>
                    <small>Last updated: <?php echo date('g:i:s A'); ?></small>
                </div>
            </div>
        </div>

        <!-- Quick Stats -->
        <div class="quick-stats">
            <div class="card metric-card">
                <div class="metric-value text-primary"><?php echo $overview['total_sites'] ?? 0; ?></div>
                <div class="metric-label">Total Sites</div>
            </div>
            
            <div class="card metric-card">
                <div class="metric-value text-success"><?php echo $overview['sites_up'] ?? 0; ?></div>
                <div class="metric-label">Sites Up</div>
            </div>
            
            <div class="card metric-card">
                <div class="metric-value text-danger"><?php echo ($overview['sites_down'] ?? 0) + ($overview['sites_error'] ?? 0) + ($overview['sites_timeout'] ?? 0); ?></div>
                <div class="metric-label">Sites Down</div>
            </div>
            
            <div class="card metric-card">
                <div class="metric-value text-warning"><?php echo $overview['sites_alerting'] ?? 0; ?></div>
                <div class="metric-label">Alerting</div>
            </div>
            
            <div class="card metric-card">
                <div class="metric-value text-info"><?php echo number_format($overview['overall_uptime_percent'] ?? 0, 1); ?>%</div>
                <div class="metric-label">Overall Uptime</div>
            </div>
        </div>

        <div class="row">
            <!-- Current Status -->
            <div class="col-lg-8">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">
                            <i class="fas fa-heartbeat me-2"></i>
                            Current Status
                        </h5>
                        <div>
                            <a href="manage.php" class="btn btn-sm btn-outline-primary">
                                <i class="fas fa-cog me-1"></i>Manage
                            </a>
                        </div>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover mb-0">
                                <thead>
                                    <tr>
                                        <th>Site</th>
                                        <th>Status</th>
                                        <th>Priority</th>
                                        <th>Response</th>
                                        <th>Last Check</th>
                                        <th>Health</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php if (empty($urls)): ?>
                                        <tr>
                                            <td colspan="6" class="text-center py-4">
                                                <i class="fas fa-inbox text-muted"></i>
                                                <p class="text-muted mt-2">No monitored URLs found</p>
                                            </td>
                                        </tr>
                                    <?php else: ?>
                                        <?php foreach ($urls as $url): ?>
                                            <tr>
                                                <td>
                                                    <div>
                                                        <strong><?php echo htmlspecialchars($url['site_name']); ?></strong>
                                                        <br>
                                                        <small class="text-muted"><?php echo htmlspecialchars($url['url']); ?></small>
                                                    </div>
                                                </td>
                                                <td>
                                                    <span class="status-badge bg-<?php echo getStatusClass($url['current_status']); ?>">
                                                        <?php echo getStatusIcon($url['current_status']); ?>
                                                        <?php echo strtoupper($url['current_status']); ?>
                                                    </span>
                                                </td>
                                                <td>
                                                    <span class="priority-badge bg-<?php echo getPriorityClass($url['priority']); ?>">
                                                        <?php echo strtoupper($url['priority']); ?>
                                                    </span>
                                                </td>
                                                <td>
                                                    <?php if ($url['last_response_time']): ?>
                                                        <span class="badge bg-light text-dark">
                                                            <?php echo number_format($url['last_response_time']); ?>ms
                                                        </span>
                                                    <?php else: ?>
                                                        <span class="text-muted">N/A</span>
                                                    <?php endif; ?>
                                                </td>
                                                <td>
                                                    <small><?php echo formatDateTime($url['last_checked_at']); ?></small>
                                                </td>
                                                <td>
                                                    <?php if (strpos($url['health_status'], 'ALERTING') !== false): ?>
                                                        <span class="badge bg-danger">
                                                            <i class="fas fa-exclamation-triangle me-1"></i>
                                                            Alert
                                                        </span>
                                                    <?php elseif (strpos($url['health_status'], 'FAILING') !== false): ?>
                                                        <span class="badge bg-warning">
                                                            <i class="fas fa-exclamation-circle me-1"></i>
                                                            Issues
                                                        </span>
                                                    <?php else: ?>
                                                        <span class="badge bg-success">
                                                            <i class="fas fa-check me-1"></i>
                                                            Healthy
                                                        </span>
                                                    <?php endif; ?>
                                                </td>
                                            </tr>
                                        <?php endforeach; ?>
                                    <?php endif; ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Sidebar -->
            <div class="col-lg-4">
                <!-- Team Performance -->
                <div class="card mb-4">
                    <div class="card-header">
                        <h6 class="mb-0">
                            <i class="fas fa-users me-2"></i>
                            Team Performance
                        </h6>
                    </div>
                    <div class="card-body">
                        <?php if (empty($teams)): ?>
                            <p class="text-muted text-center">No team data available</p>
                        <?php else: ?>
                            <?php foreach ($teams as $team): ?>
                                <?php
                                $uptimeClass = 'uptime-good';
                                if ($team['uptime_percent'] < 99.0) $uptimeClass = 'uptime-critical';
                                elseif ($team['uptime_percent'] < 99.5) $uptimeClass = 'uptime-warning';
                                ?>
                                <div class="team-card <?php echo $uptimeClass; ?> mb-3">
                                    <div class="d-flex justify-content-between align-items-center">
                                        <div>
                                            <strong><?php echo htmlspecialchars($team['team_name']); ?></strong>
                                            <br>
                                            <small class="text-muted">
                                                <?php echo $team['sites_up']; ?>/<?php echo $team['total_sites']; ?> sites up
                                            </small>
                                        </div>
                                        <div class="text-end">
                                            <div class="h5 mb-0"><?php echo number_format($team['uptime_percent'], 1); ?>%</div>
                                            <?php if ($team['sites_alerting'] > 0): ?>
                                                <small class="text-danger">
                                                    <i class="fas fa-exclamation-triangle"></i>
                                                    <?php echo $team['sites_alerting']; ?> alerting
                                                </small>
                                            <?php endif; ?>
                                        </div>
                                    </div>
                                </div>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </div>
                </div>

                <!-- SSL Certificates -->
                <?php if (!empty($sslExpiring)): ?>
                <div class="card mb-4">
                    <div class="card-header">
                        <h6 class="mb-0">
                            <i class="fas fa-certificate me-2"></i>
                            SSL Certificates Expiring
                        </h6>
                    </div>
                    <div class="card-body">
                        <?php foreach ($sslExpiring as $ssl): ?>
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <div>
                                    <small class="fw-bold"><?php echo htmlspecialchars($ssl['site_name']); ?></small>
                                    <br>
                                    <span class="priority-badge bg-<?php echo getPriorityClass($ssl['priority']); ?>">
                                        <?php echo strtoupper($ssl['priority']); ?>
                                    </span>
                                </div>
                                <div class="text-end">
                                    <?php
                                    $days = (int)$ssl['days_until_expiry'];
                                    $badgeClass = 'success';
                                    if ($days <= 0) $badgeClass = 'danger';
                                    elseif ($days <= 7) $badgeClass = 'danger';
                                    elseif ($days <= 30) $badgeClass = 'warning';
                                    ?>
                                    <span class="badge bg-<?php echo $badgeClass; ?>">
                                        <?php echo $days; ?> days
                                    </span>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    </div>
                </div>
                <?php endif; ?>

                <!-- Recent Alerts -->
                <div class="card">
                    <div class="card-header">
                        <h6 class="mb-0">
                            <i class="fas fa-bell me-2"></i>
                            Recent Alerts (24h)
                        </h6>
                    </div>
                    <div class="card-body">
                        <?php if (empty($recentAlerts)): ?>
                            <div class="text-center py-3">
                                <i class="fas fa-check-circle text-success fa-2x mb-2"></i>
                                <p class="text-muted mb-0">No recent alerts</p>
                            </div>
                        <?php else: ?>
                            <?php foreach ($recentAlerts as $alert): ?>
                                <div class="d-flex align-items-center mb-3">
                                    <div class="me-3">
                                        <?php
                                        $alertClass = 'warning';
                                        if ($alert['alert_type'] === 'down') $alertClass = 'danger';
                                        elseif ($alert['alert_type'] === 'up') $alertClass = 'success';
                                        ?>
                                        <i class="fas fa-circle text-<?php echo $alertClass; ?>"></i>
                                    </div>
                                    <div class="flex-grow-1">
                                        <div class="fw-bold"><?php echo htmlspecialchars($alert['site_name']); ?></div>
                                        <small class="text-muted">
                                            <?php echo strtoupper($alert['alert_type']); ?> - 
                                            <?php echo formatDateTime($alert['sent_at']); ?>
                                        </small>
                                    </div>
                                </div>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Auto-refresh countdown
        let refreshTime = <?php echo REFRESH_INTERVAL; ?>;
        
        function updateRefreshTimer() {
            const elements = document.querySelectorAll('.auto-refresh');
            elements.forEach(element => {
                element.innerHTML = `<i class="fas fa-sync-alt me-1"></i>Auto-refresh: ${refreshTime}s`;
            });
            
            if (refreshTime > 0) {
                refreshTime--;
                setTimeout(updateRefreshTimer, 1000);
            }
        }
        
        updateRefreshTimer();
        
        // Add visual feedback for critical issues
        document.addEventListener('DOMContentLoaded', function() {
            const criticalIssues = <?php echo ($overview['critical_sites_down'] ?? 0); ?>;
            if (criticalIssues > 0) {
                document.title = `(${criticalIssues}) Critical Issues - <?php echo APP_NAME; ?>`;
            }
        });
    </script>
</body>
</html>