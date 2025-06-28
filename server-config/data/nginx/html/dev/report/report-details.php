<?php
// Display errors for debugging
/*
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
*/

// report_details.php - Details for each test run
require_once('db_connect.php');

// Check if session_id is provided
if (!isset($_GET['session_id']) || empty($_GET['session_id'])) {
    die("Error: No session ID provided");
}

$sessionId = $_GET['session_id'];

// Connect to database
$conn = connectToDatabase();

// Get the report title and other metadata from the first record
$metadataSql = "SELECT 
            r.created_date as report_date,
            r.rep_data as rep_data_json
        FROM 
            p_n8n_report r
        where 
            topic like 'Title'
            and session_id = :session_id";

$metadataStmt = $conn->prepare($metadataSql);
$metadataStmt->bindParam(':session_id', $sessionId);
$metadataStmt->execute();
$metadata = $metadataStmt->fetch(PDO::FETCH_ASSOC);

// Parse the metadata
$metadataJson = json_decode($metadata['rep_data_json'] ?? '{}', true);
$reportTitle = $metadataJson['ReportTitle'] ?? 'N/A';
$env = $metadataJson['env'] ?? 'N/A';
$url = $metadataJson['URL'] ?? 'N/A';
$userEmail = $metadataJson['userEmail'] ?? 'N/A';

// Query to get all records for this session_id
$sql = "SELECT 
            id,
            created_date, 
            topic, 
            rep_data, 
            status,
            CONVERT(request USING utf8) as request_text, 
            CONVERT(response USING utf8) as response_text,
            error, 
            notes
        FROM 
            p_n8n_report
        WHERE 
            session_id = :session_id
        ORDER BY 
            id asc";

