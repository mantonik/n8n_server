<?php
// ========================================
// index.php - Framework with Fixed Metadata Loading
// Version: 1.0.5
// Created: 2025-07-02
// Framework: PHP Modular Development Framework
// Purpose: Framework with bulletproof metadata loading
// ========================================

error_reporting(E_ALL);
ini_set('display_errors', 1);
session_start();

// Include functions
require_once 'includes/functions.php';

// Define the framework class
class ModularFramework {
    private $config = [
        'debug' => true,
        'default_template' => 'template1',
        'site_name' => 'My Modular Site'
    ];
    
    private $metadata = [];
    
    public function handleRequest() {
        try {
            // Get requested page
            $page = isset($_GET['page']) ? $_GET['page'] : 'home';
            $page = $this->sanitizePage($page);
            
            // Load page metadata from centralized file
            $this->metadata = $this->loadPageMetadata($page);
            
            // Render the page
            $this->renderPage($page, $this->metadata);
            
        } catch (Exception $e) {
            $this->showError($e);
        }
    }
    
    private function sanitizePage($page) {
        $page = str_replace(['../', './'], '', $page);
        $page = preg_replace('/[^a-zA-Z0-9\/\-_]/', '', $page);
        return $page;
    }
    
    private function loadPageMetadata($page) {
        // Ensure page is a valid string
        if (empty($page) || !is_string($page)) {
            $page = 'home';
        }
        
        // Default metadata
        $metadata = [
            'title' => ucfirst($page) . ' - ' . $this->config['site_name'],
            'description' => 'A page on our modular PHP framework website',
            'keywords' => 'php, framework, modular',
            'template' => $this->config['default_template']
        ];
        
        // Try to load from centralized meta.php file
        $metaPath = __DIR__ . '/pages/meta.php';
        
        if (file_exists($metaPath)) {
            try {
                // Explicitly set the requested page variable for the meta file
                $requestedPage = $page;
                
                // Include the meta file and get the returned metadata
                $loadedMeta = include $metaPath;
                
                // If we got valid metadata, use it
                if (is_array($loadedMeta) && !empty($loadedMeta)) {
                    $metadata = $loadedMeta;
                }
            } catch (Exception $e) {
                // If there's an error loading metadata, just use defaults
                error_log("Error loading metadata for page '$page': " . $e->getMessage());
            }
        }
        
        return $metadata;
    }
    
    private function renderPage($page, $metadata) {
        // Find the page file
        $pagePath = $this->findPageFile($page);
        
        if (!$pagePath) {
            throw new Exception("Page not found: $page", 404);
        }
        
        // Make framework available to page files
        $framework = $this;
        
        // Get page content
        ob_start();
        include $pagePath;
        $pageContent = ob_get_clean();
        
        // Use template
        $templatePath = __DIR__ . '/template/' . $metadata['template'] . '/layout.php';
        
        if (file_exists($templatePath)) {
            // Make variables available to template (framework already set above)
            include $templatePath;
        } else {
            // Simple fallback if no template
            echo "<!DOCTYPE html><html><head><title>{$metadata['title']}</title></head><body>";
            echo "<h1>{$metadata['title']}</h1>";
            echo $pageContent;
            echo "</body></html>";
        }
    }
    
    private function findPageFile($page) {
        // Try direct file
        $pagePath = __DIR__ . "/pages/$page.php";
        if (file_exists($pagePath)) {
            return $pagePath;
        }
        
        // Try index in directory
        $dirPath = __DIR__ . "/pages/$page/index.php";
        if (file_exists($dirPath)) {
            return $dirPath;
        }
        
        // If page is 'home', try 'info' as fallback
        if ($page === 'home' && file_exists(__DIR__ . "/pages/info.php")) {
            return __DIR__ . "/pages/info.php";
        }
        
        return false;
    }
    
    private function showError($e) {
        $statusCode = $e->getCode() ?: 500;
        http_response_code($statusCode);
        
        echo "<!DOCTYPE html>
        <html>
        <head><title>Error $statusCode</title></head>
        <body style='font-family: Arial, sans-serif; margin: 40px;'>
            <h1>Error $statusCode</h1>
            <p><strong>Message:</strong> " . htmlspecialchars($e->getMessage()) . "</p>";
            
        if ($this->config['debug']) {
            echo "<p><strong>File:</strong> " . htmlspecialchars($e->getFile()) . ":" . $e->getLine() . "</p>";
            echo "<details><summary>Stack Trace</summary><pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre></details>";
        }
        
        echo "<p><a href='?'>← Back to Home</a></p>
        </body>
        </html>";
    }
    
    // Getter methods for templates
    public function getMetadata($key = null) {
        if ($key && isset($this->metadata[$key])) {
            return $this->metadata[$key];
        }
        return $this->metadata;
    }
    
    public function getTemplatePath() {
        return __DIR__ . '/template/' . ($this->metadata['template'] ?? 'template1');
    }
    
    public function getTemplateUrl() {
        return '/template/' . ($this->metadata['template'] ?? 'template1');
    }
    
    public function getConfig($key = null) {
        if ($key) {
            return $this->config[$key] ?? null;
        }
        return $this->config;
    }
}

// Create and run the framework
try {
    $framework = new ModularFramework();
    $framework->handleRequest();
} catch (Exception $e) {
    echo "Fatal Error: " . $e->getMessage();
}
?>