<?php
// manage.php - Clean PHP-only management page
require_once 'config.php';
require_once 'auth.php';

// Require authentication
$auth->requireAuth();

$message = '';
$error = '';
$activeTab = $_GET['tab'] ?? 'urls';

// Get filter and search parameters
$search = $_GET['search'] ?? '';
$teamFilter = $_GET['team'] ?? '';
$priorityFilter = $_GET['priority'] ?? '';
$statusFilter = $_GET['status'] ?? '';
$tagFilter = $_GET['tag'] ?? '';
$pageSize = $_GET['page_size'] ?? 20;
$page = $_GET['page'] ?? 1;

// Check permissions
$canModify = $auth->canModify();
$permissions = $auth->getUserPermissions();

// Handle form submissions (admin only)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $canModify) {
    if (!validateCSRFToken($_POST['csrf_token'] ?? '')) {
        $error = 'Invalid security token. Please try again.';
    } else {
        try {
            switch ($_POST['action']) {
                case 'add_url':
                    $tags = !empty($_POST['tags']) ? trim($_POST['tags']) : null;
                    
                    $sql = "INSERT INTO monitored_urls (url, name, description, priority, team_name, tags, alert_definition_id, 
                            check_interval_minutes, timeout_seconds, failure_threshold, expected_response, 
                            response_time_warning_ms, response_time_critical_ms, check_ssl_expiry, ssl_days_warning) 
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                    $db->query($sql, [
                        $_POST['url'], $_POST['name'], $_POST['description'], $_POST['priority'],
                        $_POST['team_name'], $tags, $_POST['alert_definition_id'] ?: null,
                        $_POST['check_interval_minutes'], $_POST['timeout_seconds'], $_POST['failure_threshold'],
                        $_POST['expected_response'], $_POST['response_time_warning_ms'], $_POST['response_time_critical_ms'],
                        isset($_POST['check_ssl_expiry']) ? 1 : 0, $_POST['ssl_days_warning']
                    ]);
                    $message = 'URL added successfully!';
                    break;
                    
                case 'update_url':
                    $tags = !empty($_POST['tags']) ? trim($_POST['tags']) : null;
                    
                    $sql = "UPDATE monitored_urls SET url=?, name=?, description=?, priority=?, team_name=?, tags=?,
                            alert_definition_id=?, check_interval_minutes=?, timeout_seconds=?, failure_threshold=?, 
                            expected_response=?, response_time_warning_ms=?, response_time_critical_ms=?, 
                            check_ssl_expiry=?, ssl_days_warning=?, is_active=?, updated_at=NOW() WHERE id=?";
                    $db->query($sql, [
                        $_POST['url'], $_POST['name'], $_POST['description'], $_POST['priority'],
                        $_POST['team_name'], $tags, $_POST['alert_definition_id'] ?: null,
                        $_POST['check_interval_minutes'], $_POST['timeout_seconds'], $_POST['failure_threshold'],
                        $_POST['expected_response'], $_POST['response_time_warning_ms'], $_POST['response_time_critical_ms'],
                        isset($_POST['check_ssl_expiry']) ? 1 : 0, $_POST['ssl_days_warning'],
                        isset($_POST['is_active']) ? 1 : 0, $_POST['url_id']
                    ]);
                    $message = 'URL updated successfully!';
                    break;
                    
                case 'delete_url':
                    $db->query("DELETE FROM monitored_urls WHERE id = ?", [$_POST['url_id']]);
                    $message = 'URL deleted successfully!';
                    break;
                    
                case 'bulk_action':
                    $urlIds = $_POST['selected_urls'] ?? [];
                    $bulkAction = $_POST['bulk_action'];
                    
                    if (!empty($urlIds)) {
                        $placeholders = str_repeat('?,', count($urlIds) - 1) . '?';
                        
                        switch ($bulkAction) {
                            case 'activate':
                                $db->query("UPDATE monitored_urls SET is_active = 1 WHERE id IN ($placeholders)", $urlIds);
                                $message = count($urlIds) . ' URLs activated successfully!';
                                break;
                            case 'deactivate':
                                $db->query("UPDATE monitored_urls SET is_active = 0 WHERE id IN ($placeholders)", $urlIds);
                                $message = count($urlIds) . ' URLs deactivated successfully!';
                                break;
                            case 'delete':
                                $db->query("DELETE FROM monitored_urls WHERE id IN ($placeholders)", $urlIds);
                                $message = count($urlIds) . ' URLs deleted successfully!';
                                break;
                        }
                    }
                    break;
                    
                case 'add_alert_definition':
                    $sql = "INSERT INTO alert_definitions (alert_name, description, cooldown_minutes, 
                            escalation_enabled, escalation_delay_minutes, business_hours_only, timezone, 
                            business_start_hour, business_end_hour) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
                    $db->query($sql, [
                        $_POST['alert_name'], $_POST['description'], $_POST['cooldown_minutes'],
                        isset($_POST['escalation_enabled']) ? 1 : 0, $_POST['escalation_delay_minutes'],
                        isset($_POST['business_hours_only']) ? 1 : 0, $_POST['timezone'],
                        $_POST['business_start_hour'], $_POST['business_end_hour']
                    ]);
                    $message = 'Alert definition added successfully!';
                    break;
                    
                case 'add_alert_contact':
                    $sql = "INSERT INTO alert_contacts (alert_definition_id, contact_name, contact_email, 
                            contact_phone, notification_type, priority_order) VALUES (?, ?, ?, ?, ?, ?)";
                    $db->query($sql, [
                        $_POST['alert_definition_id'], $_POST['contact_name'], $_POST['contact_email'],
                        $_POST['contact_phone'], $_POST['notification_type'], $_POST['priority_order']
                    ]);
                    $message = 'Alert contact added successfully!';
                    break;
                    
                case 'update_config':
                    foreach ($_POST['config'] as $key => $value) {
                        $sql = "UPDATE config SET config_value = ?, updated_at = NOW() WHERE config_key = ?";
                        $db->query($sql, [$value, $key]);
                    }
                    $message = 'Configuration updated successfully!';
                    break;
            }
        } catch (Exception $e) {
            $error = 'Error: ' . $e->getMessage();
        }
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST' && !$canModify) {
    $error = 'Access denied. You do not have permission to modify the system.';
}