$stmt = $conn->prepare($sql);
$stmt->bindParam(':session_id', $sessionId);
$stmt->execute();
$details = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Function to format JSON with syntax highlighting
function formatJson($data) {
    if (empty($data)) return 'None';
    
    // If it's already a JSON string, decode it first
    if (is_string($data)) {
        $decoded = json_decode($data, true);
        if (json_last_error() === JSON_ERROR_NONE) {
            $data = $decoded;
        } else {
            // If it's not valid JSON, return as plain text
            return htmlspecialchars($data);
        }
    }
    
    // If it's not an array or object, return as is
    if (!is_array($data) && !is_object($data)) {
        return htmlspecialchars($data);
    }
    
    // Convert to JSON with pretty print
    $json = json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    if ($json === false) {
        return 'Invalid JSON data';
    }
    
    // Add syntax highlighting
    $json = htmlspecialchars($json);
    $json = preg_replace('/"([^"]+)":/', '<span class="json-key">"$1"</span>:', $json);
    $json = preg_replace('/:\s*"(.*?)"/', ': <span class="json-string">"$1"</span>', $json);
    $json = preg_replace('/:\s*([0-9]+(\.[0-9]+)?)/', ': <span class="json-number">$1</span>', $json);
    $json = preg_replace('/:\s*(true|false)/', ': <span class="json-boolean">$1</span>', $json);
    $json = preg_replace('/:\s*null/', ': <span class="json-null">null</span>', $json);
    
    return $json;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Report Details: <?php echo htmlspecialchars($reportTitle); ?></title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            overflow-x: hidden;
        }
        .header {
            margin-bottom: 20px;
        }
        .report-info {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .report-info p {
            margin: 5px 0;
        }
        .table-container {
            width: 100%;
            overflow-x: auto;
            margin-top: 20px;
            border: 1px solid #ddd;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
            vertical-align: top;
            word-wrap: break-word;
        }
        th {
            background-color: #f2f2f2;
            position: sticky;
            top: 0;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .success {
            color: green;
            font-weight: bold;
        }
        .failed {
            color: red;
            font-weight: bold;
        }
        .json-container {
            max-height: 300px;
            overflow-y: auto;
            background: #f8f8f8;
            border-radius: 4px;
            padding: 8px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            line-height: 1.4;
            white-space: pre-wrap;
        }
        .json-key {
            color: #d63384;
        }
        .json-string {
            color: #20a020;
        }
        .json-number {
            color: #2080e0;
        }
        .json-boolean {
            color: #2080e0;
        }
        .json-null {
            color: #808080;
        }
        .back-link {
            margin-bottom: 20px;
            display: inline-block;
        }
        
        /* Column width adjustments */
        th:nth-child(1), td:nth-child(1) { 
            width: 120px;
            white-space: normal;
        }
        th:nth-child(2), td:nth-child(2) { 
            width: 4%;
            max-width: 100px;
        }
        th:nth-child(3), td:nth-child(3) { 
            width: 10%;
        }
        th:nth-child(4), td:nth-child(4) { 
            width: 80px;
        }
        th:nth-child(5), td:nth-child(5) { 
            width: 35%;
        }
        th:nth-child(6), td:nth-child(6) { 
            width: 45%;
        }
        
        .date-time-cell {
            display: flex;
            flex-direction: column;
            line-height: 1.3;
        }
        
        @media (max-width: 768px) {
            th:nth-child(1), td:nth-child(1) { width: 100px; }
            th:nth-child(2), td:nth-child(2) { width: 15%; }
            th:nth-child(3), td:nth-child(3) { width: 15%; }
            th:nth-child(4), td:nth-child(4) { width: 70px; }
            th:nth-child(5), td:nth-child(5) { width: 25%; }
            th:nth-child(6), td:nth-child(6) { width: 30%; }
        }
    </style>
</head>
<body>
    <a href="report-list.php" class="back-link">← Back to Reports List</a>
    
    <div class="header">
        <h1>Report Details: <?php echo htmlspecialchars($reportTitle); ?></h1>
    </div>
    
    <div class="report-info">
        <p><strong>Session ID:</strong> <?php echo htmlspecialchars($sessionId); ?></p>
        <p><strong>Environment:</strong> <?php echo htmlspecialchars($env); ?></p>
        <p><strong>URL:</strong> <?php echo htmlspecialchars($url); ?></p>
        <p><strong>User Email:</strong> <?php echo htmlspecialchars($userEmail); ?></p>
    </div>
    
    <h2>Test Run Details</h2>
    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>Date/Time</th>
                    <th>Topic</th>
                    <th>Action Data</th>
                    <th>Status</th>
                    <th>Request</th>
                    <th>Response</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($details as $detail): ?>
                    <?php
                    // Parse JSON data
                    $topicData = $detail['topic'];
                    $repData = $detail['rep_data'];
                    
                    // Format the date
                    $utcDate = new DateTime($detail['created_date'], new DateTimeZone('UTC'));
                    $utcDate->setTimezone(new DateTimeZone('America/New_York'));
                    $formattedDate = $utcDate->format('Y-m-d H:i:s');
                    
                    // Split the formatted date into date and time parts
                    $dateTimeParts = explode(' ', $formattedDate);
                    $datePart = $dateTimeParts[0] ?? '';
                    $timePart = $dateTimeParts[1] ?? '';
                    
                    // Determine status class
                    $statusClass = ($detail['status'] == 0 || $detail['status'] == 80) ? 'success' : 'failed';
                    $statusText = ($detail['status'] == 0 || $detail['status'] == 80) ? 'Success' : 'Failed (' . $detail['status'] . ')';
                    ?>
                    <tr>
                        <td class="date-time-cell">
                            <span><?php echo htmlspecialchars($datePart); ?></span>
                            <span><?php echo htmlspecialchars($timePart); ?></span>
                        </td>
                        <td>
                            <div class="json-container"><?php echo formatJson($topicData); ?></div>
                        </td>
                        <td>
                            <div class="json-container"><?php echo formatJson($repData); ?></div>
                        </td>
                        <td class="<?php echo $statusClass; ?>"><?php echo $statusText; ?></td>
                        <td>
                            <div class="json-container"><?php echo formatJson($detail['request_text'] ?? 'None'); ?></div>
                        </td>
                        <td>
                            <div class="json-container"><?php echo formatJson($detail['response_text'] ?? 'None'); ?></div>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</body>
</html>