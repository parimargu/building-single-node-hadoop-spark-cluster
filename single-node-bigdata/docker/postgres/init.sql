-- PostgreSQL Initialization Script for Monitoring Application
-- This script is run automatically when the PostgreSQL container starts

-- Create tables for service monitoring

-- Service status table
CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    container_name VARCHAR(100) NOT NULL,
    service_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'unknown',
    health VARCHAR(20) DEFAULT 'unknown',
    web_ui_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Service events table for history
CREATE TABLE IF NOT EXISTS service_events (
    id SERIAL PRIMARY KEY,
    service_id INTEGER REFERENCES services(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default service records
INSERT INTO services (name, container_name, service_type, web_ui_url) VALUES
    ('NameNode', 'namenode', 'hadoop', 'http://localhost:9870'),
    ('DataNode', 'datanode', 'hadoop', NULL),
    ('ResourceManager', 'resourcemanager', 'hadoop', 'http://localhost:8088'),
    ('NodeManager', 'nodemanager', 'hadoop', 'http://localhost:8042'),
    ('HistoryServer', 'historyserver', 'hadoop', 'http://localhost:19888'),
    ('Spark Master', 'spark-master', 'spark', 'http://localhost:8080'),
    ('Spark Worker', 'spark-worker', 'spark', 'http://localhost:8081'),
    ('Hive Metastore', 'hive-metastore', 'hive', NULL),
    ('HiveServer2', 'hiveserver2', 'hive', 'http://localhost:10002')
ON CONFLICT (name) DO NOTHING;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_service_events_service_id ON service_events(service_id);
CREATE INDEX IF NOT EXISTS idx_service_events_created_at ON service_events(created_at);

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Monitoring database initialized successfully';
END $$;
