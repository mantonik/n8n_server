<?php
// reports.php - Comprehensive reporting dashboard
require_once 'config.php';
require_once 'auth.php';

// Require authentication
$auth->requireAuth();

$activeTab = $_GET['tab'] ?? 'overview';
$dateRange = $_GET['range'] ?? '7';
$team = $_GET['team'] ?? '';
$priority = $_GET['priority'] ?? '';

// Get data based on filters
try {
    // Date range calculation
    $dateFilter = "DATE_SUB(NOW(), INTERVAL {$dateRange} DAY)";
    
    // Team filter
    $teamFilter = $team ? "AND mu.team_name = " . $db->getConnection()->quote($team) : '';
    
    // Priority filter  
    $priorityFilter = $priority ? "AND mu.priority = " . $db->getConnection()->quote($priority) : '';
    
    // Overview statistics
    $overview = $db->fetchOne("
        SELECT 
            COUNT(*) as total_sites,
            SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) as sites_up,
            SUM(CASE WHEN mu.last_status != 'up' THEN 1 ELSE 0 END) as sites_down,
            ROUND(AVG(CASE WHEN mu.last_status = 'up' THEN 100 ELSE 0 END), 2) as avg_uptime,
            SUM(CASE WHEN mu.current_failure_count >= mu.failure_threshold THEN 1 ELSE 0 END) as sites_alerting
        FROM monitored_urls mu 
        WHERE mu.is_active = TRUE {$teamFilter} {$priorityFilter}
    ");
    
    // SLA Report
    $slaReport = $db->fetchAll("
        SELECT 
            mu.name as site_name,
            mu.url,
            mu.priority,
            mu.team_name,
            COUNT(hr.id) as total_checks,
            SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) as successful_checks,
            ROUND((SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(hr.id)), 2) as uptime_percent,
            ROUND(AVG(CASE WHEN hr.status = 'up' THEN hr.response_time_ms END), 2) as avg_response_time,
            MAX(hr.checked_at) as last_check_time
        FROM monitored_urls mu
        LEFT JOIN health_reports hr ON mu.id = hr.url_id 
            AND hr.checked_at > {$dateFilter}
        WHERE mu.is_active = TRUE {$teamFilter} {$priorityFilter}
        GROUP BY mu.id, mu.name, mu.url, mu.priority, mu.team_name
        HAVING total_checks > 0
        ORDER BY uptime_percent ASC, mu.priority DESC
    ");
    
    // Performance trends
    $performanceTrends = $db->fetchAll("
        SELECT 
            DATE_FORMAT(hr.checked_at, '%Y-%m-%d %H:00:00') as hour_bucket,
            COUNT(*) as total_checks,
            ROUND(AVG(hr.response_time_ms), 2) as avg_response_time,
            SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) as successful_checks,
            ROUND((SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as success_rate
        FROM health_reports hr
        JOIN monitored_urls mu ON hr.url_id = mu.id
        WHERE hr.checked_at > {$dateFilter}
          AND mu.is_active = TRUE {$teamFilter} {$priorityFilter}
        GROUP BY hour_bucket
        ORDER BY hour_bucket DESC
        LIMIT 50
    ");
    
    // Alert volume analysis
    $alertVolume = $db->fetchAll("
        SELECT 
            DATE(ah.sent_at) as alert_date,
            COUNT(*) as total_alerts,
            COUNT(DISTINCT ah.url_id) as affected_sites,
            SUM(CASE WHEN ah.alert_type = 'down' THEN 1 ELSE 0 END) as down_alerts,
            SUM(CASE WHEN ah.alert_type = 'up' THEN 1 ELSE 0 END) as recovery_alerts,
            SUM(CASE WHEN ah.alert_type = 'error' THEN 1 ELSE 0 END) as error_alerts
        FROM alert_history ah
        JOIN monitored_urls mu ON ah.url_id = mu.id
        WHERE ah.sent_at > {$dateFilter}
          AND mu.is_active = TRUE {$teamFilter} {$priorityFilter}
        GROUP BY DATE(ah.sent_at)
        ORDER BY alert_date DESC
    ");
    
    // Team performance
    $teamPerformance = $db->fetchAll("
        SELECT 
            COALESCE(mu.team_name, 'Unassigned') as team_name,
            COUNT(*) as total_sites,
            SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) as sites_up,
            ROUND((SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as team_uptime,
            SUM(CASE WHEN mu.current_failure_count >= mu.failure_threshold THEN 1 ELSE 0 END) as sites_alerting,
            COUNT(CASE WHEN mu.priority = 'critical' THEN 1 END) as critical_sites,
            COUNT(CASE WHEN mu.priority = 'high' THEN 1 END) as high_sites
        FROM monitored_urls mu
        WHERE mu.is_active = TRUE {$priorityFilter}
        GROUP BY mu.team_name
        ORDER BY team_uptime ASC
    ");
    
    // Most problematic URLs
    $problematicUrls = $db->fetchAll("
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
        WHERE mu.is_active = TRUE {$teamFilter} {$priorityFilter}
        GROUP BY mu.id, mu.name, mu.url, mu.priority, mu.team_name, mu.current_failure_count, mu.failure_threshold
        HAVING total_alerts_{$dateRange}d > 0
        ORDER BY total_alerts_{$dateRange}d DESC, mu.priority DESC
        LIMIT 20
    ");
    
    // Get filter options
    $teams = $db->fetchAll("SELECT DISTINCT team_name FROM monitored_urls WHERE is_active = TRUE AND team_name IS NOT NULL ORDER BY team_name");
    
} catch (Exception $e) {
    error_log("Reports data fetch error: " . $e->getMessage());
    $overview = $slaReport = $performanceTrends = $alertVolume = $teamPerformance = $problematicUrls = [];
    $teams = [];
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo APP_NAME; ?> - Reports</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="style.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
                <a class="nav-link" href="dashboard.php">
                    <i class="fas fa-dashboard me-1"></i>Dashboard
                </a>
                <a class="nav-link" href="manage.php">
                    <i class="fas fa-cog me-1"></i>Management
                </a>
                <a class="nav-link" href="logout.php">
                    <i class="fas fa-sign-out-alt me-1"></i>Logout
                </a>
            </div>
        </div>
    </nav>

    <div class="container-fluid py-4">
        <!-- Header and Filters -->
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h2>
                <i class="fas fa-chart-bar me-2"></i>
                Reports & Analytics
            </h2>
            
            <!-- Filters -->
            <div class="d-flex gap-2">
                <select class="form-select form-select-sm" onchange="updateFilter('range', this.value)">
                    <option value="1" <?php echo $dateRange == '1' ? 'selected' : ''; ?>>Last 24 Hours</option>
                    <option value="7" <?php echo $dateRange == '7' ? 'selected' : ''; ?>>Last 7 Days</option>
                    <option value="30" <?php echo $dateRange == '30' ? 'selected' : ''; ?>>Last 30 Days</option>
                    <option value="90" <?php echo $dateRange == '90' ? 'selected' : ''; ?>>Last 90 Days</option>
                </select>
                
                <select class="form-select form-select-sm" onchange="updateFilter('team', this.value)">
                    <option value="">All Teams</option>
                    <?php foreach ($teams as $teamOption): ?>
                        <option value="<?php echo htmlspecialchars($teamOption['team_name']); ?>" 
                                <?php echo $team === $teamOption['team_name'] ? 'selected' : ''; ?>>
                            <?php echo htmlspecialchars($teamOption['team_name']); ?>
                        </option>
                    <?php endforeach; ?>
                </select>
                
                <select class="form-select form-select-sm" onchange="updateFilter('priority', this.value)">
                    <option value="">All Priorities</option>
                    <option value="critical" <?php echo $priority === 'critical' ? 'selected' : ''; ?>>Critical</option>
                    <option value="high" <?php echo $priority === 'high' ? 'selected' : ''; ?>>High</option>
                    <option value="normal" <?php echo $priority === 'normal' ? 'selected' : ''; ?>>Normal</option>
                    <option value="low" <?php echo $priority === 'low' ? 'selected' : ''; ?>>Low</option>
                </select>
            </div>
        </div>

        <!-- Overview Cards -->
        <div class="row mb-4">
            <div class="col-md-3">
                <div class="card metric-card">
                    <div class="card-body text-center">
                        <div class="metric-value text-primary"><?php echo $overview['total_sites'] ?? 0; ?></div>
                        <div class="metric-label">Total Sites</div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card metric-card">
                    <div class="card-body text-center">
                        <div class="metric-value text-success"><?php echo $overview['sites_up'] ?? 0; ?></div>
                        <div class="metric-label">Sites Up</div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card metric-card">
                    <div class="card-body text-center">
                        <div class="metric-value text-warning"><?php echo $overview['sites_alerting'] ?? 0; ?></div>
                        <div class="metric-label">Alerting</div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card metric-card">
                    <div class="card-body text-center">
                        <div class="metric-value text-info"><?php echo number_format($overview['avg_uptime'] ?? 0, 1); ?>%</div>
                        <div class="metric-label">Avg Uptime</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tab Navigation -->
        <ul class="nav nav-tabs mb-4">
            <li class="nav-item">
                <a class="nav-link <?php echo $activeTab === 'overview' ? 'active' : ''; ?>" href="?tab=overview&range=<?php echo $dateRange; ?>&team=<?php echo urlencode($team); ?>&priority=<?php echo urlencode($priority); ?>">
                    <i class="fas fa-chart-line me-2"></i>Overview
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?php echo $activeTab === 'sla' ? 'active' : ''; ?>" href="?tab=sla&range=<?php echo $dateRange; ?>&team=<?php echo urlencode($team); ?>&priority=<?php echo urlencode($priority); ?>">
                    <i class="fas fa-chart-bar me-2"></i>SLA Report
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?php echo $activeTab === 'performance' ? 'active' : ''; ?>" href="?tab=performance&range=<?php echo $dateRange; ?>&team=<?php echo urlencode($team); ?>&priority=<?php echo urlencode($priority); ?>">
                    <i class="fas fa-tachometer-alt me-2"></i>Performance
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?php echo $activeTab === 'alerts' ? 'active' : ''; ?>" href="?tab=alerts&range=<?php echo $dateRange; ?>&team=<?php echo urlencode($team); ?>&priority=<?php echo urlencode($priority); ?>">
                    <i class="fas fa-bell me-2"></i>Alerts
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?php echo $activeTab === 'teams' ? 'active' : ''; ?>" href="?tab=teams&range=<?php echo $dateRange; ?>&team=<?php echo urlencode($team); ?>&priority=<?php echo urlencode($priority); ?>">
                    <i class="fas fa-users me-2"></i>Teams
                </a>
            </li>
        </ul>

        <!-- Tab Content -->
        <?php if ($activeTab === 'overview'): ?>
            <div class="row">
                <!-- Performance Trend Chart -->
                <div class="col-lg-8">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0">
                                <i class="fas fa-chart-line me-2"></i>
                                Performance Trends (Last <?php echo $dateRange; ?> Days)
                            </h5>
                        </div>
                        <div class="card-body">
                            <canvas id="performanceChart" height="100"></canvas>
                        </div>
                    </div>
                </div>
                
                <!-- Most Problematic URLs -->
                <div class="col-lg-4">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0">
                                <i class="fas fa-exclamation-triangle me-2"></i>
                                Most Problematic URLs
                            </h5>
                        </div>
                        <div class="card-body">
                            <?php foreach (array_slice($problematicUrls, 0, 5) as $url): ?>
                                <div class="d-flex justify-content-between align-items-center mb-3">
                                    <div>
                                        <div class="fw-bold"><?php echo htmlspecialchars($url['site_name']); ?></div>
                                        <small class="text-muted"><?php echo htmlspecialchars($url['team_name'] ?: 'No Team'); ?></small>
                                    </div>
                                    <div class="text-end">
                                        <span class="badge bg-danger"><?php echo $url["total_alerts_{$dateRange}d"]; ?> alerts</span>
                                        <br>
                                        <span class="priority-badge bg-<?php echo getPriorityClass($url['priority']); ?>">
                                            <?php echo strtoupper($url['priority']); ?>
                                        </span>
                                    </div>
                                </div>
                            <?php endforeach; ?>
                        </div>
                    </div>
                </div>
            </div>
        <?php endif; ?>

        <?php if ($activeTab === 'sla'): ?>
            <div class="card">
                <div class="card-header">
                    <h5 class="mb-0">
                        <i class="fas fa-chart-bar me-2"></i>
                        SLA Report - Last <?php echo $dateRange; ?> Days
                    </h5>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Site Name</th>
                                    <th>Team</th>
                                    <th>Priority</th>
                                    <th>Uptime %</th>
                                    <th>Checks</th>
                                    <th>Avg Response</th>
                                    <th>Last Check</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($slaReport as $site): ?>
                                    <tr>
                                        <td>
                                            <strong><?php echo htmlspecialchars($site['site_name']); ?></strong>
                                            <br>
                                            <small class="text-muted"><?php echo htmlspecialchars($site['url']); ?></small>
                                        </td>
                                        <td><?php echo htmlspecialchars($site['team_name'] ?: 'Unassigned'); ?></td>
                                        <td>
                                            <span class="priority-badge bg-<?php echo getPriorityClass($site['priority']); ?>">
                                                <?php echo strtoupper($site['priority']); ?>
                                            </span>
                                        </td>
                                        <td>
                                            <?php 
                                            $uptime = $site['uptime_percent'];
                                            $class = $uptime >= 99.5 ? 'success' : ($uptime >= 99 ? 'warning' : 'danger');
                                            ?>
                                            <span class="badge bg-<?php echo $class; ?>">
                                                <?php echo number_format($uptime, 2); ?>%
                                            </span>
                                        </td>
                                        <td>
                                            <?php echo $site['successful_checks']; ?> / <?php echo $site['total_checks']; ?>
                                        </td>
                                        <td>
                                            <?php if ($site['avg_response_time']): ?>
                                                <?php echo number_format($site['avg_response_time']); ?>ms
                                            <?php else: ?>
                                                <span class="text-muted">N/A</span>
                                            <?php endif; ?>
                                        </td>
                                        <td>
                                            <small><?php echo formatDateTime($site['last_check_time']); ?></small>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        <?php endif; ?>

        <?php if ($activeTab === 'performance'): ?>
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0">
                                <i class="fas fa-tachometer-alt me-2"></i>
                                Performance Analysis - Last <?php echo $dateRange; ?> Days
                            </h5>
                        </div>
                        <div class="card-body">
                            <canvas id="responseTimeChart" height="80"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        <?php endif; ?>

        <?php if ($activeTab === 'alerts'): ?>
            <div class="row">
                <div class="col-lg-8">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0">
                                <i class="fas fa-chart-area me-2"></i>
                                Alert Volume Trends
                            </h5>
                        </div>
                        <div class="card-body">
                            <canvas id="alertChart" height="100"></canvas>
                        </div>
                    </div>
                </div>
                <div class="col-lg-4">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0">
                                <i class="fas fa-list me-2"></i>
                                Alert Summary
                            </h5>
                        </div>
                        <div class="card-body">
                            <?php
                            $totalAlerts = array_sum(array_column($alertVolume, 'total_alerts'));
                            $totalDownAlerts = array_sum(array_column($alertVolume, 'down_alerts'));
                            $totalRecoveryAlerts = array_sum(array_column($alertVolume, 'recovery_alerts'));
                            $totalErrorAlerts = array_sum(array_column($alertVolume, 'error_alerts'));
                            ?>
                            <div class="d-flex justify-content-between mb-2">
                                <span>Total Alerts:</span>
                                <strong><?php echo $totalAlerts; ?></strong>
                            </div>
                            <div class="d-flex justify-content-between mb-2">
                                <span>Down Alerts:</span>
                                <span class="text-danger"><?php echo $totalDownAlerts; ?></span>
                            </div>
                            <div class="d-flex justify-content-between mb-2">
                                <span>Recovery Alerts:</span>
                                <span class="text-success"><?php echo $totalRecoveryAlerts; ?></span>
                            </div>
                            <div class="d-flex justify-content-between mb-2">
                                <span>Error Alerts:</span>
                                <span class="text-warning"><?php echo $totalErrorAlerts; ?></span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        <?php endif; ?>

        <?php if ($activeTab === 'teams'): ?>
            <div class="card">
                <div class="card-header">
                    <h5 class="mb-0">
                        <i class="fas fa-users me-2"></i>
                        Team Performance Overview
                    </h5>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Team</th>
                                    <th>Total Sites</th>
                                    <th>Sites Up</th>
                                    <th>Team Uptime</th>
                                    <th>Alerting</th>
                                    <th>Critical Sites</th>
                                    <th>High Priority</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($teamPerformance as $team): ?>
                                    <tr>
                                        <td>
                                            <strong><?php echo htmlspecialchars($team['team_name']); ?></strong>
                                        </td>
                                        <td><?php echo $team['total_sites']; ?></td>
                                        <td>
                                            <span class="text-success"><?php echo $team['sites_up']; ?></span>
                                        </td>
                                        <td>
                                            <?php 
                                            $uptime = $team['team_uptime'];
                                            $class = $uptime >= 99.5 ? 'success' : ($uptime >= 99 ? 'warning' : 'danger');
                                            ?>
                                            <span class="badge bg-<?php echo $class; ?>">
                                                <?php echo number_format($uptime, 1); ?>%
                                            </span>
                                        </td>
                                        <td>
                                            <?php if ($team['sites_alerting'] > 0): ?>
                                                <span class="badge bg-danger"><?php echo $team['sites_alerting']; ?></span>
                                            <?php else: ?>
                                                <span class="text-muted">0</span>
                                            <?php endif; ?>
                                        </td>
                                        <td><?php echo $team['critical_sites']; ?></td>
                                        <td><?php echo $team['high_sites']; ?></td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        <?php endif; ?>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function updateFilter(type, value) {
            const url = new URL(window.location);
            url.searchParams.set(type, value);
            window.location = url;
        }

        // Chart configurations
        <?php if ($activeTab === 'overview' || $activeTab === 'performance'): ?>
        // Performance Chart
        const performanceData = <?php echo json_encode(array_reverse($performanceTrends)); ?>;
        const performanceCtx = document.getElementById('performanceChart');
        if (performanceCtx) {
            new Chart(performanceCtx, {
                type: 'line',
                data: {
                    labels: performanceData.map(d => new Date(d.hour_bucket).toLocaleDateString() + ' ' + new Date(d.hour_bucket).getHours() + ':00'),
                    datasets: [{
                        label: 'Avg Response Time (ms)',
                        data: performanceData.map(d => d.avg_response_time),
                        borderColor: 'rgb(102, 126, 234)',
                        backgroundColor: 'rgba(102, 126, 234, 0.1)',
                        tension: 0.1,
                        yAxisID: 'y'
                    }, {
                        label: 'Success Rate (%)',
                        data: performanceData.map(d => d.success_rate),
                        borderColor: 'rgb(40, 167, 69)',
                        backgroundColor: 'rgba(40, 167, 69, 0.1)',
                        tension: 0.1,
                        yAxisID: 'y1'
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        y: {
                            type: 'linear',
                            display: true,
                            position: 'left',
                            title: { display: true, text: 'Response Time (ms)' }
                        },
                        y1: {
                            type: 'linear',
                            display: true,
                            position: 'right',
                            title: { display: true, text: 'Success Rate (%)' },
                            grid: { drawOnChartArea: false }
                        }
                    }
                }
            });
        }
        <?php endif; ?>

        <?php if ($activeTab === 'alerts'): ?>
        // Alert Chart
        const alertData = <?php echo json_encode(array_reverse($alertVolume)); ?>;
        const alertCtx = document.getElementById('alertChart');
        if (alertCtx) {
            new Chart(alertCtx, {
                type: 'bar',
                data: {
                    labels: alertData.map(d => new Date(d.alert_date).toLocaleDateString()),
                    datasets: [{
                        label: 'Down Alerts',
                        data: alertData.map(d => d.down_alerts),
                        backgroundColor: 'rgba(220, 53, 69, 0.8)'
                    }, {
                        label: 'Error Alerts',
                        data: alertData.map(d => d.error_alerts),
                        backgroundColor: 'rgba(255, 193, 7, 0.8)'
                    }, {
                        label: 'Recovery Alerts',
                        data: alertData.map(d => d.recovery_alerts),
                        backgroundColor: 'rgba(40, 167, 69, 0.8)'
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        x: { stacked: true },
                        y: { stacked: true, title: { display: true, text: 'Number of Alerts' } }
                    }
                }
            });
        }
        <?php endif; ?>
    </script>
</body>
</html>