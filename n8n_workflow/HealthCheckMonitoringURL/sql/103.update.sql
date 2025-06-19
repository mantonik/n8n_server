-- add tags column
USE n8n_url_healthcheck;
ALTER TABLE monitored_urls 
ADD COLUMN tags TEXT COMMENT 'Comma-separated tags for grouping and filtering' 
AFTER team_name;
