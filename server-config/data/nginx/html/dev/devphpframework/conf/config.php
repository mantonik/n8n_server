// ========================================
// conf/config.php - Global Configuration
// ========================================

$config = [
    'debug' => true,
    'default_template' => 'template1',
    'site_name' => 'My Modular Site',
    'timezone' => 'America/New_York',
    'session_timeout' => 3600, // 1 hour
    'allowed_file_types' => ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx'],
    'max_file_size' => 5242880, // 5MB
    'admin_email' => 'admin@example.com'
];

// Set timezone
date_default_timezone_set($config['timezone']);