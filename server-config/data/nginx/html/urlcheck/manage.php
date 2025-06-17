<?php
// manage.php - Management and configuration page
require_once 'config.php';
require_once 'auth.php';

// Require authentication
$auth->requireAuth();

$message = '';
$error = '';
$activeTab = $_GET['tab'] ?? 'urls';

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!validateCSRFToken($_POST['csrf_token'] ?? '')) {
        $error = 'Invalid security token. Please try again.';
    } else {
        try {
            switch ($_POST['action']) {
                case 'add_url':
                    $sql = "INSERT INTO monitored_urls (url, name, description, priority, team_name, alert_definition_id, 
                            check_interval_minutes, timeout_seconds, failure_threshold, expected_response, 
                            response_time_warning_ms, response_time_critical_ms, check_ssl_expiry, ssl_days_warning) 
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                    $db->query($sql, [
                        $_POST['url'], $_POST['name'], $_POST['description'], $_POST['priority'],
                        $_POST['team_name'], $_POST['alert_definition_id'] ?: null,
                        $_POST['check_interval_minutes'], $_POST['timeout_seconds'], $_POST['failure_threshold'],
                        $_POST['expected_response'], $_POST['response_time_warning_ms'], $_POST['response_time_critical_ms'],
                        isset($_POST['check_ssl_expiry']) ? 1 : 0, $_POST['ssl_days_warning']
                    ]);
                    $message = 'URL added successfully!';
                    break;
                    
                case 'update_url':
                    $sql = "UPDATE monitored_urls SET url=?, name=?, description=?, priority=?, team_name=?, 
                            alert_definition_id=?, check_interval_minutes=?, timeout_seconds=?, failure_threshold=?, 
                            expected_response=?, response_time_warning_ms=?, response_time_critical_ms=?, 
                            check_ssl_expiry=?, ssl_days_warning=?, is_active=?, updated_at=NOW() WHERE id=?";
                    $db->query($sql, [
                        $_POST['url'], $_POST['name'], $_POST['description'], $_POST['priority'],
                        $_POST['team_name'], $_POST['alert_definition_id'] ?: null,
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
}

// Get data for display
try {
    $urls = $db->fetchAll("SELECT * FROM monitored_urls ORDER BY priority, name");
    $alertDefinitions = $db->fetchAll("SELECT * FROM alert_definitions ORDER BY alert_name");
    $alertContacts = $db->fetchAll("
        SELECT ac.*, ad.alert_name 
        FROM alert_contacts ac 
        JOIN alert_definitions ad ON ac.alert_definition_id = ad.id 
        ORDER BY ad.alert_name, ac.priority_order
    ");
    $config = $db->fetchAll("SELECT * FROM config ORDER BY category, config_key");
} catch (Exception $e) {
    $error = 'Error loading data: ' . $e->getMessage();
    $urls = $alertDefinitions = $alertContacts = $config = [];
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
    <style>
        body {
            background-color: #f8f9fa;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        .navbar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            margin-bottom: 2rem;
        }
        
        .card-header {
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            border-bottom: 1px solid #dee2e6;
            border-radius: 15px 15px 0 0 !important;
            font-weight: 600;
        }
        
        .nav-tabs .nav-link {
            border: none;
            color: #6c757d;
            font-weight: 500;
            padding: 1rem 1.5rem;
            border-radius: 10px 10px 0 0;
            margin-right: 0.5rem;
        }
        
        .nav-tabs .nav-link.active {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .table th {
            background-color: #f8f9fa;
            border-top: none;
            font-weight: 600;
            color: #495057;
        }
        
        .btn-sm {
            padding: 0.4rem 0.8rem;
            font-size: 0.8rem;
        }
        
        .status-badge {
            padding: 0.3rem 0.6rem;
            border-radius: 15px;
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
        
        .form-label {
            font-weight: 600;
            color: #495057;
        }
        
        .modal-header {
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            border-bottom: 1px solid #dee2e6;
        }
        
        .config-section {
            background: white;
            padding: 1.5rem;
            border-radius: 10px;
            margin-bottom: 1rem;
            border-left: 4px solid #667eea;
        }
        
        .alert-definition-card {
            background: white;
            padding: 1.5rem;
            border-radius: 10px;
            margin-bottom: 1rem;
            border: 1px solid #dee2e6;
        }
        
        .contact-item {
            background: #f8f9fa;
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 0.5rem;
            border-left: 3px solid #28a745;
        }
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
                <a class="nav-link" href="dashboard.php">
                    <i class="fas fa-dashboard me-1"></i>Dashboard
                </a>
                <a class="nav-link" href="reports.php">
                    <i class="fas fa-chart-bar me-1"></i>Reports
                </a>
                <a class="nav-link" href="logout.php">
                    <i class="fas fa-sign-out-alt me-1"></i>Logout
                </a>
            </div>
        </div>
    </nav>

    <div class="container-fluid py-4">
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
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">
                    <i class="fas fa-globe me-2"></i>
                    Monitored URLs (<?php echo count($urls); ?>)
                </h5>
                <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addUrlModal">
                    <i class="fas fa-plus me-2"></i>Add URL
                </button>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>URL</th>
                                <th>Priority</th>
                                <th>Team</th>
                                <th>Status</th>
                                <th>Interval</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($urls as $url): ?>
                            <tr>
                                <td>
                                    <strong><?php echo htmlspecialchars($url['name']); ?></strong>
                                    <?php if ($url['description']): ?>
                                        <br><small class="text-muted"><?php echo htmlspecialchars($url['description']); ?></small>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <a href="<?php echo htmlspecialchars($url['url']); ?>" target="_blank" class="text-decoration-none">
                                        <?php echo htmlspecialchars($url['url']); ?>
                                        <i class="fas fa-external-link-alt ms-1"></i>
                                    </a>
                                </td>
                                <td>
                                    <span class="priority-badge bg-<?php echo getPriorityClass($url['priority']); ?>">
                                        <?php echo strtoupper($url['priority']); ?>
                                    </span>
                                </td>
                                <td><?php echo htmlspecialchars($url['team_name'] ?: 'Unassigned'); ?></td>
                                <td>
                                    <span class="status-badge bg-<?php echo getStatusClass($url['last_status']); ?>">
                                        <?php echo getStatusIcon($url['last_status']); ?>
                                        <?php echo strtoupper($url['last_status'] ?: 'UNKNOWN'); ?>
                                    </span>
                                    <?php if (!$url['is_active']): ?>
                                        <br><small class="text-muted">Inactive</small>
                                    <?php endif; ?>
                                </td>
                                <td><?php echo $url['check_interval_minutes']; ?>m</td>
                                <td>
                                    <button class="btn btn-sm btn-outline-primary me-1" onclick="editUrl(<?php echo htmlspecialchars(json_encode($url)); ?>)">
                                        <i class="fas fa-edit"></i>
                                    </button>
                                    <button class="btn btn-sm btn-outline-danger" onclick="deleteUrl(<?php echo $url['id']; ?>, '<?php echo htmlspecialchars($url['name']); ?>')">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
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
                        <button type="button" class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#addAlertDefinitionModal">
                            <i class="fas fa-plus me-1"></i>Add Definition
                        </button>
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
                        <button type="button" class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#addContactModal">
                            <i class="fas fa-plus me-1"></i>Add Contact
                        </button>
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
        <?php endif; ?>
    </div>

    <!-- Add URL Modal -->
    <div class="modal fade" id="addUrlModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Add New URL</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="action" value="add_url">
                    <div class="modal-body">
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label class="form-label">URL</label>
                                <input type="url" class="form-control" name="url" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Name</label>
                                <input type="text" class="form-control" name="name" required>
                            </div>
                            <div class="col-12 mb-3">
                                <label class="form-label">Description</label>
                                <textarea class="form-control" name="description" rows="2"></textarea>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Priority</label>
                                <select class="form-select" name="priority" required>
                                    <option value="critical">Critical</option>
                                    <option value="high">High</option>
                                    <option value="normal" selected>Normal</option>
                                    <option value="low">Low</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Team</label>
                                <input type="text" class="form-control" name="team_name">
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Alert Definition</label>
                                <select class="form-select" name="alert_definition_id">
                                    <option value="">None</option>
                                    <?php foreach ($alertDefinitions as $def): ?>
                                        <option value="<?php echo $def['id']; ?>">
                                            <?php echo htmlspecialchars($def['alert_name']); ?>
                                        </option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Check Interval (minutes)</label>
                                <input type="number" class="form-control" name="check_interval_minutes" value="5" min="1" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Timeout (seconds)</label>
                                <input type="number" class="form-control" name="timeout_seconds" value="30" min="1" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Failure Threshold</label>
                                <input type="number" class="form-control" name="failure_threshold" value="5" min="1" required>
                            </div>
                            <div class="col-12 mb-3">
                                <label class="form-label">Expected Response Text</label>
                                <input type="text" class="form-control" name="expected_response" placeholder="Optional text to look for in response">
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Warning Response Time (ms)</label>
                                <input type="number" class="form-control" name="response_time_warning_ms" value="5000">
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Critical Response Time (ms)</label>
                                <input type="number" class="form-control" name="response_time_critical_ms" value="10000">
                            </div>
                            <div class="col-md-6 mb-3">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" name="check_ssl_expiry" id="check_ssl_expiry">
                                    <label class="form-check-label" for="check_ssl_expiry">
                                        Monitor SSL Certificate
                                    </label>
                                </div>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">SSL Warning Days</label>
                                <input type="number" class="form-control" name="ssl_days_warning" value="30">
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Add URL</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Edit URL Modal -->
    <div class="modal fade" id="editUrlModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Edit URL</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST" id="editUrlForm">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="action" value="update_url">
                    <input type="hidden" name="url_id" id="edit_url_id">
                    <div class="modal-body" id="editUrlBody">
                        <!-- Content populated by JavaScript -->
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Update URL</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Add Alert Definition Modal -->
    <div class="modal fade" id="addAlertDefinitionModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Add Alert Definition</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="action" value="add_alert_definition">
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">Alert Name</label>
                            <input type="text" class="form-control" name="alert_name" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Description</label>
                            <textarea class="form-control" name="description" rows="3"></textarea>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Cooldown (minutes)</label>
                            <input type="number" class="form-control" name="cooldown_minutes" value="60" min="1" required>
                        </div>
                        <div class="mb-3">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" name="escalation_enabled" id="escalation_enabled">
                                <label class="form-check-label" for="escalation_enabled">
                                    Enable Escalation
                                </label>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Escalation Delay (minutes)</label>
                            <input type="number" class="form-control" name="escalation_delay_minutes" value="30">
                        </div>
                        <div class="mb-3">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" name="business_hours_only" id="business_hours_only">
                                <label class="form-check-label" for="business_hours_only">
                                    Business Hours Only
                                </label>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-4 mb-3">
                                <label class="form-label">Timezone</label>
                                <input type="text" class="form-control" name="timezone" value="UTC">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">Start Hour</label>
                                <input type="number" class="form-control" name="business_start_hour" value="9" min="0" max="23">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">End Hour</label>
                                <input type="number" class="form-control" name="business_end_hour" value="17" min="0" max="23">
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Add Definition</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Add Contact Modal -->
    <div class="modal fade" id="addContactModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Add Alert Contact</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="action" value="add_alert_contact">
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">Alert Definition</label>
                            <select class="form-select" name="alert_definition_id" required>
                                <option value="">Select Alert Definition</option>
                                <?php foreach ($alertDefinitions as $def): ?>
                                    <option value="<?php echo $def['id']; ?>">
                                        <?php echo htmlspecialchars($def['alert_name']); ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Contact Name</label>
                            <input type="text" class="form-control" name="contact_name" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Email Address</label>
                            <input type="email" class="form-control" name="contact_email" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Phone Number</label>
                            <input type="tel" class="form-control" name="contact_phone">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Notification Type</label>
                            <select class="form-select" name="notification_type" required>
                                <option value="email">Email</option>
                                <option value="sms">SMS</option>
                                <option value="webhook">Webhook</option>
                                <option value="slack">Slack</option>
                                <option value="teams">Teams</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Priority Order</label>
                            <input type="number" class="form-control" name="priority_order" value="1" min="1" required>
                            <div class="form-text">1 = Primary contact, 2 = Secondary, etc.</div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Add Contact</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div class="modal fade" id="deleteModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Confirm Deletion</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p>Are you sure you want to delete <strong id="deleteItemName"></strong>?</p>
                    <p class="text-muted">This action cannot be undone.</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <form method="POST" id="deleteForm" style="display: inline;">
                        <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                        <input type="hidden" name="action" value="delete_url">
                        <input type="hidden" name="url_id" id="deleteUrlId">
                        <button type="submit" class="btn btn-danger">Delete</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function editUrl(url) {
            document.getElementById('edit_url_id').value = url.id;
            
            const body = document.getElementById('editUrlBody');
            body.innerHTML = `
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">URL</label>
                        <input type="url" class="form-control" name="url" value="${url.url}" required>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Name</label>
                        <input type="text" class="form-control" name="name" value="${url.name}" required>
                    </div>
                    <div class="col-12 mb-3">
                        <label class="form-label">Description</label>
                        <textarea class="form-control" name="description" rows="2">${url.description || ''}</textarea>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Priority</label>
                        <select class="form-select" name="priority" required>
                            <option value="critical" ${url.priority === 'critical' ? 'selected' : ''}>Critical</option>
                            <option value="high" ${url.priority === 'high' ? 'selected' : ''}>High</option>
                            <option value="normal" ${url.priority === 'normal' ? 'selected' : ''}>Normal</option>
                            <option value="low" ${url.priority === 'low' ? 'selected' : ''}>Low</option>
                        </select>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Team</label>
                        <input type="text" class="form-control" name="team_name" value="${url.team_name || ''}">
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Alert Definition</label>
                        <select class="form-select" name="alert_definition_id">
                            <option value="">None</option>
                            <?php foreach ($alertDefinitions as $def): ?>
                                <option value="<?php echo $def['id']; ?>" ${url.alert_definition_id == <?php echo $def['id']; ?> ? 'selected' : ''}>
                                    <?php echo htmlspecialchars($def['alert_name']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Check Interval (minutes)</label>
                        <input type="number" class="form-control" name="check_interval_minutes" value="${url.check_interval_minutes}" min="1" required>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Timeout (seconds)</label>
                        <input type="number" class="form-control" name="timeout_seconds" value="${url.timeout_seconds}" min="1" required>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Failure Threshold</label>
                        <input type="number" class="form-control" name="failure_threshold" value="${url.failure_threshold}" min="1" required>
                    </div>
                    <div class="col-12 mb-3">
                        <label class="form-label">Expected Response Text</label>
                        <input type="text" class="form-control" name="expected_response" value="${url.expected_response || ''}" placeholder="Optional text to look for in response">
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Warning Response Time (ms)</label>
                        <input type="number" class="form-control" name="response_time_warning_ms" value="${url.response_time_warning_ms}">
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Critical Response Time (ms)</label>
                        <input type="number" class="form-control" name="response_time_critical_ms" value="${url.response_time_critical_ms}">
                    </div>
                    <div class="col-md-6 mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="check_ssl_expiry" id="edit_check_ssl_expiry" ${url.check_ssl_expiry ? 'checked' : ''}>
                            <label class="form-check-label" for="edit_check_ssl_expiry">
                                Monitor SSL Certificate
                            </label>
                        </div>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">SSL Warning Days</label>
                        <input type="number" class="form-control" name="ssl_days_warning" value="${url.ssl_days_warning}">
                    </div>
                    <div class="col-12 mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="is_active" id="edit_is_active" ${url.is_active ? 'checked' : ''}>
                            <label class="form-check-label" for="edit_is_active">
                                Active
                            </label>
                        </div>
                    </div>
                </div>
            `;
            
            new bootstrap.Modal(document.getElementById('editUrlModal')).show();
        }
        
        function deleteUrl(urlId, urlName) {
            document.getElementById('deleteUrlId').value = urlId;
            document.getElementById('deleteItemName').textContent = urlName;
            new bootstrap.Modal(document.getElementById('deleteModal')).show();
        }
        
        // Auto-save form data to localStorage (optional enhancement)
        document.addEventListener('DOMContentLoaded', function() {
            // Add any additional JavaScript enhancements here
            
            // Example: Auto-focus first form field in modals
            document.querySelectorAll('.modal').forEach(modal => {
                modal.addEventListener('shown.bs.modal', function() {
                    const firstInput = this.querySelector('input:not([type="hidden"]), select, textarea');
                    if (firstInput) {
                        firstInput.focus();
                    }
                });
            });
        });
    </script>
</body>
</html>