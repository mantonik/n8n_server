-- Current status of all monitored URLs
SELECT 
    mu.id as url_id,
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.last_status as current_status,
    mu.last_checked_at,
    mu.current_failure_count,
    mu.failure_threshold,
    mu.check_interval_minutes,
    CASE 
        WHEN mu.last_status = 'up' THEN '✅ UP'
        WHEN mu.last_status = 'down' THEN '❌ DOWN'
        WHEN mu.last_status = 'error' THEN '⚠️ ERROR'
        WHEN mu.last_status = 'timeout' THEN '⏰ TIMEOUT'
        WHEN mu.last_status = 'unknown' THEN '❓ UNKNOWN'
        ELSE '❓ NOT CHECKED'
    END as status_display,
    CASE 
        WHEN mu.last_checked_at IS NULL THEN '🔴 Never checked'
        WHEN mu.last_checked_at < DATE_SUB(NOW(), INTERVAL (mu.check_interval_minutes + 5) MINUTE) THEN '🟡 Overdue for check'
        ELSE '🟢 On schedule'
    END as check_status,
    CASE 
        WHEN mu.current_failure_count >= mu.failure_threshold THEN '🚨 ALERTING'
        WHEN mu.current_failure_count > 0 THEN '⚠️ FAILING'
        ELSE '✅ HEALTHY'
    END as health_status,
    mu.contact_person,
    mu.contact_email,
    mu.is_active
FROM monitored_urls mu
ORDER BY 
    mu.is_active DESC,
    FIELD(mu.priority, 'critical', 'high', 'normal', 'low'),
    mu.last_status DESC,
    mu.name;

-- Current status with latest response time and error details
SELECT 
    mu.id as url_id,
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.last_status as current_status,
    CASE 
        WHEN mu.last_status = 'up' THEN '✅'
        WHEN mu.last_status = 'down' THEN '❌'
        WHEN mu.last_status = 'error' THEN '⚠️'
        WHEN mu.last_status = 'timeout' THEN '⏰'
        ELSE '❓'
    END as status_icon,
    mu.last_checked_at,
    hr.response_time_ms as last_response_time,
    hr.http_status_code as last_http_code,
    hr.error_message as last_error,
    mu.current_failure_count,
    mu.failure_threshold,
    CONCAT(mu.current_failure_count, '/', mu.failure_threshold) as failure_count_display,
    CASE 
        WHEN mu.current_failure_count >= mu.failure_threshold THEN '🚨 ALERT ACTIVE'
        WHEN mu.current_failure_count > 0 THEN CONCAT('⚠️ ', mu.current_failure_count, ' failures')
        ELSE '✅ Healthy'
    END as alert_status
FROM monitored_urls mu
LEFT JOIN health_reports hr ON mu.id = hr.url_id AND hr.checked_at = mu.last_checked_at
ORDER BY 
    mu.is_active DESC,
    FIELD(mu.priority, 'critical', 'high', 'normal', 'low'),
    CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END,
    mu.current_failure_count DESC,
    mu.name;

-- Simplified current status - easy to read
SELECT 
    mu.name as site_name,
    mu.url,
    mu.priority,
    CASE 
        WHEN mu.last_status = 'up' THEN '✅ UP'
        WHEN mu.last_status = 'down' THEN '❌ DOWN'
        WHEN mu.last_status = 'error' THEN '⚠️ ERROR'
        WHEN mu.last_status = 'timeout' THEN '⏰ TIMEOUT'
        ELSE '❓ UNKNOWN'
    END as status,
    mu.last_checked_at,
    CASE 
        WHEN mu.current_failure_count >= mu.failure_threshold THEN '🚨 ALERTING'
        WHEN mu.current_failure_count > 0 THEN '⚠️ ISSUES'
        ELSE '✅ OK'
    END as health
FROM monitored_urls mu
WHERE mu.is_active = TRUE
ORDER BY 
    FIELD(mu.priority, 'critical', 'high', 'normal', 'low'),
    CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END,
    mu.name;

-- Current status with alert group information
SELECT 
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.last_status as status,
    mu.last_checked_at,
    mu.current_failure_count,
    mu.failure_threshold,
    CASE 
        WHEN mu.current_failure_count >= mu.failure_threshold THEN '🚨 ALERTING'
        WHEN mu.current_failure_count > 0 THEN '⚠️ DEGRADED'
        ELSE '✅ HEALTHY'
    END as health_status,
    GROUP_CONCAT(ag.group_name SEPARATOR ', ') as alert_groups,
    COUNT(DISTINCT agm.id) as total_alert_recipients
FROM monitored_urls mu
LEFT JOIN url_alert_groups uag ON mu.id = uag.url_id AND uag.is_active = TRUE
LEFT JOIN alert_groups ag ON uag.group_id = ag.id AND ag.is_active = TRUE
LEFT JOIN alert_group_members agm ON ag.id = agm.group_id AND agm.is_active = TRUE
WHERE mu.is_active = TRUE
GROUP BY mu.id, mu.name, mu.url, mu.priority, mu.last_status, mu.last_checked_at, mu.current_failure_count, mu.failure_threshold
ORDER BY 
    FIELD(mu.priority, 'critical', 'high', 'normal', 'low'),
    CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END,
    mu.name;

-- Dashboard summary - overview of all sites
SELECT 
    'OVERALL STATUS' as metric,
    COUNT(*) as total_sites,
    SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) as sites_up,
    SUM(CASE WHEN mu.last_status = 'down' THEN 1 ELSE 0 END) as sites_down,
    SUM(CASE WHEN mu.last_status = 'error' THEN 1 ELSE 0 END) as sites_error,
    SUM(CASE WHEN mu.last_status = 'timeout' THEN 1 ELSE 0 END) as sites_timeout,
    SUM(CASE WHEN mu.last_status = 'unknown' OR mu.last_status IS NULL THEN 1 ELSE 0 END) as sites_unknown,
    SUM(CASE WHEN mu.current_failure_count >= mu.failure_threshold THEN 1 ELSE 0 END) as sites_alerting,
    ROUND(
        (SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 
        1
    ) as overall_uptime_percent
FROM monitored_urls mu 
WHERE mu.is_active = TRUE;

-- Critical sites status (priority-focused view)
SELECT 
    mu.name as site_name,
    mu.url,
    mu.priority,
    CASE 
        WHEN mu.last_status = 'up' THEN '✅ UP'
        WHEN mu.last_status = 'down' THEN '❌ DOWN'
        WHEN mu.last_status = 'error' THEN '⚠️ ERROR'
        WHEN mu.last_status = 'timeout' THEN '⏰ TIMEOUT'
        ELSE '❓ UNKNOWN'
    END as status,
    mu.last_checked_at,
    mu.current_failure_count,
    CASE 
        WHEN mu.current_failure_count >= mu.failure_threshold THEN '🚨 CRITICAL ALERT'
        WHEN mu.current_failure_count > 0 AND mu.priority = 'critical' THEN '⚠️ CRITICAL DEGRADED'
        WHEN mu.current_failure_count > 0 THEN '⚠️ DEGRADED'
        ELSE '✅ HEALTHY'
    END as alert_level
FROM monitored_urls mu
WHERE mu.is_active = TRUE 
  AND (mu.priority IN ('critical', 'high') OR mu.current_failure_count > 0)
ORDER BY 
    FIELD(mu.priority, 'critical', 'high', 'normal', 'low'),
    mu.current_failure_count DESC,
    mu.name;