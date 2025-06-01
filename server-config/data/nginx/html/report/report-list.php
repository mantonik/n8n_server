<?php

// Display errors for debugging
/*
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
*/
// report_list.php - List of reports page
require_once('db_connect.php');

// Connect to database
$conn = connectToDatabase();

// Query to get reports grouped by session_id
$sql = "SELECT 
            r.session_id, 
            r.created_date as report_date,
            r.rep_data as rep_data_json
        FROM 
            p_n8n_report r
        where 
            topic like 'Title'
            order by id desc ";

$stmt = $conn->prepare($sql);
$stmt->execute();
$reports = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>N8N Reports List</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
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
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        a {
            color: #0066cc;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        h1 {
            color: #333;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>N8N Reports List</h1>
    </div>
    
    <table>
        <thead>
            <tr>
                <th>Date of Run</th>
                <th>Report Title</th>
                <th>Environment</th>
                <th>URL</th>
                <th>User Email</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($reports as $report): ?>
                <?php
                // Parse the JSON in topic field
                $reportData = json_decode($report['rep_data_json'], true);
                
                // Set default values in case JSON parsing fails or fields are missing
                $reportTitle = isset($reportData['ReportTitle']) ? $reportData['ReportTitle'] : 'N/A';
                $env = isset($reportData['env']) ? $reportData['env'] : 'N/A';
                $url = isset($reportData['URL']) ? $reportData['URL'] : 'N/A';
                $userEmail = isset($reportData['userEmail']) ? $reportData['userEmail'] : 'N/A';
                
                // Format the date
                // Assuming $detail['report_date'] is in UTC
                $utcDate = new DateTime($report['report_date'], new DateTimeZone('UTC'));

                // Convert to Eastern Time (will be EST or EDT depending on the date)
                $utcDate->setTimezone(new DateTimeZone('America/New_York'));

                // Format the date in EST
                $formattedDate = $utcDate->format('Y-m-d H:i:s');
                // $formattedDate = date('Y-m-d H:i:s', strtotime($report['report_date']));
                ?>
                <tr>
                    <td><?php echo htmlspecialchars($formattedDate); ?></td>
                    <td>     
                        <a href="report-details.php?session_id=<?php echo urlencode($report['session_id']); ?>" target="_blank">
                            <?php echo htmlspecialchars($reportTitle); ?>
                        </a>
                    </td>
                    <td><?php echo htmlspecialchars($env); ?></td>
                    <td><?php echo htmlspecialchars($url); ?></td>
                    <td><?php echo htmlspecialchars($userEmail); ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</body>
</html>
