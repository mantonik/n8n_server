<?php
// users.php - User management system
require_once 'config.php';
require_once 'auth.php';

// Require authentication and admin role
$auth->requireAuth();
if (!$auth->isAdmin()) {
    header('HTTP/1.0 403 Forbidden');
    die('Access denied. Admin privileges required.');
}

$message = '';
$error = '';

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!validateCSRFToken($_POST['csrf_token'] ?? '')) {
        $error = 'Invalid security token. Please try again.';
    } else {
        try {
            switch ($_POST['action']) {
                case 'add_user':
                    $username = trim($_POST['username']);
                    $password = $_POST['password'];
                    $full_name = trim($_POST['full_name']);
                    $email = trim($_POST['email']);
                    $role = $_POST['role'];
                    
                    // Validate input
                    if (empty($username) || empty($password) || empty($full_name) || empty($email)) {
                        throw new Exception('All fields are required');
                    }
                    
                    if (strlen($password) < 8) {
                        throw new Exception('Password must be at least 8 characters long');
                    }
                    
                    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                        throw new Exception('Invalid email address');
                    }
                    
                    // Check if username already exists
                    $existing = $db->fetchOne("SELECT id FROM users WHERE username = ?", [$username]);
                    if ($existing) {
                        throw new Exception('Username already exists');
                    }
                    
                    // Hash password
                    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
                    
                    // Insert user
                    $sql = "INSERT INTO users (username, password_hash, full_name, email, role, is_active, created_at, created_by) 
                            VALUES (?, ?, ?, ?, ?, 1, NOW(), ?)";
                    $db->query($sql, [$username, $hashedPassword, $full_name, $email, $role, $_SESSION['username']]);
                    
                    $message = "User '{$username}' added successfully!";
                    break;
                    
                case 'update_user':
                    $userId = $_POST['user_id'];
                    $username = trim($_POST['username']);
                    $full_name = trim($_POST['full_name']);
                    $email = trim($_POST['email']);
                    $role = $_POST['role'];
                    $is_active = isset($_POST['is_active']) ? 1 : 0;
                    
                    // Validate input
                    if (empty($username) || empty($full_name) || empty($email)) {
                        throw new Exception('Username, full name, and email are required');
                    }
                    
                    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                        throw new Exception('Invalid email address');
                    }
                    
                    // Check if username already exists (excluding current user)
                    $existing = $db->fetchOne("SELECT id FROM users WHERE username = ? AND id != ?", [$username, $userId]);
                    if ($existing) {
                        throw new Exception('Username already exists');
                    }
                    
                    // Update user
                    $sql = "UPDATE users SET username = ?, full_name = ?, email = ?, role = ?, is_active = ?, 
                            updated_at = NOW(), updated_by = ? WHERE id = ?";
                    $db->query($sql, [$username, $full_name, $email, $role, $is_active, $_SESSION['username'], $userId]);
                    
                    $message = "User '{$username}' updated successfully!";
                    break;
                    
                case 'reset_password':
                    $userId = $_POST['user_id'];
                    $newPassword = $_POST['new_password'];
                    
                    if (strlen($newPassword) < 8) {
                        throw new Exception('Password must be at least 8 characters long');
                    }
                    
                    $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
                    $sql = "UPDATE users SET password_hash = ?, password_changed_at = NOW(), updated_at = NOW(), 
                            updated_by = ? WHERE id = ?";
                    $db->query($sql, [$hashedPassword, $_SESSION['username'], $userId]);
                    
                    $userInfo = $db->fetchOne("SELECT username FROM users WHERE id = ?", [$userId]);
                    $message = "Password reset for user '{$userInfo['username']}' successfully!";
                    break;
                    
                case 'delete_user':
                    $userId = $_POST['user_id'];
                    
                    // Prevent deleting yourself
                    $currentUser = $db->fetchOne("SELECT username FROM users WHERE id = ?", [$userId]);
                    if ($currentUser['username'] === $_SESSION['username']) {
                        throw new Exception('You cannot delete your own account');
                    }
                    
                    // Soft delete - mark as inactive instead of actual deletion
                    $sql = "UPDATE users SET is_active = 0, deleted_at = NOW(), updated_by = ? WHERE id = ?";
                    $db->query($sql, [$_SESSION['username'], $userId]);
                    
                    $message = "User '{$currentUser['username']}' deactivated successfully!";
                    break;
            }
        } catch (Exception $e) {
            $error = 'Error: ' . $e->getMessage();
        }
    }
}

