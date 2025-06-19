<?php
// login.php - Enhanced login page with demo user information
require_once 'config.php';
require_once 'auth.php';

$error_message = '';
$success_message = '';

// Handle login form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['username']) && isset($_POST['password'])) {
        $username = trim($_POST['username']);
        $password = $_POST['password'];
        
        if (!empty($username) && !empty($password)) {
            $result = $auth->login($username, $password);
            
            if ($result['success']) {
                header('Location: dashboard.php');
                exit;
            } else {
                $error_message = $result['message'];
            }
        } else {
            $error_message = 'Please enter both username and password.';
        }
    }
}

// Handle logout message
if (isset($_GET['message']) && $_GET['message'] === 'logged_out') {
    $success_message = 'You have been successfully logged out.';
}

// If already authenticated, redirect to dashboard
if ($auth->isAuthenticated()) {
    header('Location: dashboard.php');
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo APP_NAME; ?> - Login</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="style.css" rel="stylesheet">
</head>
<body>
    <div class="login-container">
        <div class="login-header">
            <i class="fas fa-shield-alt icon-shield"></i>
            <h1><?php echo APP_NAME; ?></h1>
            <p>Secure Dashboard Access</p>
        </div>
        
        <?php if ($error_message): ?>
            <div class="alert alert-danger" role="alert">
                <i class="fas fa-exclamation-triangle me-2"></i>
                <?php echo htmlspecialchars($error_message); ?>
            </div>
        <?php endif; ?>
        
        <?php if ($success_message): ?>
            <div class="alert alert-success" role="alert">
                <i class="fas fa-check-circle me-2"></i>
                <?php echo htmlspecialchars($success_message); ?>
            </div>
        <?php endif; ?>
        
        <form method="POST" action="login.php">
            <div class="form-floating">
                <input type="text" class="form-control" id="username" name="username" placeholder="Username" required autocomplete="username">
                <label for="username"><i class="fas fa-user me-2"></i>Username</label>
            </div>
            
            <div class="form-floating">
                <input type="password" class="form-control" id="password" name="password" placeholder="Password" required autocomplete="current-password">
                <label for="password"><i class="fas fa-lock me-2"></i>Password</label>
            </div>
            
            <button type="submit" class="btn btn-primary btn-login">
                <i class="fas fa-sign-in-alt me-2"></i>
                Sign In
            </button>
        </form>

        <!-- Demo Account Information -->
        <div class="demo-info">
            <div class="demo-header">
                <i class="fas fa-eye me-2"></i>
                <strong>Demo Account Available</strong>
            </div>
            <div class="demo-accounts">
                <div class="demo-account">
                    <div class="demo-account-header">
                        <i class="fas fa-user-shield me-2 text-danger"></i>
                        <strong>Administrator Access</strong>
                    </div>
                    <div class="demo-credentials">
                        <span class="demo-label">Username:</span> <code>admin</code><br>
                        <span class="demo-label">Password:</span> <code>monitor123!</code>
                    </div>
                    <div class="demo-features">
                        <small class="text-muted">Full access - Add, edit, delete URLs and manage users</small>
                    </div>
                </div>
                
                <div class="demo-account">
                    <div class="demo-account-header">
                        <i class="fas fa-eye me-2 text-info"></i>
                        <strong>Demo User (Read-Only)</strong>
                    </div>
                    <div class="demo-credentials">
                        <span class="demo-label">Username:</span> <code>demo</code><br>
                        <span class="demo-label">Password:</span> <code>demo</code>
                    </div>
                    <div class="demo-features">
                        <small class="text-muted">View-only access - 30 minute session limit</small>
                    </div>
                </div>
            </div>
            
            <div class="demo-note">
                <small class="text-muted">
                    <i class="fas fa-info-circle me-1"></i>
                    Demo accounts are for evaluation purposes. Change default passwords in production.
                </small>
            </div>
        </div>
        
        <?php if (PUBLIC_DASHBOARD_ENABLED): ?>
            <div class="public-link">
                <a href="public.php">
                    <i class="fas fa-eye me-1"></i>
                    View Public Dashboard
                </a>
            </div>
        <?php endif; ?>
        
        <div class="system-status">
            <div class="status-indicator">
                <i class="fas fa-heartbeat"></i>
                <span>System Online</span>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Focus username field on page load
        document.addEventListener('DOMContentLoaded', function() {
            document.getElementById('username').focus();
        });
        
        // Handle Enter key in password field
        document.getElementById('password').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                this.form.submit();
            }
        });
        
        // Quick login buttons
        function quickLogin(username, password) {
            document.getElementById('username').value = username;
            document.getElementById('password').value = password;
            document.querySelector('form').submit();
        }
        
        // Add quick login buttons
        document.addEventListener('DOMContentLoaded', function() {
            const demoAccounts = document.querySelectorAll('.demo-account');
            
            demoAccounts.forEach(account => {
                const credentials = account.querySelector('.demo-credentials');
                const codes = credentials.querySelectorAll('code');
                
                if (codes.length >= 2) {
                    const username = codes[0].textContent;
                    const password = codes[1].textContent;
                    
                    const quickLoginBtn = document.createElement('button');
                    quickLoginBtn.type = 'button';
                    quickLoginBtn.className = 'btn btn-outline-primary btn-sm mt-2';
                    quickLoginBtn.innerHTML = '<i class="fas fa-bolt me-1"></i>Quick Login';
                    quickLoginBtn.onclick = () => quickLogin(username, password);
                    
                    account.appendChild(quickLoginBtn);
                }
            });
        });
    </script>
    
    <style>
        .demo-info {
            margin-top: 2rem;
            padding: 1.5rem;
            background: rgba(255, 255, 255, 0.9);
            border-radius: 15px;
            border: 1px solid rgba(102, 126, 234, 0.2);
            backdrop-filter: blur(5px);
        }
        
        .demo-header {
            text-align: center;
            margin-bottom: 1rem;
            color: #667eea;
            font-size: 1.1rem;
        }
        
        .demo-accounts {
            display: grid;
            gap: 1rem;
        }
        
        .demo-account {
            background: rgba(248, 249, 250, 0.8);
            padding: 1rem;
            border-radius: 10px;
            border: 1px solid #dee2e6;
        }
        
        .demo-account-header {
            font-weight: 600;
            margin-bottom: 0.5rem;
            display: flex;
            align-items: center;
        }
        
        .demo-credentials {
            margin-bottom: 0.5rem;
            font-family: 'Courier New', monospace;
        }
        
        .demo-credentials code {
            background: rgba(102, 126, 234, 0.1);
            color: #667eea;
            padding: 0.2rem 0.4rem;
            border-radius: 4px;
            font-weight: 600;
        }
        
        .demo-label {
            font-weight: 500;
            color: #495057;
        }
        
        .demo-features {
            margin-top: 0.5rem;
        }
        
        .demo-note {
            text-align: center;
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid #dee2e6;
        }
        
        .form-floating {
            margin-bottom: 1rem;
        }
        
        @media (max-width: 576px) {
            .demo-info {
                margin: 1rem;
                padding: 1rem;
            }
            
            .demo-credentials {
                font-size: 0.9rem;
            }
        }
    </style>
</body>
</html>