<?php
// index.php - Main entry point
require_once 'config.php';
require_once 'auth.php';

// Check if user is authenticated
if ($auth->isAuthenticated()) {
    // Redirect to dashboard
    header('Location: dashboard.php');
} else {
    // Redirect to login
    header('Location: login.php');
}
exit;
?>