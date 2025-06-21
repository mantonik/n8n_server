# Website Health Monitor - PHP Dashboard

A comprehensive web-based dashboard for monitoring website health and managing alerts, designed to work with your existing N8N monitoring workflow.

## 🚀 Features

- **Real-time Dashboard** - Live monitoring status with auto-refresh
- **Public Status Page** - Optional public-facing status page  
- **Alert Management** - Configure alert definitions and contacts
- **URL Management** - Add, edit, and manage monitored URLs
- **Team Organization** - Group monitoring by teams
- **SSL Certificate Monitoring** - Track SSL certificate expiration
- **Performance Analytics** - Response time tracking and reporting
- **Authentication System** - Secure admin access with session management
- **Mobile Responsive** - Works on desktop, tablet, and mobile devices

## 📋 Requirements

- **PHP 7.4+** with PDO MySQL extension
- **MySQL 5.7+** or **MariaDB 10.3+**
- **Web Server** (Apache, Nginx, or similar)
- **Existing N8N monitoring workflow** (from your uploaded files)

## 🛠 Installation

### 1. Upload Files

Upload all PHP files to your web server directory:
```
https://dmseo03.dmcloudarchitect.com/urlcheck/
```

Required files:
- `config.php` - Database and application configuration
- `auth.php` - Authentication system
- `login.php` - Login page
- `dashboard.php` - Main dashboard
- `public.php` - Public status page (optional)
- `manage.php` - Management interface
- `logout.php` - Logout handler
- `index.php` - Main entry point
- `setup_database.php` - Database verification tool

### 2. Database Setup

**Option A: Use Existing Database**
If you already have the clean database structure from your uploaded SQL files:

1. Update `config.php` with your database credentials:
```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'n8n_url_healthcheck');
define('DB_USER', 'n8nheathcheckusr');
define('DB_PASS', 'your_password_here');
```

**Option B: Fresh Database Setup**
1. Run `101.complete_database_rebuild.sql` to create the database structure
2. Run `102.Sample_date_insert.sql` to populate with sample data (optional)
3. Update `config.php` with your database credentials

### 3. Verify Installation

1. Visit: `https://dmseo03.dmcloudarchitect.com/urlcheck/setup_database.php`
2. Verify all database tables are present and working
3. Check that sample data is loaded (if applicable)
4. Delete `setup_database.php` after successful verification

### 4. Configure Authentication

**Default Login Credentials:**
- Username: `admin`
- Password: `monitor123!`

**⚠️ IMPORTANT:** Change the default password in `config.php`:
```php
define('ADMIN_PASSWORD', 'your_secure_password_here');
```

### 5. Test Access

1. **Admin Dashboard:** `https://dmseo03.dmcloudarchitect.com/urlcheck/`
2. **Public Status:** `https://dmseo03.dmcloudarchitect.com/urlcheck/public.php`

## 🔧 Configuration

### Basic Settings

Edit `config.php` to customize:

```php
// Application settings
define('APP_NAME', 'Website Health Monitor');
define('TIMEZONE', 'America/New_York');
define('REFRESH_INTERVAL', 30); // Dashboard refresh in seconds

// Public dashboard
define('PUBLIC_DASHBOARD_ENABLED', true);

// Security
define('SESSION_TIMEOUT', 3600); // 1 hour
define('LOGIN_ATTEMPTS_LIMIT', 5);
```

### Database Views

The system uses several database views for efficient data retrieval:
- `dashboard_overview` - System overview metrics
- `url_status_current` - Current status of all URLs
- `alert_configuration_overview` - Alert configuration summary

### N8N Integration

Your existing N8N workflow should continue working with the new database structure. The monitoring workflow uses:
- `monitored_urls` table for URLs to check
- `alert_definitions` and `alert_contacts` for alert configuration
- `health_reports` for storing check results
- `alert_history` for tracking sent alerts

## 🎛 Management Interface

### Alert Definitions

1. Go to **Management > Alert Configuration**
2. Create alert definitions for different teams/priorities
3. Add contacts for each alert definition
4. Configure notification types (email, SMS, webhook, etc.)

### Monitored URLs

1. Go to **Management > Monitored URLs**
2. Add new URLs with configuration:
   - Basic info (URL, name, description)
   - Priority level (critical, high, normal, low)
   - Team assignment
   - Check interval and timeout settings
   - Expected response validation
   - SSL certificate monitoring
   - Performance thresholds

### System Configuration

1. Go to **Management > System Configuration**
2. Adjust global settings:
   - Default timeouts and intervals
   - Alert cooldown periods
   - Data retention settings
   - Performance thresholds

## 📱 Dashboard Features

### Main Dashboard
- **System Overview** - Overall health metrics
- **Current Status** - Real-time status of all monitored URLs
- **Team Performance** - Status grouped by team
- **Recent Alerts** - Latest alerts from the past 24 hours
- **SSL Certificates** - Certificates expiring soon

