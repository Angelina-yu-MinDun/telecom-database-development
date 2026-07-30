
-- create_database
CREATE DATABASE telecom;

-- create_schemas
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS analytics;

-- create_tables
CREATE TABLE raw.customers (
    customer_id VARCHAR(8) PRIMARY KEY,
    registration_date DATE NOT NULL,
    date_of_birth DATE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    address TEXT NOT NULL
);

CREATE TABLE raw.customers (
    customer_id VARCHAR(8) PRIMARY KEY,
    registration_date DATE NOT NULL,
    date_of_birth DATE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    address TEXT NOT NULL
);

CREATE TABLE raw.plans (
    plan_id VARCHAR(8) PRIMARY KEY,
    plan_name VARCHAR(100) NOT NULL,
    plan_description TEXT NOT NULL,
    plan_duration INTEGER NOT NULL CHECK (plan_duration IN (28, 365)),
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE raw.phone_number (
    phone_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(8) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    activation_date DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES raw.customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE raw.phone_number (
    phone_id VARCHAR(8) PRIMARY KEY,
    customer_id VARCHAR(8) NOT NULL,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    activation_date DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES raw.customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE raw.subscriptions (
    subscription_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(8) NOT NULL,
    phone_id VARCHAR(8) NOT NULL,
    plan_id VARCHAR(8) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES raw.customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (phone_id) REFERENCES raw.phone_number(phone_id) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES raw.plans(plan_id) ON DELETE CASCADE
);

CREATE TABLE raw.payments (
    payment_id VARCHAR(12) PRIMARY KEY,
    subscription_id VARCHAR(10) NOT NULL UNIQUE,
    customer_id VARCHAR(8) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(20) NOT NULL CHECK (
        payment_method IN ('Credit Card', 'Debit Card', 'Bank Transfer', 'Cash', 'PayPal')
    ),
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    FOREIGN KEY (subscription_id) REFERENCES raw.subscriptions(subscription_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES raw.customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE raw.customer_service_rep (
    csr_id VARCHAR(12) PRIMARY KEY,
    csr_name VARCHAR(100) NOT NULL,
    employment_type VARCHAR(20) NOT NULL CHECK (employment_type IN ('Full-time', 'Part-time'))
);

CREATE TABLE raw.support_requests (
    request_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(8) NOT NULL,
    open_time TIMESTAMP NOT NULL,
    closed_time TIMESTAMP NOT NULL,
    request_type VARCHAR(50) NOT NULL CHECK (
        request_type IN (
            'Billing & Payments',
            'Technical Support',
            'Service & Account Management',
            'Security & Fraud',
            'General Inquiry'
        )
    ),
    csr_id VARCHAR(12) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES raw.customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (csr_id) REFERENCES raw.customer_service_rep(csr_id) ON DELETE CASCADE
);