// Build search and filter conditions
$whereConditions = ['1=1'];
$queryParams = [];

if (!empty($search)) {
    $whereConditions[] = "(mu.name LIKE ? OR mu.url LIKE ? OR mu.description LIKE ?)";
    $searchTerm = "%$search%";
    $queryParams = array_merge($queryParams, [$searchTerm, $searchTerm, $searchTerm]);
}

if (!empty($teamFilter)) {
    $whereConditions[] = "mu.team_name = ?";
    $queryParams[] = $teamFilter;
}

if (!empty($priorityFilter)) {
    $whereConditions[] = "mu.priority = ?";
    $queryParams[] = $priorityFilter;
}

if (!empty($statusFilter)) {
    $whereConditions[] = "mu.last_status = ?";
    $queryParams[] = $statusFilter;
}

if (!empty($tagFilter)) {
    $whereConditions[] = "mu.tags LIKE ?";
    $queryParams[] = "%$tagFilter%";
}

$whereClause = implode(' AND ', $whereConditions);

// Get data for display with pagination
try {
    // Count total results
    $totalCountSql = "SELECT COUNT(*) as total FROM monitored_urls mu WHERE $whereClause";
    $totalResult = $db->fetchOne($totalCountSql, $queryParams);
    $totalUrls = $totalResult['total'];
    
    // Calculate pagination
    $offset = ($page - 1) * $pageSize;
    $totalPages = ceil($totalUrls / $pageSize);
    
    // Get URLs with pagination
    $urls = $db->fetchAll("
        SELECT mu.*, ad.alert_name 
        FROM monitored_urls mu
        LEFT JOIN alert_definitions ad ON mu.alert_definition_id = ad.id
        WHERE $whereClause
        ORDER BY mu.priority, mu.name
        LIMIT $pageSize OFFSET $offset
    ", $queryParams);
    
    $alertDefinitions = $db->fetchAll("SELECT * FROM alert_definitions WHERE is_active = TRUE ORDER BY alert_name");
    $alertContacts = $db->fetchAll("
        SELECT ac.*, ad.alert_name 
        FROM alert_contacts ac 
        JOIN alert_definitions ad ON ac.alert_definition_id = ad.id 
        ORDER BY ad.alert_name, ac.priority_order
    ");
    $config = $db->fetchAll("SELECT * FROM config ORDER BY category, config_key");
    
    // Get filter options
    $teams = $db->fetchAll("SELECT DISTINCT team_name FROM monitored_urls WHERE team_name IS NOT NULL ORDER BY team_name");
    $tags = $db->fetchAll("
        SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tags, ',', numbers.n), ',', -1)) as tag
        FROM monitored_urls
        CROSS JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) numbers
        WHERE tags IS NOT NULL AND tags != ''
          AND CHAR_LENGTH(tags) - CHAR_LENGTH(REPLACE(tags, ',', '')) >= numbers.n - 1
        ORDER BY tag
    ");
    
} catch (Exception $e) {
    $error = 'Error loading data: ' . $e->getMessage();
    $urls = $alertDefinitions = $alertContacts = $config = $teams = $tags = [];
    $totalUrls = 0;
    $totalPages = 1;
}

