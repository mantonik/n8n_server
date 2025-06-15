-- =====================================================
-- COMPREHENSIVE REPORTING QUERIES FOR WEBSITE DASHBOARD
-- =====================================================
-- These queries provide the foundation for a complete monitoring dashboard website

-- =====================================================
-- 1. REAL-TIME DASHBOARD METRICS
-- =====================================================

-- Main Dashboard Overview (Real-time stats)
-- Usage: Homepage hero section, system status widget
SELECT 
    total_sites,
    sites_up,
    sites_down,
    sites_error,
    sites_timeout,
    sites_unknown,
    sites_alerting,
    critical_sites_down,
    overall_uptime_percent,
    ssl_monitored_sites,
    ssl_expiring_soon,
    CASE 
        WHEN critical_sites_down > 0 THEN '🔴 Critical Issues'
        WHEN sites_alerting > 0 THEN '🟡 Some Issues'
        WHEN overall_uptime_percent >= 99.5 THEN '🟢 All Systems Operational'
        ELSE '🟠 Degraded Performance'
    END as system_status,
    CASE 
        WHEN critical_sites_down > 0 THEN 'critical'
        WHEN sites_alerting > 0 THEN 'warning'
        WHEN overall_uptime_percent >= 99.5 THEN 'operational'
        ELSE 'degraded'
    END as status_level,
    last_system_check,
    report_generated_at
FROM dashboard_overview;

-- =====================================================
-- 2. CURRENT STATUS - DETAILED VIEW
-- =====================================================

-- All Sites Current Status (Main status page)
-- Usage: Primary status page showing all monitored services
SELECT 
    url_id,
    site_name,
    url,
    priority,
    team_name,
    status_display,
    health_status,
    check_status,
    performance_status,
    ssl_status,
    ssl_days_remaining,
    last_checked_at,
    last_response_time,
    last_http_code,
    last_error,
    failure_count_display,
    alert_groups_count,
    CASE 
        WHEN priority = 'critical' THEN 1
        WHEN priority = 'high' THEN 2
        WHEN priority = 'normal' THEN 3
        ELSE 4
    END as priority_order
FROM url_status_detailed
ORDER BY 
    CASE WHEN current_status = 'up' THEN 1 ELSE 0 END,
    priority_order,
    current_failure_count DESC,
    site_name;

-- Critical Services Only (Priority view)
-- Usage: Executive dashboard, critical services widget
SELECT 
    site_name,
    url,
    status_display,
    health_status,
    last_checked_at,
    last_response_time,
    team_name,
    contact_person
FROM url_status_detailed
WHERE priority IN ('critical', 'high')
ORDER BY 
    CASE WHEN current_status = 'up' THEN 1 ELSE 0 END,
    FIELD(priority, 'critical', 'high'),
    current_failure_count DESC;

-- Services with Issues (Incident view)
-- Usage: Incidents page, alerts dashboard
SELECT 
    site_name,
    url,
    priority,
    team_name,
    contact_person,
    contact_email,
    status_display,
    health_status,
    last_error,
    current_failure_count,
    failure_threshold,
    last_checked_at,
    TIMESTAMPDIFF(MINUTE, last_checked_at, NOW()) as minutes_since_last_check
FROM url_status_detailed
WHERE current_status != 'up' OR current_failure_count > 0
ORDER BY 
    FIELD(priority, 'critical', 'high', 'normal', 'low'),
    current_failure_count DESC,
    last_checked_at DESC;

-- =====================================================
-- 3. PERFORMANCE ANALYTICS
-- =====================================================

