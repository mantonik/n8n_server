<?php
// ========================================
// index.php - Main Entry Point with Database Support
// Version: 1.0.0
// Created: 2025-07-01
// Framework: PHP Modular Development Framework
// Purpose: Main router for database-driven operations
// Database: dev_phpframework
// ========================================

session_start();

// Set error reporting based on debug mode
$debugMode = true; // Will be loaded from database
if ($debugMode) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}

// Include core files
require_once 'includes/functions.php';

// Initialize framework
$framework = new ModularFramework();
$framework->handleRequest();

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
            
            // Log page access
            Logger::info("Page accessed: {$this->currentPage}", [
                'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
                'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'unknown',
                'user_id' => AuthManager::getCurrentUser()['id'] ?? null
            ]);
            
            // Render the page
            $this->renderPage();
            
        } catch (Exception $e) {
            $this->handleError($e);
        }
    }
    
    private function loadConfiguration() {
        try {
            // Load basic configuration from database
            $this->config = [
                'debug' => ConfigManager::getSetting('debug_mode', true),
                'default_template' => ConfigManager::getSetting('default_template', 'template1'),
                'site_name' => ConfigManager::getSetting('site_name', 'My Modular Site'),
                'timezone' => ConfigManager::getSetting('timezone', 'America/New_York'),
                'admin_email' => ConfigManager::getSetting('admin_email', 'admin@example.com')
            ];
            
            // Set timezone
            date_default_timezone_set($this->config['timezone']);
            
        } catch (Exception $e) {
            // Fallback configuration if database is not available
            Logger::error("Failed to load configuration from database", ['error' => $e->getMessage()]);
            $this->config = [
                'debug' => true,
                'default_template' => 'template1',
                'site_name' => 'My Modular Site',
                'timezone' => 'America/New_York',
                'admin_email' => 'admin@example.com'
            ];
        }
    }
    
    private function parseRequest() {
        $page = isset($_GET['page']) ? $_GET['page'] : 'home';
        $page = $this->sanitizePage($page);
        
        // Check if page file exists
        if (!$this->pageExists($page)) {
            Logger::warning("Page not found: $page", [
                'requested_url' => $_SERVER['REQUEST_URI'] ?? '',
                'referer' => $_SERVER['HTTP_REFERER'] ?? ''
            ]);
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
        $pagePath = "pages/$page.php";
        if (file_exists($pagePath)) {
            return true;
        }
        
        // Check for index file in directory
        $dirPath = "pages/$page/index.php";
        return file_exists($dirPath);
    }
    
    private function loadPageMetadata($page) {
        // First try to load from database (c_page_meta table)
        $dbMeta = PageMetaManager::getPageMeta($page);
        
        if ($dbMeta) {
            return $dbMeta;
        }
        
        // Fallback to file-based metadata
        $metadata = [
            'title' => 'Default Title',
            'description' => 'Default description',
            'keywords' => 'default, keywords',
            'template' => $this->config['default_template']
        ];
        
        // Try to load meta.php from page directory
        $parts = explode('/', $page);
        $metaPath = 'pages/' . $parts[0] . '/meta.php';
        
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
        
        // Get template info from database
        $templateInfo = TemplateManager::getTemplate($templateName);
        
        if (!$templateInfo) {
            Logger::warning("Template not found in database: $templateName, using default");
            $templateInfo = TemplateManager::getDefaultTemplate();
            $templateName = $templateInfo['template_name'];
        }
        
        $templatePath = "template/$templateName";
        
        if (!is_dir($templatePath)) {
            throw new Exception("Template directory not found: $templatePath");
        }
        
        $this->template = [
            'name' => $templateName,
            'path' => $templatePath,
            'info' => $templateInfo,
            'config' => TemplateManager::getTemplateConfig($templateName),
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
        
        include $layoutPath;
    }
    
    private function getPagePath($page) {
        $pagePath = "pages/$page.php";
        if (file_exists($pagePath)) {
            return $pagePath;
        }
        
        $dirPath = "pages/$page/index.php";
        if (file_exists($dirPath)) {
            return $dirPath;
        }
        
        throw new Exception("Page file not found: $page");
    }
    
    private function initializeLogging() {
        if ($this->config['debug'] ?? true) {
            ini_set('log_errors', 1);
            ini_set('error_log', 'log/error.log');
        }
    }
    
    private function handleError($e) {
        $errorId = uniqid('err_');
        
        // Log detailed error
        Logger::error("Framework Error [$errorId]: " . $e->getMessage(), [
            'error_id' => $errorId,
            'file' => $e->getFile(),
            'line' => $e->getLine(),
            'trace' => $e->getTraceAsString(),
            'url' => $_SERVER['REQUEST_URI'] ?? '',
            'method' => $_SERVER['REQUEST_METHOD'] ?? '',
            'user_id' => AuthManager::getCurrentUser()['id'] ?? null
        ]);
        
        // Set appropriate HTTP status code
        $statusCode = $e->getCode() ?: 500;
        http_response_code($statusCode);
        
        if ($this->config['debug'] ?? true) {
            echo "<h1>Error {$statusCode}</h1>";
            echo "<p><strong>Error ID:</strong> $errorId</p>";
            echo "<p><strong>Message:</strong> {$e->getMessage()}</p>";
            echo "<p><strong>File:</strong> {$e->getFile()}:{$e->getLine()}</p>";
            echo "<pre><strong>Trace:</strong>\n{$e->getTraceAsString()}</pre>";
        } else {
            // Show user-friendly error page
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
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; text-align: center; }
                .error-container { max-width: 600px; margin: 0 auto; }
                h1 { color: #dc3545; }
                .error-id { font-size: 12px; color: #6c757d; margin-top: 20px; }
            </style>
        </head>
        <body>
            <div class='error-container'>
                <h1>$title</h1>
                <p>We're sorry, but something went wrong.</p>
                <p><a href='?'>Return to Home</a></p>
                <div class='error-id'>Error ID: $errorId</div>
            </div>
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
        return $this->template['path'];
    }
    
    public function getTemplateConfig($key = null) {
        if ($key) {
            return isset($this->template['config'][$key]) ? $this->template['config'][$key] : null;
        }
        return $this->template['config'];
    }
    
    public function getConfig($key = null) {
        if ($key) {
            return isset($this->config[$key]) ? $this->config[$key] : null;
        }
        return $this->config;
    }
}
?>