// Helper function to build URL with current filters
function buildFilterUrl($newParams = []) {
    global $search, $teamFilter, $priorityFilter, $statusFilter, $tagFilter, $pageSize, $activeTab;
    
    $params = [
        'tab' => $activeTab,
        'search' => $search,
        'team' => $teamFilter,
        'priority' => $priorityFilter,
        'status' => $statusFilter,
        'tag' => $tagFilter,
        'page_size' => $pageSize,
        'page' => 1
    ];
    
    $params = array_merge($params, $newParams);
    $params = array_filter($params);
    
    return 'manage.php?' . http_build_query($params);
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo APP_NAME; ?> - Management</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="style.css" rel="stylesheet">
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
                <a class="nav-link" href="reports.php">
                    <i class="fas fa-chart-bar me-1"></i>Reports
                </a>
                <?php if ($auth->isAdmin()): ?>
                <a class="nav-link" href="users.php">
                    <i class="fas fa-users me-1"></i>Users
                </a>
                <?php endif; ?>
                <div class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown">
                        <i class="fas fa-user me-1"></i>
                        <?php echo htmlspecialchars($auth->getSessionInfo()['full_name']); ?>
                        <span class="badge bg-<?php echo $permissions['role'] === 'admin' ? 'danger' : 'info'; ?> ms-1">
                            <?php echo strtoupper($permissions['role']); ?>
                        </span>
                    </a>
                    <ul class="dropdown-menu">
                        <li><a class="dropdown-item" href="#"><i class="fas fa-key me-2"></i>Change Password</a></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item" href="logout.php"><i class="fas fa-sign-out-alt me-2"></i>Logout</a></li>
                    </ul>
                </div>
            </div>
        </div>
    </nav>

    <div class="container-fluid py-4">
        <!-- Role-based access message -->
        <?php if (!$canModify): ?>
            <div class="alert alert-info" role="alert">
                <i class="fas fa-info-circle me-2"></i>
                <strong>Read-Only Access:</strong> You can view all information but cannot make changes. Contact an administrator to modify settings.
            </div>
        <?php endif; ?>

        <?php if ($message): ?>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="fas fa-check-circle me-2"></i>
                <?php echo htmlspecialchars($message); ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <?php endif; ?>

        <?php if ($error): ?>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="fas fa-exclamation-triangle me-2"></i>
                <?php echo htmlspecialchars($error); ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <?php endif; ?>

        <!-- Tab Navigation -->
        <ul class="nav nav-tabs mb-4">
            <li class="nav-item">
                <a class="nav-link <?php echo $activeTab === 'urls' ? 'active' : ''; ?>" href="?tab=urls">
                    <i class="fas fa-globe me-2"></i>Monitored URLs
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?php echo $activeTab === 'alerts' ? 'active' : ''; ?>" href="?tab=alerts">
                    <i class="fas fa-bell me-2"></i>Alert Configuration
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?php echo $activeTab === 'config' ? 'active' : ''; ?>" href="?tab=config">
                    <i class="fas fa-cog me-2"></i>System Configuration
                </a>
            </li>
        </ul>

        <!-- URLs Tab -->
        <?php if ($activeTab === 'urls'): ?>
        <!-- Search and Filter Bar -->
        <div class="card mb-4">
            <div class="card-body">
                <form method="GET" class="row g-3">
                    <input type="hidden" name="tab" value="<?php echo htmlspecialchars($activeTab); ?>">
                    
                    <div class="col-md-3">
                        <label class="form-label">Search</label>
                        <input type="text" class="form-control" name="search" 
                               value="<?php echo htmlspecialchars($search); ?>" 
                               placeholder="Search name, URL, or description...">
                    </div>
                    
                    <div class="col-md-2">
                        <label class="form-label">Team</label>
                        <select class="form-select" name="team">
                            <option value="">All Teams</option>
                            <?php foreach ($teams as $team): ?>
                                <option value="<?php echo htmlspecialchars($team['team_name']); ?>" 
                                        <?php echo $teamFilter === $team['team_name'] ? 'selected' : ''; ?>>
                                    <?php echo htmlspecialchars($team['team_name']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    
                    <div class="col-md-2">
                        <label class="form-label">Priority</label>
                        <select class="form-select" name="priority">
                            <option value="">All Priorities</option>
                            <option value="critical" <?php echo $priorityFilter === 'critical' ? 'selected' : ''; ?>>Critical</option>
                            <option value="high" <?php echo $priorityFilter === 'high' ? 'selected' : ''; ?>>High</option>
                            <option value="normal" <?php echo $priorityFilter === 'normal' ? 'selected' : ''; ?>>Normal</option>
                            <option value="low" <?php echo $priorityFilter === 'low' ? 'selected' : ''; ?>>Low</option>
                        </select>
                    </div>
                    
                    <div class="col-md-2">
                        <label class="form-label">Status</label>
                        <select class="form-select" name="status">
                            <option value="">All Status</option>
                            <option value="up" <?php echo $statusFilter === 'up' ? 'selected' : ''; ?>>Up</option>
                            <option value="down" <?php echo $statusFilter === 'down' ? 'selected' : ''; ?>>Down</option>
                            <option value="error" <?php echo $statusFilter === 'error' ? 'selected' : ''; ?>>Error</option>
                            <option value="timeout" <?php echo $statusFilter === 'timeout' ? 'selected' : ''; ?>>Timeout</option>
                        </select>
                    </div>
                    
                    <div class="col-md-2">
                        <label class="form-label">Tag</label>
                        <select class="form-select" name="tag">
                            <option value="">All Tags</option>
                            <?php foreach ($tags as $tag): ?>
                                <option value="<?php echo htmlspecialchars($tag['tag']); ?>" 
                                        <?php echo $tagFilter === $tag['tag'] ? 'selected' : ''; ?>>
                                    <?php echo htmlspecialchars($tag['tag']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    
                    <div class="col-md-1">
                        <label class="form-label">&nbsp;</label>
                        <div>
                            <button type="submit" class="btn btn-primary">
                                <i class="fas fa-search"></i>
                            </button>
                            <a href="<?php echo buildFilterUrl(['search' => '', 'team' => '', 'priority' => '', 'status' => '', 'tag' => '']); ?>" 
                               class="btn btn-outline-secondary">
                                <i class="fas fa-times"></i>
                            </a>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <!-- URLs Management -->
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <div>
                    <h5 class="mb-0">
                        <i class="fas fa-globe me-2"></i>
                        Monitored URLs
                    </h5>
                    <small class="text-muted">
                        Showing <?php echo count($urls); ?> of <?php echo $totalUrls; ?> URLs
                        <?php if (!empty($search) || !empty($teamFilter) || !empty($priorityFilter) || !empty($statusFilter) || !empty($tagFilter)): ?>
                            (filtered)
                        <?php endif; ?>
                    </small>
                </div>
                <div>
                    <?php if ($canModify): ?>
                        <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addUrlModal">
                            <i class="fas fa-plus me-2"></i>Add URL
                        </button>
                    <?php endif; ?>
                </div>
            </div>
            
            <?php if ($canModify && !empty($urls)): ?>
            <!-- Bulk Actions -->
            <div class="card-body border-bottom">
                <form method="POST" id="bulkActionForm">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="action" value="bulk_action">
                    
                    <div class="row align-items-center">
                        <div class="col-auto">
                            <input type="checkbox" id="selectAll" class="form-check-input">
                            <label for="selectAll" class="form-check-label">Select All</label>
                        </div>
                        <div class="col-auto">
                            <select name="bulk_action" class="form-select form-select-sm">
                                <option value="">Bulk Actions...</option>
                                <option value="activate">Activate Selected</option>
                                <option value="deactivate">Deactivate Selected</option>
                                <option value="delete">Delete Selected</option>
                            </select>
                        </div>
                        <div class="col-auto">
                            <button type="submit" class="btn btn-sm btn-outline-primary" onclick="return confirmBulkAction()">
                                Apply
                            </button>
                        </div>
                    </div>
                </form>
            </div>
            <?php endif; ?>
            
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <?php if ($canModify): ?>
                                <th width="40"></th>
                                <?php endif; ?>
                                <th>Name & URL</th>
                                <th>Team & Tags</th>
                                <th>Priority</th>
                                <th>Status</th>
                                <th>Interval</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (empty($urls)): ?>
                                <tr>
                                    <td colspan="<?php echo $canModify ? '7' : '6'; ?>" class="text-center py-4">
                                        <i class="fas fa-inbox text-muted fa-2x mb-2"></i>
                                        <p class="text-muted">
                                            <?php if (!empty($search) || !empty($teamFilter) || !empty($priorityFilter) || !empty($statusFilter) || !empty($tagFilter)): ?>
                                                No URLs match your current filters
                                            <?php else: ?>
                                                No monitored URLs found
                                            <?php endif; ?>
                                        </p>
                                    </td>
                                </tr>
                            <?php else: ?>
                                <?php foreach ($urls as $url): ?>
                                <tr>
                                    <?php if ($canModify): ?>
                                    <td>
                                        <input type="checkbox" name="selected_urls[]" value="<?php echo $url['id']; ?>" 
                                               class="form-check-input url-checkbox" form="bulkActionForm">
                                    </td>
                                    <?php endif; ?>
                                    <td>
                                        <div>
                                            <strong><?php echo htmlspecialchars($url['name']); ?></strong>
                                            <?php if (!$url['is_active']): ?>
                                                <span class="badge bg-secondary ms-1">Inactive</span>
                                            <?php endif; ?>
                                            <br>
                                            <a href="<?php echo htmlspecialchars($url['url']); ?>" target="_blank" class="text-decoration-none small">
                                                <?php echo htmlspecialchars($url['url']); ?>
                                                <i class="fas fa-external-link-alt ms-1"></i>
                                            </a>
                                            <?php if ($url['description']): ?>
                                                <br><small class="text-muted"><?php echo htmlspecialchars($url['description']); ?></small>
                                            <?php endif; ?>
                                        </div>
                                    </td>
                                    <td>
                                        <div>
                                            <?php if ($url['team_name']): ?>
                                                <span class="badge bg-info"><?php echo htmlspecialchars($url['team_name']); ?></span>
                                            <?php else: ?>
                                                <span class="text-muted">No Team</span>
                                            <?php endif; ?>
                                            <?php if ($url['tags']): ?>
                                                <br>
                                                <?php foreach (explode(',', $url['tags']) as $tag): ?>
                                                    <span class="badge bg-light text-dark me-1"><?php echo htmlspecialchars(trim($tag)); ?></span>
                                                <?php endforeach; ?>
                                            <?php endif; ?>
                                        </div>
                                    </td>
                                    <td>
                                        <span class="priority-badge bg-<?php echo getPriorityClass($url['priority']); ?>">
                                            <?php echo strtoupper($url['priority']); ?>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="status-badge bg-<?php echo getStatusClass($url['last_status']); ?>">
                                            <?php echo getStatusIcon($url['last_status']); ?>
                                            <?php echo strtoupper($url['last_status'] ?: 'UNKNOWN'); ?>
                                        </span>
                                        <?php if ($url['current_failure_count'] > 0): ?>
                                            <br><small class="text-danger">
                                                <?php echo $url['current_failure_count']; ?>/<?php echo $url['failure_threshold']; ?> failures
                                            </small>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <?php echo $url['check_interval_minutes']; ?>m
                                        <?php if ($url['alert_name']): ?>
                                            <br><small class="text-muted"><?php echo htmlspecialchars($url['alert_name']); ?></small>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <div class="btn-group" role="group">
                                            <?php if ($canModify): ?>
                                                <button class="btn btn-sm btn-outline-primary edit-url-btn" 
                                                        data-url='<?php echo htmlspecialchars(json_encode($url)); ?>'>
                                                    <i class="fas fa-edit"></i>
                                                </button>
                                                <button class="btn btn-sm btn-outline-danger delete-url-btn" 
                                                        data-id="<?php echo $url['id']; ?>" 
                                                        data-name="<?php echo htmlspecialchars($url['name']); ?>">
                                                    <i class="fas fa-trash"></i>
                                                </button>
                                            <?php else: ?>
                                                <button class="btn btn-sm btn-outline-secondary view-url-btn" 
                                                        data-url='<?php echo htmlspecialchars(json_encode($url)); ?>'>
                                                    <i class="fas fa-eye"></i>
                                                </button>
                                            <?php endif; ?>
                                        </div>
                                    </td>
                                </tr>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
                
                <!-- Pagination -->
                <?php if ($totalPages > 1): ?>
                <div class="card-footer">
                    <nav aria-label="Page navigation">
                        <ul class="pagination pagination-sm justify-content-center mb-0">
                            <li class="page-item <?php echo $page <= 1 ? 'disabled' : ''; ?>">
                                <a class="page-link" href="<?php echo buildFilterUrl(['page' => $page - 1]); ?>">Previous</a>
                            </li>
                            
                            <?php for ($i = max(1, $page - 2); $i <= min($totalPages, $page + 2); $i++): ?>
                                <li class="page-item <?php echo $page == $i ? 'active' : ''; ?>">
                                    <a class="page-link" href="<?php echo buildFilterUrl(['page' => $i]); ?>"><?php echo $i; ?></a>
                                </li>
                            <?php endfor; ?>
                            
                            <li class="page-item <?php echo $page >= $totalPages ? 'disabled' : ''; ?>">
                                <a class="page-link" href="<?php echo buildFilterUrl(['page' => $page + 1]); ?>">Next</a>
                            </li>
                        </ul>
                    </nav>
                    
                    <div class="text-center mt-2">
                        <small class="text-muted">
                            Page <?php echo $page; ?> of <?php echo $totalPages; ?> 
                            (<?php echo $totalUrls; ?> total URLs)
                        </small>
                    </div>
                </div>
                <?php endif; ?>
            </div>
        </div>
        <?php endif; ?>

        <!-- Alerts Tab -->
        <?php if ($activeTab === 'alerts'): ?>
        <div class="row">
            <div class="col-lg-6">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">
                            <i class="fas fa-bell me-2"></i>
                            Alert Definitions
                        </h5>
                        <?php if ($canModify): ?>
                        <button type="button" class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#addAlertDefinitionModal">
                            <i class="fas fa-plus me-1"></i>Add Definition
                        </button>
                        <?php endif; ?>
                    </div>
                    <div class="card-body">
                        <?php foreach ($alertDefinitions as $def): ?>
                        <div class="alert-definition-card">
                            <div class="d-flex justify-content-between align-items-start">
                                <div>
                                    <h6 class="mb-1"><?php echo htmlspecialchars($def['alert_name']); ?></h6>
                                    <p class="text-muted mb-2"><?php echo htmlspecialchars($def['description']); ?></p>
                                    <small class="text-muted">
                                        Cooldown: <?php echo $def['cooldown_minutes']; ?>m |
                                        <?php echo $def['is_active'] ? 'Active' : 'Inactive'; ?>
                                    </small>
                                </div>
                                <div>
                                    <span class="badge bg-<?php echo $def['is_active'] ? 'success' : 'secondary'; ?>">
                                        <?php echo $def['is_active'] ? 'Active' : 'Inactive'; ?>
                                    </span>
                                </div>
                            </div>
                        </div>
                        <?php endforeach; ?>
                    </div>
                </div>
            </div>
            
            <div class="col-lg-6">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">
                            <i class="fas fa-users me-2"></i>
                            Alert Contacts
                        </h5>
                        <?php if ($canModify): ?>
                        <button type="button" class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#addContactModal">
                            <i class="fas fa-plus me-1"></i>Add Contact
                        </button>
                        <?php endif; ?>
                    </div>
                    <div class="card-body">
                        <?php 
                        $currentGroup = '';
                        foreach ($alertContacts as $contact): 
                            if ($contact['alert_name'] !== $currentGroup):
                                if ($currentGroup !== '') echo '</div>';
                                $currentGroup = $contact['alert_name'];
                                echo '<h6 class="mt-3 mb-2">' . htmlspecialchars($currentGroup) . '</h6><div>';
                            endif;
                        ?>
                        <div class="contact-item">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <strong><?php echo htmlspecialchars($contact['contact_name']); ?></strong>
                                    <br>
                                    <small>
                                        <?php echo htmlspecialchars($contact['contact_email']); ?>
                                        <?php if ($contact['contact_phone']): ?>
                                            | <?php echo htmlspecialchars($contact['contact_phone']); ?>
                                        <?php endif; ?>
                                    </small>
                                </div>
                                <div>
                                    <span class="badge bg-info"><?php echo strtoupper($contact['notification_type']); ?></span>
                                    <span class="badge bg-secondary">P<?php echo $contact['priority_order']; ?></span>
                                </div>
                            </div>
                        </div>
                        <?php endforeach; ?>
                        <?php if ($currentGroup !== '') echo '</div>'; ?>
                    </div>
                </div>
            </div>
        </div>
        <?php endif; ?>

        <!-- Configuration Tab -->
        <?php if ($activeTab === 'config'): ?>
        <?php if ($canModify): ?>
        <form method="POST">
            <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
            <input type="hidden" name="action" value="update_config">
            
            <?php 
            $categories = [];
            foreach ($config as $item) {
                $categories[$item['category']][] = $item;
            }
            ?>
            
            <?php foreach ($categories as $category => $items): ?>
            <div class="config-section">
                <h5 class="mb-3">
                    <i class="fas fa-cog me-2"></i>
                    <?php echo ucfirst($category); ?> Settings
                </h5>
                <div class="row">
                    <?php foreach ($items as $item): ?>
                    <div class="col-md-6 mb-3">
                        <label class="form-label"><?php echo htmlspecialchars($item['config_key']); ?></label>
                        <input type="text" class="form-control" name="config[<?php echo $item['config_key']; ?>]" 
                               value="<?php echo htmlspecialchars($item['config_value']); ?>">
                        <?php if ($item['description']): ?>
                            <div class="form-text"><?php echo htmlspecialchars($item['description']); ?></div>
                        <?php endif; ?>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>
            <?php endforeach; ?>
            
            <div class="text-end">
                <button type="submit" class="btn btn-primary">
                    <i class="fas fa-save me-2"></i>Save Configuration
                </button>
            </div>
        </form>
        <?php else: ?>
            <?php 
            $categories = [];
            foreach ($config as $item) {
                $categories[$item['category']][] = $item;
            }
            ?>
            
            <?php foreach ($categories as $category => $items): ?>
            <div class="config-section">
                <h5 class="mb-3">
                    <i class="fas fa-cog me-2"></i>
                    <?php echo ucfirst($category); ?> Settings
                </h5>
                <div class="row">
                    <?php foreach ($items as $item): ?>
                    <div class="col-md-6 mb-3">
                        <label class="form-label"><?php echo htmlspecialchars($item['config_key']); ?></label>
                        <input type="text" class="form-control" value="<?php echo htmlspecialchars($item['config_value']); ?>" readonly>
                        <?php if ($item['description']): ?>
                            <div class="form-text"><?php echo htmlspecialchars($item['description']); ?></div>
                        <?php endif; ?>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>
            <?php endforeach; ?>
        <?php endif; ?>
        <?php endif; ?>
    </div>

    <!-- Include all modals -->
    <?php include 'manage_modals.php'; ?>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <!-- Custom Management JS -->
    <script src="manage.js"></script>
    
    <!-- Pass PHP data to JavaScript -->
    <script>
        // Pass PHP configuration to JavaScript
        window.ManageConfig = {
            canModify: <?php echo json_encode($canModify); ?>,
            csrfToken: <?php echo json_encode(generateCSRFToken()); ?>,
            alertDefinitions: <?php echo json_encode($alertDefinitions); ?>,
            teams: <?php echo json_encode($teams); ?>,
            tags: <?php echo json_encode($tags); ?>
        };
    </script>
</body>
</html>