<?php
// logout.php - Handle user logout
require_once 'config.php';
require_once 'auth.php';

// Perform logout
$auth->logout();

// Redirect to login page with message
header('Location: login.php?message=logged_out');
exit;
?>