-- Response Time Trends (Last 24 Hours)
-- Usage: Performance trends chart, response time analytics
SELECT 
    mu.name as site_name,
    mu.url,
    mu.priority,
    DATE_FORMAT(hr.checked_at, '%Y-%m-%d %H:00:00') as hour_bucket,
    COUNT(*) as total_checks,
    ROUND(AVG(hr.response_time_ms), 2) as avg_response_time,
    ROUND(MIN(hr.response_time_ms), 2) as min_response_time,
    ROUND(MAX(hr.response_time_ms), 2) as max_response_time,
    SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) as successful_checks,
    ROUND((SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as success_rate
FROM health_reports hr
JOIN monitored_urls mu ON hr.url_id = mu.id
WHERE hr.checked_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)
  AND mu.is_active = TRUE
GROUP BY mu.id, mu.name, mu.url, mu.priority, hour_bucket
ORDER BY mu.name, hour_bucket;

-- Slowest Services (Performance ranking)
-- Usage: Performance optimization dashboard
SELECT 
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.team_name,
    ROUND(AVG(hr.response_time_ms), 2) as avg_response_time_7d,
    ROUND(MIN(hr.response_time_ms), 2) as min_response_time_7d,
    ROUND(MAX(hr.response_time_ms), 2) as max_response_time_7d,
    COUNT(*) as total_checks_7d,
    mu.response_time_warning_ms,
    mu.response_time_critical_ms,
    CASE 
        WHEN AVG(hr.response_time_ms) <= mu.response_time_warning_ms THEN '🟢 Good'
        WHEN AVG(hr.response_time_ms) <= mu.response_time_critical_ms THEN '🟡 Warning'
        ELSE '🔴 Critical'
    END as performance_classification
FROM health_reports hr
JOIN monitored_urls mu ON hr.url_id = mu.id
WHERE hr.checked_at > DATE_SUB(NOW(), INTERVAL 7 DAY)
  AND hr.status = 'up'
  AND mu.is_active = TRUE
GROUP BY mu.id, mu.name, mu.url, mu.priority, mu.team_name, mu.response_time_warning_ms, mu.response_time_critical_ms
HAVING COUNT(*) >= 10  -- Only include services with sufficient data
ORDER BY avg_response_time_7d DESC
LIMIT 20;

-- =====================================================
-- 4. SLA AND UPTIME REPORTS
-- =====================================================

-- 30-Day SLA Report (Comprehensive uptime analysis)
-- Usage: SLA reports page, monthly reviews
SELECT 
    site_name,
    url,
    priority,
    team_name,
    total_checks,
    successful_checks,
    down_checks,
    error_checks,
    timeout_checks,
    uptime_sla_percent,
    sla_grade,
    avg_response_time_ms,
    min_response_time_ms,
    max_response_time_ms,
    last_check_time,
    last_incident_time,
    CASE 
        WHEN last_incident_time IS NOT NULL 
        THEN TIMESTAMPDIFF(HOUR, last_incident_time, NOW())
        ELSE NULL
    END as hours_since_last_incident,
    report_start_date,
    report_end_date
FROM sla_report_30day
ORDER BY uptime_sla_percent ASC, priority DESC;

-- SLA Summary by Priority
-- Usage: Executive summary, priority-based reporting
SELECT 
    priority,
    COUNT(*) as total_services,
    ROUND(AVG(uptime_sla_percent), 2) as avg_uptime_sla,
    ROUND(MIN(uptime_sla_percent), 2) as worst_uptime_sla,
    ROUND(MAX(uptime_sla_percent), 2) as best_uptime_sla,
    SUM(CASE WHEN uptime_sla_percent >= 99.9 THEN 1 ELSE 0 END) as excellent_count,
    SUM(CASE WHEN uptime_sla_percent >= 99.5 AND uptime_sla_percent < 99.9 THEN 1 ELSE 0 END) as good_count,
    SUM(CASE WHEN uptime_sla_percent >= 99.0 AND uptime_sla_percent < 99.5 THEN 1 ELSE 0 END) as fair_count,
    SUM(CASE WHEN uptime_sla_percent < 99.0 THEN 1 ELSE 0 END) as poor_count,
    ROUND(AVG(avg_response_time_ms), 2) as avg_performance
FROM sla_report_30day
GROUP BY priority
ORDER BY FIELD(priority, 'critical', 'high', 'normal', 'low');

-- =====================================================
-- 5. SSL CERTIFICATE MONITORING
-- =====================================================

-- SSL Certificate Status Overview
-- Usage: Security dashboard, SSL monitoring page
SELECT 
    site_name,
    url,
    priority,
    team_name,
    contact_email,
    ssl_status_display,
    expiry_date,
    days_until_expiry,
    ssl_issuer,
    alert_configuration,
    CASE 
        WHEN days_until_expiry IS NULL THEN 999
        ELSE days_until_expiry
    END as sort_days
FROM ssl_certificate_status
ORDER BY 
    CASE WHEN monitoring_enabled = TRUE THEN 0 ELSE 1 END,
    sort_days ASC,
    FIELD(priority, 'critical', 'high', 'normal', 'low'),
    site_name;

-- SSL Certificates Expiring Soon (Alert dashboard)
-- Usage: SSL alerts, urgent action items
SELECT 
    site_name,
    url,
    priority,
    team_name,
    contact_email,
    expiry_date,
    days_until_expiry,
    ssl_issuer,
    CASE 
        WHEN days_until_expiry <= 0 THEN '🔴 EXPIRED'
        WHEN days_until_expiry <= 7 THEN '🔴 Critical (≤7 days)'
        WHEN days_until_expiry <= 30 THEN '🟡 Warning (≤30 days)'
        ELSE '🟢 OK'
    END as urgency_level,
    CASE 
        WHEN days_until_expiry <= 0 THEN 'expired'
        WHEN days_until_expiry <= 7 THEN 'critical'
        WHEN days_until_expiry <= 30 THEN 'warning'
        ELSE 'ok'
    END as urgency_class
FROM ssl_certificate_status
WHERE monitoring_enabled = TRUE 
  AND days_until_expiry IS NOT NULL 
  AND days_until_expiry <= 60
ORDER BY days_until_expiry ASC, FIELD(priority, 'critical', 'high', 'normal', 'low');

-- =====================================================
-- 6. TEAM PERFORMANCE REPORTS
-- =====================================================

-- Team Performance Dashboard
-- Usage: Team management, organizational reporting
SELECT 
    team_name,
    total_sites,
    sites_up,
    sites_down,
    sites_error,
    sites_timeout,
    team_health_score,
    team_avg_uptime_30d,
    team_avg_response_time_7d,
    team_alerts_7d,
    critical_sites,
    high_sites,
    normal_sites,
    low_sites,
    CASE 
        WHEN team_health_score >= 95 THEN '🟢 Excellent'
        WHEN team_health_score >= 90 THEN '🟡 Good'
        WHEN team_health_score >= 80 THEN '🟠 Fair'
        ELSE '🔴 Needs Attention'
    END as team_status,
    CASE 
        WHEN team_health_score >= 95 THEN 'excellent'
        WHEN team_health_score >= 90 THEN 'good'
        WHEN team_health_score >= 80 THEN 'fair'
        ELSE 'poor'
    END as team_status_class
FROM team_performance_summary
ORDER BY team_health_score DESC;

-- Team Detailed Breakdown
-- Usage: Detailed team analysis, drill-down reports
SELECT 
    t.team_name,
    t.team_health_score,
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.last_status,
    mu.current_failure_count,
    mu.failure_threshold,
    CASE 
        WHEN mu.last_status = 'up' THEN '✅'
        WHEN mu.last_status = 'down' THEN '❌'
        WHEN mu.last_status = 'error' THEN '⚠️'
        WHEN mu.last_status = 'timeout' THEN '⏰'
        ELSE '❓'
    END as status_icon,
    (SELECT COUNT(*) FROM alert_history ah 
     WHERE ah.url_id = mu.id 
     AND ah.sent_at > DATE_SUB(NOW(), INTERVAL 7 DAY)) as alerts_7d
FROM team_performance_summary t
JOIN monitored_urls mu ON COALESCE(mu.team_name, 'Unassigned') = t.team_name
WHERE mu.is_active = TRUE
ORDER BY t.team_health_score DESC, t.team_name, 
         CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END,
         FIELD(mu.priority, 'critical', 'high', 'normal', 'low');

-- =====================================================
-- 7. INCIDENT AND ALERT ANALYTICS
-- =====================================================

-- Recent Incidents Timeline (Last 48 Hours)
-- Usage: Incident timeline, recent activity feed
SELECT 
    incident_time,
    site_name,
    url,
    priority,
    team_name,
    incident_type,
    incident_description,
    response_time_ms,
    http_status_code,
    error_message,
    outage_duration_minutes,
    alerts_sent,
    CASE 
        WHEN incident_type = 'down' THEN 'danger'
        WHEN incident_type = 'error' THEN 'warning'
        WHEN incident_type = 'timeout' THEN 'warning'
        WHEN incident_description LIKE '%Recovered%' THEN 'success'
        ELSE 'info'
    END as incident_class,
    CASE 
        WHEN outage_duration_minutes IS NOT NULL THEN 
            CONCAT(outage_duration_minutes, ' minutes')
        ELSE NULL
    END as outage_duration_display
FROM incident_timeline_48h
ORDER BY incident_time DESC;

-- Alert Volume Analysis (Last 7 Days)
-- Usage: Alert analytics, noise analysis
SELECT 
    DATE(ah.sent_at) as alert_date,
    COUNT(*) as total_alerts,
    COUNT(DISTINCT ah.url_id) as affected_sites,
    SUM(CASE WHEN ah.alert_type = 'down' THEN 1 ELSE 0 END) as down_alerts,
    SUM(CASE WHEN ah.alert_type = 'up' THEN 1 ELSE 0 END) as recovery_alerts,
    SUM(CASE WHEN ah.alert_type = 'error' THEN 1 ELSE 0 END) as error_alerts,
    SUM(CASE WHEN ah.alert_type = 'timeout' THEN 1 ELSE 0 END) as timeout_alerts,
    SUM(CASE WHEN ah.alert_type LIKE 'ssl_%' THEN 1 ELSE 0 END) as ssl_alerts,
    SUM(CASE WHEN ah.alert_type LIKE 'performance_%' THEN 1 ELSE 0 END) as performance_alerts,
    ROUND(AVG(CASE WHEN ah.success THEN 1.0 ELSE 0.0 END) * 100, 2) as alert_success_rate
FROM alert_history ah
WHERE ah.sent_at > DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(ah.sent_at)
ORDER BY alert_date DESC;

-- Most Problematic Services (Alert frequency)
-- Usage: Service reliability analysis, maintenance prioritization
SELECT 
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.team_name,
    COUNT(ah.id) as total_alerts_30d,
    SUM(CASE WHEN ah.alert_type = 'down' THEN 1 ELSE 0 END) as down_alerts,
    SUM(CASE WHEN ah.alert_type = 'error' THEN 1 ELSE 0 END) as error_alerts,
    SUM(CASE WHEN ah.alert_type = 'timeout' THEN 1 ELSE 0 END) as timeout_alerts,
    MAX(ah.sent_at) as last_alert_time,
    ROUND(AVG(CASE WHEN ah.success THEN 1.0 ELSE 0.0 END) * 100, 2) as alert_delivery_rate,
    -- Calculate uptime from SLA report
    COALESCE((SELECT uptime_sla_percent FROM sla_report_30day s WHERE s.url_id = mu.id), 0) as uptime_30d
FROM monitored_urls mu
LEFT JOIN alert_history ah ON mu.id = ah.url_id 
    AND ah.sent_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
WHERE mu.is_active = TRUE
GROUP BY mu.id, mu.name, mu.url, mu.priority, mu.team_name
HAVING total_alerts_30d > 0
ORDER BY total_alerts_30d DESC, FIELD(mu.priority, 'critical', 'high', 'normal', 'low')
LIMIT 20;

-- =====================================================
-- 8. EXECUTIVE DASHBOARD QUERIES
-- =====================================================

-- Executive Summary (High-level KPIs)
-- Usage: Executive dashboard, management reporting
SELECT 
    metric_category,
    total_monitored_sites,
    sites_operational,
    sites_in_alert,
    critical_sites_down,
    overall_sla_30d,
    critical_sla_30d,
    avg_response_time_30d,
    alerts_24h,
    alerts_7d,
    ssl_monitored_sites,
    ssl_critical_sites,
    active_teams,
    report_generated_at,
    -- Calculate additional metrics
    ROUND((sites_operational * 100.0 / total_monitored_sites), 2) as operational_percentage,
    CASE 
        WHEN critical_sites_down > 0 THEN 'Critical Impact'
        WHEN sites_in_alert > 0 THEN 'Some Issues'
        WHEN overall_sla_30d >= 99.5 THEN 'Excellent Performance'
        ELSE 'Acceptable Performance'
    END as overall_health_summary
FROM executive_dashboard;

-- Service Availability by Priority (Executive view)
-- Usage: Priority-based reporting for executives
SELECT 
    priority,
    COUNT(*) as total_services,
    SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) as operational_services,
    ROUND((SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as availability_percent,
    SUM(CASE WHEN mu.current_failure_count >= mu.failure_threshold THEN 1 ELSE 0 END) as services_in_alert,
    -- Get average SLA for this priority level
    COALESCE((SELECT ROUND(AVG(uptime_sla_percent), 2) 
              FROM sla_report_30day s 
              WHERE s.priority = mu.priority), 0) as avg_sla_30d,
    CASE 
        WHEN priority = 'critical' AND 
             (SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) < 100 
             THEN '🔴 Critical Impact'
        WHEN (SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) >= 99 
             THEN '🟢 Healthy'
        ELSE '🟡 Some Issues'
    END as status_summary
FROM monitored_urls mu
WHERE mu.is_active = TRUE
GROUP BY priority
ORDER BY FIELD(priority, 'critical', 'high', 'normal', 'low');

-- =====================================================
-- 9. HISTORICAL TRENDS AND ANALYTICS
-- =====================================================

-- Weekly Uptime Trends (Last 8 Weeks)
-- Usage: Trend analysis, historical performance
SELECT 
    YEARWEEK(hr.checked_at, 1) as week_number,
    DATE(DATE_SUB(hr.checked_at, INTERVAL WEEKDAY(hr.checked_at) DAY)) as week_start,
    mu.priority,
    COUNT(*) as total_checks,
    SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) as successful_checks,
    ROUND((SUM(CASE WHEN hr.status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as weekly_uptime,
    ROUND(AVG(CASE WHEN hr.status = 'up' THEN hr.response_time_ms END), 2) as avg_response_time
FROM health_reports hr
JOIN monitored_urls mu ON hr.url_id = mu.id
WHERE hr.checked_at > DATE_SUB(NOW(), INTERVAL 8 WEEK)
  AND mu.is_active = TRUE
GROUP BY week_number, week_start, mu.priority
ORDER BY week_start DESC, FIELD(mu.priority, 'critical', 'high', 'normal', 'low');

-- Monthly Incident Summary (Last 6 Months)
-- Usage: Monthly reports, trend analysis
SELECT 
    DATE_FORMAT(ah.sent_at, '%Y-%m') as month_period,
    COUNT(DISTINCT ah.url_id) as affected_services,
    COUNT(*) as total_incidents,
    SUM(CASE WHEN ah.alert_type = 'down' THEN 1 ELSE 0 END) as downtime_incidents,
    SUM(CASE WHEN ah.alert_type = 'error' THEN 1 ELSE 0 END) as error_incidents,
    SUM(CASE WHEN ah.alert_type = 'timeout' THEN 1 ELSE 0 END) as timeout_incidents,
    SUM(CASE WHEN ah.severity = 'critical' THEN 1 ELSE 0 END) as critical_incidents,
    ROUND(AVG(CASE WHEN ah.success THEN 1.0 ELSE 0.0 END) * 100, 2) as alert_delivery_rate
FROM alert_history ah
WHERE ah.sent_at > DATE_SUB(NOW(), INTERVAL 6 MONTH)
  AND ah.alert_type IN ('down', 'error', 'timeout')
GROUP BY month_period
ORDER BY month_period DESC;

-- =====================================================
-- 10. OPERATIONAL DASHBOARDS
-- =====================================================

-- Service Health Matrix (Operations view)
-- Usage: NOC dashboard, operations center
SELECT 
    mu.team_name,
    mu.priority,
    COUNT(*) as total_services,
    SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) as up_count,
    SUM(CASE WHEN mu.last_status = 'down' THEN 1 ELSE 0 END) as down_count,
    SUM(CASE WHEN mu.last_status = 'error' THEN 1 ELSE 0 END) as error_count,
    SUM(CASE WHEN mu.last_status = 'timeout' THEN 1 ELSE 0 END) as timeout_count,
    SUM(CASE WHEN mu.current_failure_count >= mu.failure_threshold THEN 1 ELSE 0 END) as alerting_count,
    ROUND((SUM(CASE WHEN mu.last_status = 'up' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 1) as team_availability
FROM monitored_urls mu
WHERE mu.is_active = TRUE
GROUP BY mu.team_name, mu.priority
ORDER BY COALESCE(mu.team_name, 'ZZZ_Unassigned'), 
         FIELD(mu.priority, 'critical', 'high', 'normal', 'low');

-- Real-time Alert Queue (Operations dashboard)
-- Usage: Active incident management, real-time monitoring
SELECT 
    mu.name as site_name,
    mu.url,
    mu.priority,
    mu.team_name,
    mu.contact_person,
    mu.contact_email,
    mu.last_status,
    mu.current_failure_count,
    mu.failure_threshold,
    mu.last_checked_at,
    TIMESTAMPDIFF(MINUTE, mu.last_checked_at, NOW()) as minutes_since_check,
    hr.error_message as last_error,
    hr.response_time_ms as last_response_time,
    -- Calculate next check time
    DATE_ADD(mu.last_checked_at, INTERVAL mu.check_interval_minutes MINUTE) as next_check_due,
    CASE 
        WHEN mu.current_failure_count >= mu.failure_threshold THEN 'ALERTING'
        WHEN mu.current_failure_count > 0 THEN 'DEGRADED'
        WHEN TIMESTAMPDIFF(MINUTE, mu.last_checked_at, NOW()) > (mu.check_interval_minutes + 5) THEN 'OVERDUE'
        ELSE 'HEALTHY'
    END as operational_status,
    CASE 
        WHEN mu.current_failure_count >= mu.failure_threshold THEN 'danger'
        WHEN mu.current_failure_count > 0 THEN 'warning'
        WHEN TIMESTAMPDIFF(MINUTE, mu.last_checked_at, NOW()) > (mu.check_interval_minutes + 5) THEN 'info'
        ELSE 'success'
    END as status_class
FROM monitored_urls mu
LEFT JOIN health_reports hr ON mu.id = hr.url_id AND hr.checked_at = mu.last_checked_at
WHERE mu.is_active = TRUE
ORDER BY 
    CASE 
        WHEN mu.current_failure_count >= mu.failure_threshold THEN 1
        WHEN mu.current_failure_count > 0 THEN 2
        WHEN TIMESTAMPDIFF(MINUTE, mu.last_checked_at, NOW()) > (mu.check_interval_minutes + 5) THEN 3
        ELSE 4
    END,
    FIELD(mu.priority, 'critical', 'high', 'normal', 'low'),
    mu.current_failure_count DESC;

-- =====================================================
-- 11. API ENDPOINTS DATA
-- =====================================================

-- JSON-Ready Dashboard Data (For REST APIs)
-- Usage: API endpoints, mobile apps, external integrations
SELECT JSON_OBJECT(
    'timestamp', NOW(),
    'system_status', (
        SELECT JSON_OBJECT(
            'total_sites', total_sites,
            'operational', sites_up,
            'issues', (sites_down + sites_error + sites_timeout),
            'alerting', sites_alerting,
            'uptime_percent', overall_uptime_percent,
            'status_level', CASE 
                WHEN critical_sites_down > 0 THEN 'critical'
                WHEN sites_alerting > 0 THEN 'warning'
                WHEN overall_uptime_percent >= 99.5 THEN 'operational'
                ELSE 'degraded'
            END
        ) FROM dashboard_overview
    ),
    'services', (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id', url_id,
                'name', site_name,
                'url', url,
                'priority', priority,
                'status', current_status,
                'health', CASE 
                    WHEN health_status LIKE '%ALERTING%' THEN 'alerting'
                    WHEN health_status LIKE '%FAILING%' THEN 'degraded'
                    ELSE 'healthy'
                END,
                'response_time', last_response_time,
                'last_checked', last_checked_at
            )
        )
        FROM url_status_detailed 
        WHERE priority IN ('critical', 'high')
        ORDER BY FIELD(priority, 'critical', 'high'), site_name
    )
) as dashboard_json;

-- =====================================================
-- 12. MAINTENANCE AND CONFIGURATION QUERIES
-- =====================================================

-- System Configuration Overview
-- Usage: Settings page, system administration
SELECT 
    category,
    config_key,
    config_value,
    description,
    updated_at
FROM config
ORDER BY category, config_key;

-- Monitoring Coverage Analysis
-- Usage: Coverage assessment, gap analysis
SELECT 
    team_name,
    priority,
    COUNT(*) as service_count,
    AVG(check_interval_minutes) as avg_check_interval,
    COUNT(CASE WHEN check_ssl_expiry = TRUE THEN 1 END) as ssl_monitored_count,
    COUNT(CASE WHEN auth_token IS NOT NULL OR auth_header IS NOT NULL THEN 1 END) as authenticated_count,
    SUM(CASE WHEN last_checked_at IS NULL THEN 1 ELSE 0 END) as never_checked_count
FROM monitored_urls
WHERE is_active = TRUE
GROUP BY team_name, priority
ORDER BY COALESCE(team_name, 'ZZZ_Unassigned'), 
         FIELD(priority, 'critical', 'high', 'normal', 'low');

-- =====================================================
-- USAGE INSTRUCTIONS FOR REPORTING WEBSITE
-- =====================================================

/*
These queries provide a complete foundation for building a monitoring dashboard website.

IMPLEMENTATION SUGGESTIONS:

1. REAL-TIME DASHBOARD:
   - Use queries 1-3 for homepage status widgets
   - Refresh every 30-60 seconds for real-time updates
   - Implement WebSocket connections for live updates

2. STATUS PAGES:
   - Query 2 for main status page
   - Query 3 for incident-focused views
   - Add filtering by team, priority, status

3. PERFORMANCE ANALYTICS:
   - Queries 4-5 for performance dashboards
   - Create charts from response time trends
   - Implement alerting on performance degradation

4. REPORTING INTERFACES:
   - Queries 6-7 for SLA and uptime reports
   - Generate PDFs for executive reporting
   - Schedule automated report delivery

5. SECURITY MONITORING:
   - Query 8 for SSL certificate management
   - Implement SSL expiry alerts and notifications

6. TEAM DASHBOARDS:
   - Queries 9-10 for team-specific views
   - Role-based access control by team

7. API INTEGRATION:
   - Query 11 provides JSON-ready data
   - Implement REST APIs for mobile apps
   - Enable third-party integrations

RECOMMENDED TECHNOLOGY STACK:
- Frontend: React, Vue, or Angular
- Backend: Node.js, Python Flask/Django, or PHP Laravel
- Database: MySQL (as implemented)
- Real-time: WebSockets or Server-Sent Events
- Charts: Chart.js, D3.js, or Highcharts
- Styling: Bootstrap, Tailwind CSS, or Material UI

CACHING STRATEGY:
- Cache dashboard overview for 30 seconds
- Cache SLA reports for 5 minutes
- Cache historical data for 1 hour
- Use Redis or Memcached for performance

ALERTING INTEGRATION:
- Connect to Slack, Teams, PagerDuty
- Implement escalation workflows
- Add maintenance window awareness
*/