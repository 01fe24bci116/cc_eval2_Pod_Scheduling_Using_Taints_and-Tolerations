-- CloudOps Console Database Initialization Schema
-- Database: cloudops_db

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cloudops_resources (
    id SERIAL PRIMARY KEY,
    resource_name VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    namespace VARCHAR(50) NOT NULL,
    node_name VARCHAR(100),
    status VARCHAR(30) DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS resource_requests (
    id SERIAL PRIMARY KEY,
    requester VARCHAR(50) NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    cpu_cores VARCHAR(20) NOT NULL,
    memory_mb VARCHAR(20) NOT NULL,
    status VARCHAR(30) DEFAULT 'Approved',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lab_evaluation_records (
    id SERIAL PRIMARY KEY,
    experiment_name VARCHAR(100) NOT NULL,
    status VARCHAR(30) NOT NULL,
    details TEXT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed default admin user (admin / admin123)
INSERT INTO users (username, password_hash, full_name, role)
VALUES ('admin', 'pbkdf2:sha256:dummyhashorplain', 'CloudOps Administrator', 'admin')
ON CONFLICT (username) DO NOTHING;

-- Seed initial resource requests
INSERT INTO resource_requests (requester, service_name, cpu_cores, memory_mb, status)
VALUES 
('DevOps-Lead', 'order-service', '500m', '512Mi', 'Approved'),
('QA-Team', 'load-test-runner', '1000m', '1024Mi', 'Pending'),
('DBA', 'postgres-db-0', '250m', '256Mi', 'Dedicated-Tolerated');

-- Seed official persistence test record
INSERT INTO lab_evaluation_records (experiment_name, status, details)
VALUES ('PERSISTENCE_TEST_RECORD', 'PERMANENT_VERIFIED', 'This row was created during initial setup. It MUST survive postgres-db-0 pod deletion and recreation.');
