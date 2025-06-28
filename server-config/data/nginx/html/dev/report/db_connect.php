<?php
// db_connect.php - Corrected database name
function connectToDatabase() {
    $host = '10.20.2.34';
    $port = '3306';
    $username = 'n8nusr';
    $password = 'Rfvgtdswe!df543554';
    $database = 'db_n8n'; // Corrected database name
    
    try {
        // Attempt connection with corrected database name
        $dsn = "mysql:host=$host;port=$port;dbname=$database";
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
        ];
        
        $conn = new PDO($dsn, $username, $password, $options);
        return $conn;
    } catch(PDOException $e) {
        die("Connection failed: " . $e->getMessage());
    }
}
?>