// Get all users
try {
    $users = $db->fetchAll("
        SELECT 
            id, username, full_name, email, role, is_active, 
            created_at, last_login_at, login_count,
            created_by, updated_by, updated_at
        FROM users 
        WHERE deleted_at IS NULL
        ORDER BY created_at DESC
    ");
} catch (Exception $e) {
    $error = 'Error loading users: ' . $e->getMessage();
    $users = [];
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo APP_NAME; ?> - User Management</title>
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
                <a class="nav-link" href="manage.php">
                    <i class="fas fa-cog me-1"></i>Management
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

        <!-- Header -->
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h2>
                <i class="fas fa-users me-2"></i>
                User Management
            </h2>
            <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addUserModal">
                <i class="fas fa-plus me-2"></i>Add User
            </button>
        </div>

        <!-- Users Table -->
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">
                    <i class="fas fa-list me-2"></i>
                    System Users (<?php echo count($users); ?>)
                </h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>User</th>
                                <th>Role</th>
                                <th>Status</th>
                                <th>Last Login</th>
                                <th>Login Count</th>
                                <th>Created</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($users as $user): ?>
                            <tr>
                                <td>
                                    <div>
                                        <strong><?php echo htmlspecialchars($user['full_name']); ?></strong>
                                        <br>
                                        <small class="text-muted">
                                            @<?php echo htmlspecialchars($user['username']); ?> • 
                                            <?php echo htmlspecialchars($user['email']); ?>
                                        </small>
                                    </div>
                                </td>
                                <td>
                                    <span class="badge bg-<?php echo $user['role'] === 'admin' ? 'danger' : 'info'; ?>">
                                        <i class="fas fa-<?php echo $user['role'] === 'admin' ? 'crown' : 'eye'; ?> me-1"></i>
                                        <?php echo strtoupper($user['role']); ?>
                                    </span>
                                </td>
                                <td>
                                    <span class="badge bg-<?php echo $user['is_active'] ? 'success' : 'secondary'; ?>">
                                        <i class="fas fa-<?php echo $user['is_active'] ? 'check-circle' : 'ban'; ?> me-1"></i>
                                        <?php echo $user['is_active'] ? 'Active' : 'Inactive'; ?>
                                    </span>
                                </td>
                                <td>
                                    <?php if ($user['last_login_at']): ?>
                                        <small><?php echo formatDateTime($user['last_login_at']); ?></small>
                                    <?php else: ?>
                                        <small class="text-muted">Never</small>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <span class="badge bg-light text-dark"><?php echo $user['login_count'] ?: 0; ?></span>
                                </td>
                                <td>
                                    <small>
                                        <?php echo formatDateTime($user['created_at']); ?>
                                        <?php if ($user['created_by']): ?>
                                            <br><em>by <?php echo htmlspecialchars($user['created_by']); ?></em>
                                        <?php endif; ?>
                                    </small>
                                </td>
                                <td>
                                    <div class="btn-group" role="group">
                                        <button class="btn btn-sm btn-outline-primary" onclick="editUser(<?php echo htmlspecialchars(json_encode($user)); ?>)">
                                            <i class="fas fa-edit"></i>
                                        </button>
                                        <button class="btn btn-sm btn-outline-warning" onclick="resetPassword(<?php echo $user['id']; ?>, '<?php echo htmlspecialchars($user['username']); ?>')">
                                            <i class="fas fa-key"></i>
                                        </button>
                                        <?php if ($user['username'] !== $_SESSION['username']): ?>
                                        <button class="btn btn-sm btn-outline-danger" onclick="deleteUser(<?php echo $user['id']; ?>, '<?php echo htmlspecialchars($user['username']); ?>')">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                        <?php endif; ?>
                                    </div>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- Role Information -->
        <div class="row mt-4">
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header">
                        <h6 class="mb-0">
                            <i class="fas fa-crown me-2 text-danger"></i>
                            Admin Role
                        </h6>
                    </div>
                    <div class="card-body">
                        <ul class="list-unstyled mb-0">
                            <li><i class="fas fa-check text-success me-2"></i>Full dashboard access</li>
                            <li><i class="fas fa-check text-success me-2"></i>Manage URLs and alerts</li>
                            <li><i class="fas fa-check text-success me-2"></i>View and modify system configuration</li>
                            <li><i class="fas fa-check text-success me-2"></i>Generate reports</li>
                            <li><i class="fas fa-check text-success me-2"></i>Manage users</li>
                        </ul>
                    </div>
                </div>
            </div>
            
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header">
                        <h6 class="mb-0">
                            <i class="fas fa-eye me-2 text-info"></i>
                            Read-Only Role
                        </h6>
                    </div>
                    <div class="card-body">
                        <ul class="list-unstyled mb-0">
                            <li><i class="fas fa-check text-success me-2"></i>View dashboard</li>
                            <li><i class="fas fa-check text-success me-2"></i>View URLs and alerts</li>
                            <li><i class="fas fa-times text-danger me-2"></i>Cannot modify configuration</li>
                            <li><i class="fas fa-check text-success me-2"></i>View reports</li>
                            <li><i class="fas fa-times text-danger me-2"></i>Cannot manage users</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Add User Modal -->
    <div class="modal fade" id="addUserModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Add New User</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="action" value="add_user">
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">Username</label>
                            <input type="text" class="form-control" name="username" required>
                            <div class="form-text">Lowercase letters, numbers, and underscores only</div>
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Full Name</label>
                            <input type="text" class="form-control" name="full_name" required>
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Email Address</label>
                            <input type="email" class="form-control" name="email" required>
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Password</label>
                            <input type="password" class="form-control" name="password" required minlength="8">
                            <div class="form-text">Minimum 8 characters</div>
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Role</label>
                            <select class="form-select" name="role" required>
                                <option value="readonly">Read-Only User</option>
                                <option value="admin">Administrator</option>
                            </select>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Add User</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Edit User Modal -->
    <div class="modal fade" id="editUserModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Edit User</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST" id="editUserForm">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="action" value="update_user">
                    <input type="hidden" name="user_id" id="edit_user_id">
                    <div class="modal-body" id="editUserBody">
                        <!-- Content populated by JavaScript -->
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Update User</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Reset Password Modal -->
    <div class="modal fade" id="resetPasswordModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Reset Password</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="action" value="reset_password">
                    <input type="hidden" name="user_id" id="reset_user_id">
                    <div class="modal-body">
                        <p>Reset password for user: <strong id="reset_username"></strong></p>
                        <div class="mb-3">
                            <label class="form-label">New Password</label>
                            <input type="password" class="form-control" name="new_password" required minlength="8">
                            <div class="form-text">Minimum 8 characters</div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-warning">Reset Password</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Delete User Modal -->
    <div class="modal fade" id="deleteUserModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Deactivate User</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p>Are you sure you want to deactivate user: <strong id="delete_username"></strong>?</p>
                    <p class="text-muted">The user will be deactivated and will no longer be able to log in.</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <form method="POST" style="display: inline;">
                        <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                        <input type="hidden" name="action" value="delete_user">
                        <input type="hidden" name="user_id" id="delete_user_id">
                        <button type="submit" class="btn btn-danger">Deactivate User</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function editUser(user) {
            document.getElementById('edit_user_id').value = user.id;
            
            const body = document.getElementById('editUserBody');
            body.innerHTML = `
                <div class="mb-3">
                    <label class="form-label">Username</label>
                    <input type="text" class="form-control" name="username" value="${user.username}" required>
                </div>
                
                <div class="mb-3">
                    <label class="form-label">Full Name</label>
                    <input type="text" class="form-control" name="full_name" value="${user.full_name}" required>
                </div>
                
                <div class="mb-3">
                    <label class="form-label">Email Address</label>
                    <input type="email" class="form-control" name="email" value="${user.email}" required>
                </div>
                
                <div class="mb-3">
                    <label class="form-label">Role</label>
                    <select class="form-select" name="role" required>
                        <option value="readonly" ${user.role === 'readonly' ? 'selected' : ''}>Read-Only User</option>
                        <option value="admin" ${user.role === 'admin' ? 'selected' : ''}>Administrator</option>
                    </select>
                </div>
                
                <div class="mb-3">
                    <div class="form-check">
                        <input class="form-check-input" type="checkbox" name="is_active" id="edit_is_active" ${user.is_active ? 'checked' : ''}>
                        <label class="form-check-label" for="edit_is_active">
                            Active Account
                        </label>
                    </div>
                </div>
            `;
            
            new bootstrap.Modal(document.getElementById('editUserModal')).show();
        }
        
        function resetPassword(userId, username) {
            document.getElementById('reset_user_id').value = userId;
            document.getElementById('reset_username').textContent = username;
            new bootstrap.Modal(document.getElementById('resetPasswordModal')).show();
        }
        
        function deleteUser(userId, username) {
            document.getElementById('delete_user_id').value = userId;
            document.getElementById('delete_username').textContent = username;
            new bootstrap.Modal(document.getElementById('deleteUserModal')).show();
        }
    </script>
</body>
</html>