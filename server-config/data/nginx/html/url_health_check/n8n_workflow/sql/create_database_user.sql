CREATE DATABASE n8n_url_healthcheck
    DEFAULT CHARACTER SET = 'utf8mb4';


-- 1. Create the user
CREATE USER 'n8nheathcheckusr'@'%' IDENTIFIED BY 'Edcvfr5687#9ikjJhsg';

-- 2. Create the database (if it doesn't exist)
CREATE DATABASE IF NOT EXISTS n8n_url_healthcheck CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 3. Grant necessary privileges to the user for the health check database
GRANT ALL PRIVILEGES ON n8n_url_healthcheck.* TO 'n8nheathcheckusr'@'%';

-- 5. Apply the changes
FLUSH PRIVILEGES;

-- 6. Verify the user was created successfully
SELECT User, Host FROM mysql.user WHERE User = 'n8nheathcheckusr';

-- 7. Verify the grants
SHOW GRANTS FOR 'n8nheathcheckusr'@'%';

-- Optional: Create a read-only user for monitoring/reporting
CREATE USER 'n8nhealthcheck_readonly'@'%' IDENTIFIED BY 'ReadOnly123#Monitor';
GRANT SELECT ON n8n_url_healthcheck.* TO 'n8nhealthcheck_readonly'@'%';
FLUSH PRIVILEGES;