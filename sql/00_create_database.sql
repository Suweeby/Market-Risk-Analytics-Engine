-- One-time setup. Run as the postgres superuser:
--   psql -U postgres -v pw="your_password" -f sql/00_create_database.sql
-- The password is passed in at run time, so it is never stored in this file.

CREATE ROLE riskdesk_user WITH LOGIN PASSWORD :'pw';
CREATE DATABASE riskdesk OWNER riskdesk_user;