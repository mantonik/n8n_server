<?php
// ========================================
// index.php - Main Entry Point (Fixed Version)
// Version: 1.0.1
// Created: 2025-07-01
// Framework: PHP Modular Development Framework
// Purpose: Main router with error handling and debugging
// Database: dev_phpframework
// ========================================

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);

try {
    // Start session
    session_start();
    
    // Include core files with error checking
    $includesPath = __DIR__ . '/includes/functions.php';
    if (!file_exists($includesPath)) {
        throw new Exception("Required file not found: includes/functions.php");
    }
    require_once $includesPath;
    
    // Initialize framework
    $framework = new ModularFramework();
    $framework->handleRequest();
    
} catch (Exception $e) {
    // Handle errors gracefully
    http_response_code(500);
    
    echo "<!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Framework Error</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
            .error-container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .error-header { color: #dc3545; border-bottom: 1px solid #dee2e6; padding-bottom: 10px; }
            .error-details { margin: 20px 0; }
            .stack-trace { background: #f8f9fa; padding: 15px; border-radius: 4px; overflow-x: auto; }
            .debug-info { margin-top: 20px; font-size: 12px; color: #6c757d; }
        </style>
    </head>
    <body>
        <div class='error-container'>
            <h1 class='error-header'>Framework Initialization Error</h1>
            <div class='error-details'>
                <p><strong>Error:</strong> " . htmlspecialchars($e->getMessage()) . "</p>
                <p><strong>File:</strong> " . htmlspecialchars($e->getFile()) . "</p>
                <p><strong>Line:</strong> " . $e->getLine() . "</p>
            </div>
            
            <details>
                <summary>Stack Trace</summary>
                <pre class='stack-trace'>" . htmlspecialchars($e->getTraceAsString()) . "</pre>
            </details>
            
            <div class='debug-info'>
                <p><strong>Current Directory:</strong> " . htmlspecialchars(getcwd()) . "</p>
                <p><strong>Script Path:</strong> " . htmlspecialchars($_SERVER['SCRIPT_FILENAME'] ?? 'Unknown') . "</p>
                <p><strong>Request URI:</strong> " . htmlspecialchars($_SERVER['REQUEST_URI'] ?? 'Unknown') . "</p>
                <p><strong>Timestamp:</strong> " . date('Y-m-d H:i:s') . "</p>
            </div>
            
            <p><a href='/debug_php_framework.php'>→ Run Full Debug Script</a></p>
        </div>
    </body>
    </html>";
    
    // Log the error
    error_log("Framework Error: " . $e->getMessage() . " in " . $e->getFile() . ":" . $e->getLine());
}

// Framework class definition
class ModularFramework {
    private $config;
    private $db;
    private $currentPage;
    private $template;
    private $metadata;
    
    public function __construct() {
        $this->initializeLogging();
        $this->loadConfiguration();
    }
    
    public function handleRequest() {
        try {
            // Parse the requested page
            $this->currentPage = $this->parseRequest();
            
            // Load page metadata (from database first, then file fallback)
            $this->metadata = $this->loadPageMetadata($this->currentPage);
            
            // Initialize template system
            $this->initializeTemplate($this->metadata);
            
            // Log page access (only if logger is available)
            if (class_exists('Logger')) {
                Logger::info("Page accessed: {$this->currentPage}", [
                    'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
                    'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'unknown',
                    'user_id' => class_exists('AuthManager') ? (AuthManager::getCurrentUser()['id'] ?? null) : null
                ]);
            }
            
            // Render the page
            $this->renderPage();
            
        } catch (Exception $e) {
            $this->handleError($e);
        }
    }
    
    private function loadConfiguration() {
        try {
            // Try to load from database first
            if (class_exists('ConfigManager')) {
                $this->config = [
                    'debug' => ConfigManager::getSetting('debug_mode', true),
                    'default_template' => ConfigManager::getSetting('default_template', 'template1'),
                    'site_name' => ConfigManager::getSetting('site_name', 'My Modular Site'),
                    'timezone' => ConfigManager::getSetting('timezone', 'America/New_York'),
                    'admin_email' => ConfigManager::getSetting('admin_email', 'admin@example.com')
                ];
            } else {
                throw new Exception("ConfigManager not available");
            }
            
            // Set timezone
            date_default_timezone_set($this->config['timezone']);
            
        } catch (Exception $e) {
            // Fallback configuration if database is not available
            $this->config = [
                'debug' => true,
                'default_template' => 'template1',
                'site_name' => 'My Modular Site',
                'timezone' => 'America/New_York',
                'admin_email' => 'admin@example.com'
            ];
            
            // Try to include traditional config.php as fallback
            $configPath = __DIR__ . '/conf/config.php';
            if (file_exists($configPath)) {
                include $configPath;
                if (isset($config) && is_array($config)) {
                    $this->config = array_merge($this->config, $config);
                }
            }
        }
    }
    
    private function parseRequest() {
        $page = isset($_GET['page']) ? $_GET['page'] : 'home';
        $page = $this->sanitizePage($page);
        
        // Check if page file exists
        if (!$this->pageExists($page)) {
            throw new Exception("Page not found: $page", 404);
        }
        
        return $page;
    }
    
    private function sanitizePage($page) {
        // Remove any directory traversal attempts
        $page = str_replace(['../', './'], '', $page);
        $page = preg_replace('/[^a-zA-Z0-9\/\-_]/', '', $page);
        return $page;
    }
    
    private function pageExists($page) {
        $pagePath = __DIR__ . "/pages/$page.php";
        if (file_exists($pagePath)) {
            return true;
        }
        
        // Check for index file in directory
        $dirPath = __DIR__ . "/pages/$page/index.php";
        return file_exists($dirPath);
    }
    
    private function loadPageMetadata($page) {
        $metadata = [
            'title' => 'Default Title',
            'description' => 'Default description',
            'keywords' => 'default, keywords',
            'template' => $this->config['default_template']
        ];
        
        // Try database first (if available)
        if (class_exists('PageMetaManager')) {
            try {
                $dbMeta = PageMetaManager::getPageMeta($page);
                if ($dbMeta) {
                    return $dbMeta;
                }
            } catch (Exception $e) {
                // Database not available, continue with file-based metadata
            }
        }
        
        // Fallback to file-based metadata
        $parts = explode('/', $page);
        $metaPath = __DIR__ . '/pages/' . $parts[0] . '/meta.php';
        
        if (file_exists($metaPath)) {
            $pageMeta = include $metaPath;
            if (is_array($pageMeta)) {
                $metadata = array_merge($metadata, $pageMeta);
            }
        }
        
        return $metadata;
    }
    
    private function initializeTemplate($metadata) {
        $templateName = $metadata['template'];
        
        // Try database template info (if available)
        if (class_exists('TemplateManager')) {
            try {
                $templateInfo = TemplateManager::getTemplate($templateName);
                if (!$templateInfo) {
                    $templateInfo = TemplateManager::getDefaultTemplate();
                    $templateName = $templateInfo['template_name'] ?? $templateName;
                }
            } catch (Exception $e) {
                // Database not available, continue with file-based templates
            }
        }
        
        $templatePath = __DIR__ . "/template/$templateName";
        
        if (!is_dir($templatePath)) {
            throw new Exception("Template directory not found: $templatePath");
        }
        
        $this->template = [
            'name' => $templateName,
            'path' => $templatePath,
            'metadata' => $metadata
        ];
    }
    
    private function renderPage() {
        // Start output buffering for the page content
        ob_start();
        
        // Include the actual page
        $pagePath = $this->getPagePath($this->currentPage);
        include $pagePath;
        
        // Get the page content
        $pageContent = ob_get_clean();
        
        // Include the template layout
        $layoutPath = $this->template['path'] . '/layout.php';
        if (!file_exists($layoutPath)) {
            throw new Exception("Template layout not found: $layoutPath");
        }
        
        // Make framework available to template
        $framework = $this;
        include $layoutPath;
    }
    
    private function getPagePath($page) {
        $pagePath = __DIR__ . "/pages/$page.php";
        if (file_exists($pagePath)) {
            return $pagePath;
        }
        
        $dirPath = __DIR__ . "/pages/$page/index.php";
        if (file_exists($dirPath)) {
            return $dirPath;
        }
        
        throw new Exception("Page file not found: $page");
    }
    
    private function initializeLogging() {
        if ($this->config['debug'] ?? true) {
            ini_set('log_errors', 1);
            ini_set('error_log', __DIR__ . '/log/error.log');
            
            // Create log directory if it doesn't exist
            $logDir = __DIR__ . '/log';
            if (!is_dir($logDir)) {
                mkdir($logDir, 0755, true);
            }
        }
    }
    
    private function handleError($e) {
        $errorId = uniqid('err_');
        
        // Set appropriate HTTP status code
        $statusCode = $e->getCode() ?: 500;
        http_response_code($statusCode);
        
        // Log the error
        error_log("Framework Error [$errorId]: " . $e->getMessage() . " in " . $e->getFile() . ":" . $e->getLine());
        
        if ($this->config['debug'] ?? true) {
            echo "<!DOCTYPE html>
            <html>
            <head><title>Error $statusCode</title></head>
            <body style='font-family: Arial, sans-serif; margin: 40px;'>
                <h1>Error $statusCode</h1>
                <p><strong>Error ID:</strong> $errorId</p>
                <p><strong>Message:</strong> " . htmlspecialchars($e->getMessage()) . "</p>
                <p><strong>File:</strong> " . htmlspecialchars($e->getFile()) . ":" . $e->getLine() . "</p>
                <details>
                    <summary>Stack Trace</summary>
                    <pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>
                </details>
                <p><a href='/'>← Back to Home</a></p>
            </body>
            </html>";
        } else {
            $this->showErrorPage($statusCode, $errorId);
        }
    }
    
    private function showErrorPage($statusCode, $errorId) {
        $errorMessages = [
            404 => 'Page Not Found',
            403 => 'Access Forbidden',
            500 => 'Internal Server Error'
        ];
        
        $title = $errorMessages[$statusCode] ?? 'Error';
        
        echo "<!DOCTYPE html>
        <html lang='en'>
        <head>
            <meta charset='UTF-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1.0'>
            <title>$title - {$this->config['site_name']}</title>
        </head>
        <body style='font-family: Arial, sans-serif; margin: 40px; text-align: center;'>
            <h1>$title</h1>
            <p>We're sorry, but something went wrong.</p>
            <p><a href='/'>Return to Home</a></p>
            <div style='font-size: 12px; color: #666; margin-top: 20px;'>Error ID: $errorId</div>
        </body>
        </html>";
    }
    
    // Getter methods for use in templates
    public function getMetadata($key = null) {
        if ($key) {
            return isset($this->metadata[$key]) ? $this->metadata[$key] : '';
        }
        return $this->metadata;
    }
    
    public function getTemplatePath() {
        return $this->template['path'];
    }
    
    public function getTemplateUrl() {
        return str_replace(__DIR__, '', $this->template['path']);
    }
    
    public function getConfig($key = null) {
        if ($key) {
            return isset($this->config[$key]) ? $this->config[$key] : null;
        }
        return $this->config;
    }
}
?>