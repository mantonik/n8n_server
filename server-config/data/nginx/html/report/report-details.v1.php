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
// $metadataSql = "SELECT * FROM p_n8n_report WHERE session_id = :session_id LIMIT 1";
$metadataSql ="SELECT 
            r.created_date as report_date,
            r.rep_data as rep_data_json
        FROM 
            p_n8n_report r
        where 
            topic like 'Title'
            and session_id = :session_id
            ";

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
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
            vertical-align: top;
        }
        th {
            background-color: #f2f2f2;
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
                // Assuming $detail['created_date'] is in UTC
                $utcDate = new DateTime($detail['created_date'], new DateTimeZone('UTC'));

                // Convert to Eastern Time (will be EST or EDT depending on the date)
                $utcDate->setTimezone(new DateTimeZone('America/New_York'));

                // Format the date in EST
                $formattedDate = $utcDate->format('Y-m-d H:i:s');
                //$formattedDate = date('Y-m-d H:i:s', strtotime($detail['created_date']));
                
                // Determine status class
                //$statusClass = ($detail['status'] == 0) ? 'success' : 'failed';
                //$statusText = ($detail['status'] == 0) ? 'Success' : 'Failed (' . $detail['status'] . ')';
				// Determine status class
				$statusClass = ($detail['status'] == 0 || $detail['status'] == 80) ? 'success' : 'failed';
				$statusText = ($detail['status'] == 0 || $detail['status'] == 80) ? 'Success' : 'Failed (' . $detail['status'] . ')';

                
                // Get action from rep_data if available
                $action = isset($repData['action']) ? $repData['action'] : 'N/A';
                $statusMsg = isset($repData['status_msg']) ? $repData['status_msg'] : 'N/A';
                ?>
                <tr>
                    <td><?php echo htmlspecialchars($formattedDate); ?></td>
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
                    <td><?php echo htmlspecialchars($detail['request_text'] ?? 'None'); ?></td>
                    <td><?php echo htmlspecialchars($detail['response_text'] ?? 'None'); ?></td>
                    
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</body>
</html>
