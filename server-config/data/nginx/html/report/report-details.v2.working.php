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
        .json-content {
            white-space: pre-wrap;
            font-family: monospace;
            background-color: #f8f8f8;
            padding: 5px;
            border-radius: 3px;
            max-height: 200px;
            overflow-y: auto;
        }
        .back-link {
            margin-bottom: 20px;
            display: inline-block;
        }
        
        /* Updated Column width adjustments */
        th:nth-child(1), td:nth-child(1) { 
            width: 120px;  /* Static width for Date/Time */
            white-space: normal; /* Allow text to wrap */
        }
        th:nth-child(2), td:nth-child(2) { 
            width: 4%; /* Reduced Topic column */
            max-width: 100px; /* Prevent from getting too wide */
        }
        th:nth-child(3), td:nth-child(3) { 
            width: 10%; /* Action Data */
        }
        th:nth-child(4), td:nth-child(4) { 
            width: 80px;  /* Static width for Status */
        }
        th:nth-child(5), td:nth-child(5) { 
            width: 35%; /* Increased Request column */
        }
        th:nth-child(6), td:nth-child(6) { 
            width: 45%; /* Increased Response column */
        }
        
        /* Date/Time formatting */
        .date-time-cell {
            display: flex;
            flex-direction: column;
            line-height: 1.3;
        }
        
        @media (max-width: 768px) {
            /* Adjust for smaller screens */
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
                    $topicData = json_decode($detail['topic'], true);
                    $repData = json_decode($detail['rep_data'], true);
                    
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
                            <?php if (is_array($topicData)): ?>
                                <div class="json-content"><?php echo htmlspecialchars(json_encode($topicData, JSON_PRETTY_PRINT)); ?></div>
                            <?php else: ?>
                                <?php echo htmlspecialchars($detail['topic']); ?>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if (is_array($repData)): ?>
                                <div class="json-content"><?php echo htmlspecialchars(json_encode($repData, JSON_PRETTY_PRINT)); ?></div>
                            <?php else: ?>
                                <?php echo htmlspecialchars($detail['rep_data']); ?>
                            <?php endif; ?>
                        </td>
                        <td class="<?php echo $statusClass; ?>"><?php echo $statusText; ?></td>
                        <td>
                            <div class="json-content"><?php echo htmlspecialchars($detail['request_text'] ?? 'None'); ?></div>
                        </td>
                        <td>
                            <div class="json-content"><?php echo htmlspecialchars($detail['response_text'] ?? 'None'); ?></div>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</body>
</html>