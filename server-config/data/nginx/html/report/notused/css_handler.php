<?php
// css_handler.php
header('Content-Type: text/css');

// Check if file exists
$cssFile = __DIR__ . '/style.css';
if (file_exists($cssFile)) {
    readfile($cssFile);
} else {
    header("HTTP/1.0 404 Not Found");
    echo "/* CSS file not found */";
}
?>