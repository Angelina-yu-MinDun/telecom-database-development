PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS support_requests;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS phone_number;
DROP TABLE IF EXISTS customer_service_rep;
DROP TABLE IF EXISTS plans;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY,
    registration_date TEXT NOT NULL,
    date_of_birth TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    address TEXT
);

CREATE TABLE plans (
    plan_id TEXT PRIMARY KEY,
    plan_name TEXT NOT NULL,
    plan_description TEXT,
    plan_duration INTEGER NOT NULL CHECK (plan_duration IN (28, 365)),
    price REAL NOT NULL CHECK (price >= 0)
);

CREATE TABLE phone_number (
    phone_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    phone_number TEXT UNIQUE NOT NULL,
    activation_date TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE subscriptions (
    subscription_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    phone_id TEXT NOT NULL,
    plan_id TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (phone_id) REFERENCES phone_number(phone_id) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES plans(plan_id) ON DELETE CASCADE
);

CREATE TABLE payments (
    payment_id TEXT PRIMARY KEY,
    subscription_id TEXT NOT NULL UNIQUE,
    customer_id TEXT NOT NULL,
    payment_date TEXT NOT NULL,
    payment_method TEXT NOT NULL CHECK (
        payment_method IN ('Credit Card', 'Debit Card', 'Bank Transfer', 'Cash', 'PayPal')
    ),
    amount REAL NOT NULL CHECK (amount >= 0),
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE customer_service_rep (
    csr_id TEXT PRIMARY KEY,
    csr_name TEXT NOT NULL,
    employment_type TEXT NOT NULL CHECK (employment_type IN ('Full-time', 'Part-time'))
);

CREATE TABLE support_requests (
    request_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    open_time TEXT NOT NULL,
    closed_time TEXT NOT NULL,
    request_type TEXT NOT NULL CHECK (
        request_type IN (
            'Billing & Payments',
            'Technical Support',
            'Service & Account Management',
            'Security & Fraud',
            'General Inquiry'
        )
    ),
    csr_id TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (csr_id) REFERENCES customer_service_rep(csr_id) ON DELETE CASCADE
);

CREATE INDEX idx_phone_customer ON phone_number(customer_id);
CREATE INDEX idx_subscriptions_customer ON subscriptions(customer_id);
CREATE INDEX idx_subscriptions_phone ON subscriptions(phone_id);
CREATE INDEX idx_subscriptions_plan ON subscriptions(plan_id);
CREATE INDEX idx_payments_customer ON payments(customer_id);
CREATE INDEX idx_support_customer ON support_requests(customer_id);
CREATE INDEX idx_support_csr ON support_requests(csr_id);
