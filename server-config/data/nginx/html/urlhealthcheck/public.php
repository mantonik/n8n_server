<?php
// public.php - Public dashboard (no authentication required)
require_once 'config.php';

// Check if public dashboard is enabled
if (!PUBLIC_DASHBOARD_ENABLED) {
    header('HTTP/1.0 404 Not Found');
    exit('Public dashboard is disabled');
}

// Get public dashboard data (limited information)
try {
    // System overview
    $overview = $db->fetchOne("SELECT * FROM dashboard_overview");
    
    // Current URL status (limited info for public)
    $urls = $db->fetchAll("
        SELECT 
            name as site_name,
            priority,
            last_status as current_status,
            last_checked_at,
            CASE 
                WHEN last_status = 'up' THEN '✅ UP'
                WHEN last_status = 'down' THEN '❌ DOWN'
                WHEN last_status = 'error' THEN '⚠️ ERROR'
                WHEN last_status = 'timeout' THEN '⏰ TIMEOUT'
                ELSE '❓ UNKNOWN'
            END as status_display
        FROM monitored_urls
        WHERE is_active = TRUE
        ORDER BY 
            FIELD(priority, 'critical', 'high', 'normal', 'low'),
            CASE WHEN last_status = 'up' THEN 1 ELSE 0 END,
            name
    ");
    
    // Service groups by priority
    $priorityStats = $db->fetchAll("
        SELECT 
            priority,
            COUNT(*) as total_services,
            SUM(CASE WHEN last_status = 'up' THEN 1 ELSE 0 END) as operational_services,
            ROUND((SUM(CASE WHEN last_status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as availability_percent
        FROM monitored_urls
        WHERE is_active = TRUE
        GROUP BY priority
        ORDER BY FIELD(priority, 'critical', 'high', 'normal', 'low')
    ");
    
} catch (Exception $e) {
    error_log("Public dashboard data fetch error: " . $e->getMessage());
    $overview = ['total_sites' => 0, 'sites_up' => 0, 'overall_uptime_percent' => 0];
    $urls = [];
    $priorityStats = [];
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo APP_NAME; ?> - Status</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <meta http-equiv="refresh" content="<?php echo REFRESH_INTERVAL; ?>">
    <style>
        body {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            min-height: 100vh;
        }
        
        .status-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 3rem 0;
            text-align: center;
            position: relative;
            overflow: hidden;
        }
        
        .status-header::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grain" width="100" height="100" patternUnits="userSpaceOnUse"><circle cx="50" cy="50" r="1" fill="white" opacity="0.1"/></pattern></defs><rect width="100" height="100" fill="url(%23grain)"/></svg>');
            opacity: 0.1;
        }
        
        .status-header h1 {
            font-size: 3rem;
            font-weight: 700;
            margin-bottom: 1rem;
            position: relative;
            z-index: 1;
        }
        
        .overall-status {
            font-size: 1.3rem;
            margin-bottom: 2rem;
            position: relative;
            z-index: 1;
        }
        
        .status-metrics {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 2rem;
            max-width: 800px;
            margin: 0 auto;
            position: relative;
            z-index: 1;
        }
        
        .metric-item {
            text-align: center;
        }
        
        .metric-value {
            display: block;
            font-size: 2.5rem;
            font-weight: 700;
            line-height: 1;
        }
        
        .metric-label {
            display: block;
            font-size: 0.9rem;
            opacity: 0.9;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-top: 0.5rem;
        }
        
        .card {
            border: none;
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            backdrop-filter: blur(10px);
            background: rgba(255, 255, 255, 0.95);
            margin-bottom: 2rem;
        }
        
        .card-header {
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            border-bottom: 1px solid #dee2e6;
            border-radius: 20px 20px 0 0 !important;
            padding: 1.5rem 2rem;
        }
        
        .card-header h3 {
            margin: 0;
            font-weight: 600;
            color: #495057;
        }
        
        .service-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 1rem;
            padding: 2rem;
        }
        
        .service-item {
            display: flex;
            justify-content: between;
            align-items: center;
            padding: 1rem;
            background: white;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            transition: all 0.3s ease;
        }
        
        .service-item:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.1);
        }
        
        .service-name {
            font-weight: 600;
            color: #333;
            flex-grow: 1;
        }
        
        .service-status {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        
        .status-badge {
            padding: 0.5rem 1rem;
            border-radius: 25px;
            font-size: 0.8rem;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        
        .status-up { background: #d4edda; color: #155724; }
        .status-down { background: #f8d7da; color: #721c24; }
        .status-error { background: #fff3cd; color: #856404; }
        .status-timeout { background: #fff3cd; color: #856404; }
        .status-unknown { background: #e2e3e5; color: #383d41; }
        
        .priority-badge {
            padding: 0.3rem 0.8rem;
            border-radius: 15px;
            font-size: 0.7rem;
            font-weight: 600;
            text-transform: uppercase;
            margin-right: 1rem;
        }
        
        .priority-critical { background: #f8d7da; color: #721c24; }
        .priority-high { background: #fff3cd; color: #856404; }
        .priority-normal { background: #d1ecf1; color: #0c5460; }
        .priority-low { background: #e2e3e5; color: #383d41; }
        
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1.5rem;
            margin-bottom: 3rem;
        }
        
        .summary-card {
            background: white;
            padding: 2rem;
            border-radius: 20px;
            text-align: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .summary-priority {
            font-size: 0.9rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 1rem;
        }
        
        .summary-availability {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 0.5rem;
        }
        
        .summary-services {
            color: #6c757d;
            font-size: 0.9rem;
        }
        
        .footer {
            text-align: center;
            padding: 2rem;
            color: #6c757d;
            border-top: 1px solid #dee2e6;
            margin-top: 3rem;
        }
        
        .last-updated {
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(255, 255, 255, 0.9);
            padding: 0.5rem 1rem;
            border-radius: 20px;
            font-size: 0.8rem;
            color: #6c757d;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .login-link {
            position: fixed;
            top: 20px;
            left: 20px;
            background: rgba(255, 255, 255, 0.9);
            padding: 0.5rem 1rem;
            border-radius: 20px;
            text-decoration: none;
            color: #667eea;
            font-weight: 600;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
        }
        
        .login-link:hover {
            background: #667eea;
            color: white;
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <!-- Login Link -->
    <a href="login.php" class="login-link">
        <i class="fas fa-lock me-1"></i>
        Admin Login
    </a>
    
    <!-- Last Updated -->
    <div class="last-updated">
        <i class="fas fa-clock me-1"></i>
        Updated: <?php echo date('g:i:s A'); ?>
    </div>

    <!-- Status Header -->
    <div class="status-header">
        <div class="container">
            <h1>
                <i class="fas fa-shield-alt me-3"></i>
                System Status
            </h1>
            
            <?php
            $overallStatusText = 'All Systems Operational';
            $overallStatusIcon = 'fas fa-check-circle';
            $statusClass = 'text-success';
            
            if (($overview['critical_sites_down'] ?? 0) > 0) {
                $overallStatusText = 'Critical Issues Detected';
                $overallStatusIcon = 'fas fa-exclamation-triangle';
                $statusClass = 'text-danger';
            } elseif (($overview['sites_alerting'] ?? 0) > 0) {
                $overallStatusText = 'Some Issues Detected';
                $overallStatusIcon = 'fas fa-exclamation-circle';
                $statusClass = 'text-warning';
            }
            ?>
            
            <div class="overall-status">
                <i class="<?php echo $overallStatusIcon; ?> me-2"></i>
                <?php echo $overallStatusText; ?>
            </div>
            
            <div class="status-metrics">
                <div class="metric-item">
                    <span class="metric-value"><?php echo $overview['total_sites'] ?? 0; ?></span>
                    <span class="metric-label">Total Services</span>
                </div>
                <div class="metric-item">
                    <span class="metric-value"><?php echo $overview['sites_up'] ?? 0; ?></span>
                    <span class="metric-label">Operational</span>
                </div>
                <div class="metric-item">
                    <span class="metric-value"><?php echo number_format($overview['overall_uptime_percent'] ?? 0, 1); ?>%</span>
                    <span class="metric-label">Uptime</span>
                </div>
                <div class="metric-item">
                    <span class="metric-value"><?php echo ($overview['sites_down'] ?? 0) + ($overview['sites_error'] ?? 0) + ($overview['sites_timeout'] ?? 0); ?></span>
                    <span class="metric-label">Issues</span>
                </div>
            </div>
        </div>
    </div>

    <div class="container py-5">
        <!-- Priority Summary -->
        <?php if (!empty($priorityStats)): ?>
        <div class="summary-grid">
            <?php foreach ($priorityStats as $stat): ?>
                <div class="summary-card">
                    <div class="summary-priority priority-<?php echo $stat['priority']; ?>">
                        <?php echo strtoupper($stat['priority']); ?> Priority
                    </div>
                    <div class="summary-availability <?php echo $stat['availability_percent'] >= 99 ? 'text-success' : ($stat['availability_percent'] >= 95 ? 'text-warning' : 'text-danger'); ?>">
                        <?php echo number_format($stat['availability_percent'], 1); ?>%
                    </div>
                    <div class="summary-services">
                        <?php echo $stat['operational_services']; ?> of <?php echo $stat['total_services']; ?> services
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
        <?php endif; ?>

        <!-- Service Status -->
        <div class="card">
            <div class="card-header">
                <h3>
                    <i class="fas fa-list me-2"></i>
                    Service Status
                </h3>
            </div>
            <div class="service-grid">
                <?php if (empty($urls)): ?>
                    <div class="col-12 text-center py-5">
                        <i class="fas fa-inbox text-muted fa-3x mb-3"></i>
                        <p class="text-muted">No services are currently monitored</p>
                    </div>
                <?php else: ?>
                    <?php foreach ($urls as $url): ?>
                        <div class="service-item">
                            <div class="service-name">
                                <?php echo htmlspecialchars($url['site_name']); ?>
                            </div>
                            <div class="service-status">
                                <span class="priority-badge priority-<?php echo $url['priority']; ?>">
                                    <?php echo strtoupper($url['priority']); ?>
                                </span>
                                <span class="status-badge status-<?php echo $url['current_status']; ?>">
                                    <?php echo $url['status_display']; ?>
                                </span>
                            </div>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <!-- Footer -->
    <div class="footer">
        <div class="container">
            <p class="mb-2">
                <strong><?php echo APP_NAME; ?></strong> v<?php echo APP_VERSION; ?>
            </p>
            <p class="mb-0">
                Last updated: <?php echo formatDateTime(date('Y-m-d H:i:s')); ?> |
                Auto-refresh: <?php echo REFRESH_INTERVAL; ?> seconds
            </p>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Update page title for critical issues
        document.addEventListener('DOMContentLoaded', function() {
            const criticalIssues = <?php echo ($overview['critical_sites_down'] ?? 0); ?>;
            const totalIssues = <?php echo ($overview['sites_down'] ?? 0) + ($overview['sites_error'] ?? 0) + ($overview['sites_timeout'] ?? 0); ?>;
            
            if (criticalIssues > 0) {
                document.title = `🔴 Critical Issues - System Status`;
            } else if (totalIssues > 0) {
                document.title = `🟡 Some Issues - System Status`;
            } else {
                document.title = `✅ All Systems Operational - System Status`;
            }
        });
        
        // Auto-refresh countdown
        let refreshTime = <?php echo REFRESH_INTERVAL; ?>;
        
        function updateRefreshTimer() {
            const lastUpdatedEl = document.querySelector('.last-updated');
            if (lastUpdatedEl) {
                lastUpdatedEl.innerHTML = `<i class="fas fa-sync-alt me-1"></i>Refresh in: ${refreshTime}s`;
            }
            
            if (refreshTime > 0) {
                refreshTime--;
                setTimeout(updateRefreshTimer, 1000);
            }
        }
        
        updateRefreshTimer();
    </script>
</body>
</html>