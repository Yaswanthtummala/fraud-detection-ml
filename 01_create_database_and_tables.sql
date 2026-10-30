-- =============================================================================
-- PROJECT  : Detection of Fraudulent Financial Transactions
-- STUDENT  : Yaswanth Sai Tummala, Student ID: S3423122
-- MODULE   : CIS4055 - Computing Masters Project
-- UNIVERSITY: Teesside University
-- FILE     : 01_create_database_and_tables.sql
-- PURPOSE  : Create the MySQL database and all tables needed for this project
-- =============================================================================

-- Step 1: Create the database
-- DROP DATABASE IF EXISTS fraud_detection;  -- Uncomment only if you want to start fresh
CREATE DATABASE IF NOT EXISTS fraud_detection
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Step 2: Switch to this database
USE fraud_detection;

-- =============================================================================
-- TABLE 1: transactions
-- This is the main table that stores all financial transaction records
-- =============================================================================
DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
    id                          INT AUTO_INCREMENT PRIMARY KEY,  -- Auto-generated row number
    transaction_id              VARCHAR(20)     NOT NULL UNIQUE, -- Unique transaction code like T100000
    transaction_timestamp       DATETIME        NOT NULL,        -- When the transaction happened
    sender_account              VARCHAR(20)     NOT NULL,        -- Account that sent money
    receiver_account            VARCHAR(20)     NOT NULL,        -- Account that received money
    amount                      DECIMAL(15, 2)  NOT NULL,        -- Money amount in dollars
    transaction_type            VARCHAR(20)     NOT NULL,        -- withdrawal, deposit, transfer, payment
    merchant_category           VARCHAR(50)     NOT NULL,        -- grocery, retail, travel, etc.
    location                    VARCHAR(100)    NOT NULL,        -- City where transaction happened
    device_used                 VARCHAR(20)     NOT NULL,        -- mobile, atm, pos, web
    is_fraud                    TINYINT(1)      NOT NULL DEFAULT 0, -- 0 = not fraud, 1 = fraud
    fraud_type                  VARCHAR(50)     NULL,            -- Type of fraud if it is fraud
    time_since_last_transaction DECIMAL(10, 4)  NULL,            -- Hours since last transaction
    spending_deviation_score    DECIMAL(10, 4)  NULL,            -- How different this spend is from normal
    velocity_score              INT             NULL,            -- Number of recent transactions
    geo_anomaly_score           DECIMAL(10, 4)  NULL,            -- Score for unusual location
    payment_channel             VARCHAR(30)     NOT NULL,        -- card, ACH, wire_transfer, UPI
    ip_address                  VARCHAR(50)     NULL,            -- IP address of the device
    device_hash                 VARCHAR(20)     NULL,            -- Unique code for the device
    created_at                  TIMESTAMP       DEFAULT CURRENT_TIMESTAMP, -- When this record was added

    -- Index on fraud column for fast filtering
    INDEX idx_is_fraud (is_fraud),
    INDEX idx_sender (sender_account),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_merchant_category (merchant_category),
    INDEX idx_location (location),
    INDEX idx_timestamp (transaction_timestamp),
    INDEX idx_amount (amount)
) ENGINE=InnoDB COMMENT='Main table: all financial transactions';

-- =============================================================================
-- TABLE 2: fraud_summary
-- This table stores a summary of fraud by category for quick dashboard access
-- =============================================================================
DROP TABLE IF EXISTS fraud_summary;
CREATE TABLE fraud_summary (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    summary_date        DATE        NOT NULL,           -- The date of this summary
    category            VARCHAR(50) NOT NULL,           -- Category name (e.g. merchant type)
    category_value      VARCHAR(100) NOT NULL,          -- Value (e.g. grocery, retail)
    total_transactions  INT         NOT NULL DEFAULT 0, -- Total count of transactions
    fraud_count         INT         NOT NULL DEFAULT 0, -- How many were fraud
    fraud_amount        DECIMAL(15,2) NOT NULL DEFAULT 0, -- Total fraud money
    fraud_rate          DECIMAL(5,4) NULL,              -- Fraud percentage (0 to 1)
    updated_at          TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_summary_date (summary_date),
    INDEX idx_category (category)
) ENGINE=InnoDB COMMENT='Summary table for Power BI dashboards';

-- =============================================================================
-- TABLE 3: account_profiles
-- This table stores account-level information and risk scores
-- =============================================================================
DROP TABLE IF EXISTS account_profiles;
CREATE TABLE account_profiles (
    account_id              VARCHAR(20)     PRIMARY KEY,     -- Account number
    first_seen              DATETIME        NULL,            -- First transaction date
    last_seen               DATETIME        NULL,            -- Most recent transaction date
    total_transactions      INT             DEFAULT 0,       -- Total number of transactions
    total_amount            DECIMAL(15,2)   DEFAULT 0,       -- Total money transacted
    fraud_count             INT             DEFAULT 0,       -- Number of fraud transactions
    avg_transaction_amount  DECIMAL(10,2)   NULL,            -- Average transaction value
    risk_score              DECIMAL(5,4)    NULL,            -- Calculated risk score (0 to 1)
    most_used_device        VARCHAR(20)     NULL,            -- Most common device
    most_common_location    VARCHAR(100)    NULL,            -- Most common location
    created_at              TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_risk_score (risk_score),
    INDEX idx_fraud_count (fraud_count)
) ENGINE=InnoDB COMMENT='Account-level risk profiles for analysis';

-- =============================================================================
-- TABLE 4: model_predictions
-- This table stores predictions made by our machine learning models
-- =============================================================================
DROP TABLE IF EXISTS model_predictions;
CREATE TABLE model_predictions (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id      VARCHAR(20)     NOT NULL,        -- Which transaction this is for
    model_name          VARCHAR(50)     NOT NULL,        -- e.g. RandomForest, XGBoost
    predicted_fraud     TINYINT(1)      NOT NULL,        -- What the model predicted (0 or 1)
    fraud_probability   DECIMAL(6,4)    NULL,            -- Probability score from the model
    actual_fraud        TINYINT(1)      NOT NULL,        -- Actual true label
    is_correct          TINYINT(1) AS (predicted_fraud = actual_fraud) VIRTUAL, -- Was prediction right?
    prediction_date     TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    INDEX idx_model_name (model_name),
    INDEX idx_transaction_id (transaction_id)
) ENGINE=InnoDB COMMENT='ML model predictions for evaluation';

-- =============================================================================
-- TABLE 5: daily_fraud_stats
-- Pre-aggregated daily statistics for Deployment performance
-- =============================================================================
DROP TABLE IF EXISTS daily_fraud_stats;
CREATE TABLE daily_fraud_stats (
    stat_date           DATE        PRIMARY KEY,
    total_transactions  INT         NOT NULL DEFAULT 0,
    total_amount        DECIMAL(15,2) NOT NULL DEFAULT 0,
    fraud_count         INT         NOT NULL DEFAULT 0,
    fraud_amount        DECIMAL(15,2) NOT NULL DEFAULT 0,
    fraud_rate_percent  DECIMAL(5,2) NULL,           -- Fraud % for that day
    avg_fraud_amount    DECIMAL(10,2) NULL,          -- Average fraud transaction amount
    top_fraud_type      VARCHAR(50) NULL,            -- Most common fraud type that day
    updated_at          TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Daily statistics for trend dashboards';

-- =============================================================================
-- Verify all tables were created successfully
-- =============================================================================
SHOW TABLES;
DESCRIBE transactions;
