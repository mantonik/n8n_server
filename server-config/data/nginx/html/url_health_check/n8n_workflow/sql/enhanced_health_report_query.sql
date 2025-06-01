-- Enhanced health reports query with URL details
SELECT 
    hr.url_id,
    mu.name as site_name,
    mu.url,
    mu.priority,
    hr.status,
    hr.response_time_ms,
    hr.http_status_code,
    hr.error_message,
    hr.checked_at
FROM health_reports hr
JOIN monitored_urls mu ON hr.url_id = mu.id
ORDER BY hr.checked_at DESC 
LIMIT 10;

-- Even more detailed version with additional context
SELECT 
    hr.url_id,
    mu.name as site_name,
    mu.url,
    mu.priority,
    hr.status,
    hr.response_time_ms,
    hr.http_status_code,
    hr.error_message,
    hr.response_body_preview,
    hr.checked_at,
    mu.failure_threshold,
    mu.current_failure_count,
    CASE 
        WHEN hr.status = 'up' THEN '✅'
        WHEN hr.status = 'down' THEN '❌'
        WHEN hr.status = 'error' THEN '⚠️'
        WHEN hr.status = 'timeout' THEN '⏰'
        ELSE '❓'
    END as status_icon
FROM health_reports hr
JOIN monitored_urls mu ON hr.url_id = mu.id
ORDER BY hr.checked_at DESC 
LIMIT 10;

-- Health reports grouped by URL for summary view
SELECT 
    mu.name as site_name,
    mu.url,
    mu.priority,
    COUNT(*) as total_checks,
    SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) as successful_checks,
    ROUND(AVG(hr.response_time_ms), 2) as avg_response_time_ms,
    MAX(hr.checked_at) as last_checked,
    ROUND(
        (SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 
        2
    ) as uptime_percentage
FROM health_reports hr
JOIN monitored_urls mu ON hr.url_id = mu.id
WHERE hr.checked_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY hr.url_id, mu.name, mu.url, mu.priority
ORDER BY uptime_percentage ASC, mu.priority DESC;

-- Recent failures only
SELECT 
    hr.url_id,
    mu.name as site_name,
    mu.url,
    mu.priority,
    hr.status,
    hr.response_time_ms,
    hr.http_status_code,
    hr.error_message,
    hr.checked_at
FROM health_reports hr
JOIN monitored_urls mu ON hr.url_id = mu.id
WHERE hr.status IN ('down', 'error', 'timeout')
ORDER BY hr.checked_at DESC 
LIMIT 20;

-- Performance analysis - slowest sites
SELECT 
    mu.name as site_name,
    mu.url,
    AVG(hr.response_time_ms) as avg_response_time,
    MIN(hr.response_time_ms) as min_response_time,
    MAX(hr.response_time_ms) as max_response_time,
    COUNT(*) as total_checks,
    MAX(hr.checked_at) as last_checked
FROM health_reports hr
JOIN monitored_urls mu ON hr.url_id = mu.id
WHERE hr.status = 'up' 
  AND hr.checked_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY hr.url_id, mu.name, mu.url
ORDER BY avg_response_time DESC
LIMIT 10;