### Public Status Page
- **System Status** - Public-facing status overview
- **Service Categories** - Status by priority level
- **Individual Services** - Status of each monitored service
- **Auto-refresh** - Real-time updates without login

## 🔒 Security Features

- **Authentication Required** - Admin access requires login
- **Session Management** - Automatic session timeout
- **CSRF Protection** - Forms protected against CSRF attacks
- **Login Attempt Limiting** - Prevents brute force attacks
- **Activity Logging** - Tracks login/logout activities
- **SQL Injection Prevention** - Prepared statements used throughout

## 📊 Reporting

The system provides several reporting capabilities:
- **SLA Reports** - Uptime and availability metrics
- **Performance Analytics** - Response time trends
- **Alert Volume Analysis** - Alert frequency and patterns
- **Team Performance** - Team-based monitoring metrics

## 🛡 Maintenance

### Regular Tasks

1. **Monitor disk usage** - Health reports and alert history grow over time
2. **Review alert configurations** - Ensure contacts are current
3. **Update SSL certificates** - Monitor certificate expiration
4. **Check N8N workflow** - Ensure monitoring workflow is running
5. **Review performance** - Monitor dashboard loading times

### Database Cleanup

The system includes automatic cleanup via your N8N workflow, but you can also run manual cleanup:

```sql
-- Clean old health reports (older than 90 days)
DELETE FROM health_reports 
WHERE checked_at < DATE_SUB(NOW(), INTERVAL 90 DAY);

-- Clean old alert history (older than 90 days)  
DELETE FROM alert_history 
WHERE sent_at < DATE_SUB(NOW(), INTERVAL 90 DAY);

-- Optimize tables
OPTIMIZE TABLE health_reports, alert_history;
```

### Backup Recommendations

1. **Database backups** - Regular MySQL dumps
2. **Configuration backup** - Save `config.php` settings
3. **Alert configuration** - Export alert definitions and contacts

## 🐛 Troubleshooting

### Common Issues

**Database Connection Errors:**
- Verify credentials in `config.php`
- Check MySQL service is running
- Confirm database exists and user has permissions

**Dashboard Not Loading:**
- Check PHP error logs
- Verify all required PHP extensions are installed
- Check file permissions (web server needs read access)

**Login Issues:**
- Verify username/password in `config.php`
- Check session configuration
- Clear browser cookies/cache

**No Data Showing:**
- Verify N8N workflow is running
- Check database has sample data or real monitoring data
- Confirm database views exist and are working

**Public Dashboard 404:**
- Check `PUBLIC_DASHBOARD_ENABLED` setting
- Verify `public.php` file exists
- Check web server configuration

### Debug Mode

To enable debug information, add to `config.php`:
```php
error_reporting(E_ALL);
ini_set('display_errors', 1);
```

**⚠️ Remember to disable debug mode in production!**

## 🔄 Integration with Existing N8N Workflow

Your existing N8N monitoring workflow should work seamlessly with the new database structure:

### Required Updates to N8N Workflow

1. **Alert Recipients Query** - Update to use new alert system:
```sql
SELECT ac.notification_type, ac.contact_email as destination, 
       ac.contact_name as member_name, ad.alert_name as group_name, 
       ad.id as group_id 
FROM monitored_urls mu 
JOIN alert_definitions ad ON mu.alert_definition_id = ad.id 
JOIN alert_contacts ac ON ad.id = ac.alert_definition_id 
WHERE mu.id = ? AND mu.is_active = TRUE 
  AND ad.is_active = TRUE AND ac.is_active = TRUE
```

2. **URL Selection Query** - Updated for new structure:
```sql
SELECT id, url, name, expected_response, timeout_seconds, 
       failure_threshold, current_failure_count, priority, 
       check_interval_minutes, expected_response_chars, 
       http_method, alert_definition_id 
FROM monitored_urls 
WHERE is_active = TRUE 
  AND (last_checked_at IS NULL OR 
       last_checked_at <= DATE_SUB(NOW(), INTERVAL check_interval_minutes MINUTE))
ORDER BY FIELD(priority, 'critical', 'high', 'normal', 'low'), 
         last_checked_at ASC 
LIMIT 10
```

### Database Field Mapping

| Old Field | New Field | Notes |
|-----------|-----------|-------|
| `contact_person` | `alert_definition_id` | Now links to alert definitions |
| `contact_email` | `alert_definition_id` | Contacts managed separately |
| `alert_groups` | `alert_definitions` | Simplified alert system |
| `group_members` | `alert_contacts` | Multiple contacts per definition |

## 🎨 Customization

### Styling

The dashboard uses Bootstrap 5 with custom CSS. To customize:

1. **Colors** - Modify CSS gradient variables
2. **Branding** - Update `APP_NAME` and add your logo
3. **Layout** - Adjust Bootstrap classes in HTML templates

### Additional Features

The codebase is designed for easy extension:

1. **New Alert Types** - Add to enum in `alert_history.alert_type`
2. **Custom Dashboards** - Create new PHP pages using existing patterns
3. **API Endpoints** - Add REST API endpoints for mobile apps
4. **Reporting** - Extend with additional SQL queries and charts

## 📱 Mobile App Integration

The system provides JSON endpoints for mobile app integration:

```php
// Get dashboard data as JSON
$dashboardData = $db->fetchOne("SELECT JSON_OBJECT(...) as dashboard_json FROM dashboard_overview");
```

## 🔗 API Documentation

### Basic Endpoints

- **GET `/dashboard.php`** - Main dashboard (requires auth)
- **GET `/public.php`** - Public status page
- **POST `/manage.php`** - Management actions (requires auth)

### Adding REST API

To add RESTful API endpoints, create `api.php`:

```php
<?php
require_once 'config.php';
require_once 'auth.php';

header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];
$path = $_GET['path'] ?? '';

switch ($path) {
    case 'status':
        $overview = $db->fetchOne("SELECT * FROM dashboard_overview");
        echo json_encode($overview);
        break;
        
    case 'urls':
        $urls = $db->fetchAll("SELECT * FROM url_status_current");
        echo json_encode($urls);
        break;
        
    default:
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint not found']);
}
?>
```

## 📞 Support

### Documentation References

- Database schema: See `101.complete_database_rebuild.sql`
- Sample data: See `102.Sample_date_insert.sql`  
- N8N workflow: See `101.n8n_monitoring_workflow_v1.json`
- Queries: See `website_monitoring_query.sql`

### Configuration Examples

**High-Frequency Monitoring:**
```php
define('REFRESH_INTERVAL', 15); // 15 second refresh
```

**Custom Timezone:**
```php
define('TIMEZONE', 'America/Los_Angeles');
```

**Extended Session:**
```php
define('SESSION_TIMEOUT', 7200); // 2 hours
```

## 🚀 Performance Optimization

### Database Optimization

1. **Indexes** - Ensure proper indexes on frequently queried columns
2. **Cleanup** - Regular cleanup of old health reports
3. **Views** - Use database views for complex queries
4. **Connection Pooling** - Consider connection pooling for high traffic

### Web Server Optimization

1. **PHP OPcache** - Enable PHP bytecode caching
2. **Gzip Compression** - Enable gzip for HTML/CSS/JS
3. **Browser Caching** - Set appropriate cache headers
4. **CDN** - Use CDN for Bootstrap/FontAwesome assets

### Frontend Optimization

1. **Auto-refresh** - Configurable refresh intervals
2. **AJAX Updates** - Partial page updates instead of full refresh
3. **Progressive Loading** - Load critical data first
4. **Responsive Images** - Optimize for mobile devices

## 🔄 Migration from Legacy System

If migrating from an older monitoring system:

1. **Export existing URLs** - Create CSV export of current monitored URLs
2. **Map alert groups** - Convert old alert groups to new alert definitions
3. **Import data** - Use bulk insert scripts for large datasets
4. **Test thoroughly** - Verify all functionality before going live
5. **Parallel operation** - Run both systems temporarily during transition

## 📈 Scaling Considerations

For high-volume monitoring (100+ URLs):

1. **Database Performance** - Consider read replicas for dashboard queries
2. **N8N Scaling** - Distribute N8N workflows across multiple instances
3. **Caching** - Implement Redis/Memcached for dashboard data
4. **Load Balancing** - Use multiple web servers behind load balancer
5. **Monitoring** - Monitor the monitoring system itself!

---

## 🎯 Quick Start Checklist

- [ ] Upload all PHP files to web server
- [ ] Update `config.php` with database credentials
- [ ] Run database setup scripts (if needed)
- [ ] Visit `setup_database.php` to verify installation
- [ ] Login with default credentials (admin/monitor123!)
- [ ] Change default password in `config.php`
- [ ] Configure alert definitions and contacts
- [ ] Add your URLs to monitor
- [ ] Verify N8N workflow is running
- [ ] Test both admin dashboard and public status page
- [ ] Delete `setup_database.php`

## 📋 Production Deployment Checklist

- [ ] Change default admin password
- [ ] Disable debug mode in `config.php`
- [ ] Set up SSL/HTTPS for the website
- [ ] Configure web server security headers
- [ ] Set up database backups
- [ ] Configure log rotation
- [ ] Monitor disk space usage
- [ ] Set up external monitoring of the monitoring system
- [ ] Document team access procedures
- [ ] Train team members on dashboard usage

---

**Need Help?** Check the troubleshooting section above or review the SQL files for database structure details.