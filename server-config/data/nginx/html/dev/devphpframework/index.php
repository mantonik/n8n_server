<?php
// ========================================
// htdocs/index.php - Main Entry Point
// ========================================

session_start();
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Include core files
require_once 'includes/functions.php';
require_once 'conf/config.php';

// Initialize framework
$framework = new ModularFramework();
$framework->handleRequest();

class ModularFramework {
    private $config;
    private $db;
    private $currentPage;
    private $template;
    
    public function __construct() {
        global $config;
        $this->config = $config;
        $this->initializeLogging();
    }
    
    public function handleRequest() {
        try {
            // Parse the requested page
            $this->currentPage = $this->parseRequest();
            
            // Load page metadata
            $metadata = $this->loadPageMetadata($this->currentPage);
            
            // Initialize template system
            $this->initializeTemplate($metadata);
            
            // Render the page
            $this->renderPage();
            
        } catch (Exception $e) {
            $this->handleError($e);
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
        $pagePath = "pages/$page.php";
        if (file_exists($pagePath)) {
            return true;
        }
        
        // Check for index file in directory
        $dirPath = "pages/$page/index.php";
        return file_exists($dirPath);
    }
    
    private function loadPageMetadata($page) {
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
        $templatePath = "template/$templateName";
        
        if (!is_dir($templatePath)) {
            throw new Exception("Template not found: $templateName");
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
        if ($this->config['debug']) {
            ini_set('log_errors', 1);
            ini_set('error_log', 'log/error.log');
        }
    }
    
    private function handleError($e) {
        if ($this->config['debug']) {
            echo "<h1>Error {$e->getCode()}</h1>";
            echo "<p>{$e->getMessage()}</p>";
            echo "<pre>{$e->getTraceAsString()}</pre>";
        } else {
            // Show user-friendly error page
            http_response_code($e->getCode() ?: 500);
            echo "<h1>Something went wrong</h1>";
            echo "<p>Please try again later.</p>";
        }
        
        // Log the error
        error_log("Framework Error: " . $e->getMessage() . " in " . $e->getFile() . ":" . $e->getLine());
    }
    
    // Getter methods for use in templates
    public function getMetadata($key = null) {
        if ($key) {
            return isset($this->template['metadata'][$key]) ? $this->template['metadata'][$key] : '';
        }
        return $this->template['metadata'];
    }
    
    public function getTemplatePath() {
        return $this->template['path'];
    }
    
    public function getTemplateUrl() {
        return $this->template['path'];
    }
}