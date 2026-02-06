-- MySQL Initialization Script for Hive Metastore
-- This script is run automatically when the MySQL container starts

-- Create the hive metastore database
CREATE DATABASE IF NOT EXISTS hive_metastore;

-- Create the hive user with full privileges
CREATE USER IF NOT EXISTS 'hive'@'%' IDENTIFIED BY 'hivepass';
GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hive'@'%';

-- Flush privileges to apply changes
FLUSH PRIVILEGES;

-- Log completion
SELECT 'Hive Metastore database initialized successfully' as status;
