-- =============================================================================
-- PROJECT  : Detection of Fraudulent Financial Transactions
-- FILE     : 02_load_data.sql
-- PURPOSE  : Load the CSV dataset into the transactions table
-- NOTE     : Run 01_create_database_and_tables.sql first before this file
-- =============================================================================

USE fraud_detection;

-- =============================================================================
-- Step 1: Load the CSV data into the transactions table
-- IMPORTANT: Change the file path below to match where your CSV file is saved
-- =============================================================================

-- First, allow loading from local files (run this once as admin if needed)
-- SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE "C:\Users\yaswa\OneDrive\Desktop\Yashwanth Dissertation\Dataset\financial_fraud_detection_dataset.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS  -- Skip the header row
(
    transaction_id,
    @ts,                        -- Read timestamp as text first
    sender_account,
    receiver_account,
    amount,
    transaction_type,
    merchant_category,
    location,
    device_used,
    @is_fraud_raw,              -- Read as text, then convert
    @fraud_type_raw,
    time_since_last_transaction,
    spending_deviation_score,
    velocity_score,
    geo_anomaly_score,
    payment_channel,
    ip_address,
    device_hash
)
SET
    -- Convert the timestamp format to MySQL DATETIME
    transaction_timestamp = STR_TO_DATE(@ts, '%Y-%m-%dT%H:%i:%s.%f'),
    -- Convert True/False to 1/0
    is_fraud = IF(@is_fraud_raw = 'True', 1, 0),
    -- Convert NaN to NULL for fraud type
    fraud_type = IF(@fraud_type_raw = '' OR @fraud_type_raw = 'nan', NULL, @fraud_type_raw);

-- Check how many rows were loaded
SELECT COUNT(*) AS total_rows_loaded FROM transactions;

-- =============================================================================
-- Step 2: Check for any data quality issues after loading
-- =============================================================================

-- Check for NULL values in important columns
SELECT
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END)      AS null_transaction_id,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END)              AS null_amount,
    SUM(CASE WHEN transaction_type IS NULL THEN 1 ELSE 0 END)    AS null_type,
    SUM(CASE WHEN is_fraud IS NULL THEN 1 ELSE 0 END)            AS null_is_fraud,
    SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END)            AS null_location
FROM transactions;

-- Check fraud vs non-fraud counts
SELECT
    is_fraud,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM transactions
GROUP BY is_fraud;

-- =============================================================================
-- Step 3: Populate the account_profiles table from transactions data
-- =============================================================================

INSERT INTO account_profiles
    (account_id, first_seen, last_seen, total_transactions, total_amount,
     fraud_count, avg_transaction_amount, most_used_device, most_common_location)
SELECT
    sender_account                          AS account_id,
    MIN(transaction_timestamp)              AS first_seen,
    MAX(transaction_timestamp)              AS last_seen,
    COUNT(*)                                AS total_transactions,
    SUM(amount)                             AS total_amount,
    SUM(is_fraud)                           AS fraud_count,
    ROUND(AVG(amount), 2)                   AS avg_transaction_amount,
    -- Find most commonly used device
    (
        SELECT device_used
        FROM transactions t2
        WHERE t2.sender_account = t1.sender_account
        GROUP BY device_used
        ORDER BY COUNT(*) DESC
        LIMIT 1
    )                                       AS most_used_device,
    -- Find most common location
    (
        SELECT location
        FROM transactions t3
        WHERE t3.sender_account = t1.sender_account
        GROUP BY location
        ORDER BY COUNT(*) DESC
        LIMIT 1
    )                                       AS most_common_location
FROM transactions t1
GROUP BY sender_account
ON DUPLICATE KEY UPDATE
    last_seen               = VALUES(last_seen),
    total_transactions      = VALUES(total_transactions),
    total_amount            = VALUES(total_amount),
    fraud_count             = VALUES(fraud_count),
    avg_transaction_amount  = VALUES(avg_transaction_amount);

-- Update risk scores for accounts (fraud_count / total_transactions)
UPDATE account_profiles
SET risk_score = ROUND(fraud_count / total_transactions, 4)
WHERE total_transactions > 0;

-- =============================================================================
-- Step 4: Populate daily_fraud_stats table
-- =============================================================================

INSERT INTO daily_fraud_stats
    (stat_date, total_transactions, total_amount, fraud_count, fraud_amount,
     fraud_rate_percent, avg_fraud_amount)
SELECT
    DATE(transaction_timestamp)                                         AS stat_date,
    COUNT(*)                                                            AS total_transactions,
    ROUND(SUM(amount), 2)                                               AS total_amount,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2)       AS fraud_amount,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate_percent,
    ROUND(AVG(CASE WHEN is_fraud = 1 THEN amount END), 2)              AS avg_fraud_amount
FROM transactions
GROUP BY DATE(transaction_timestamp)
ON DUPLICATE KEY UPDATE
    total_transactions  = VALUES(total_transactions),
    total_amount        = VALUES(total_amount),
    fraud_count         = VALUES(fraud_count),
    fraud_amount        = VALUES(fraud_amount),
    fraud_rate_percent  = VALUES(fraud_rate_percent),
    avg_fraud_amount    = VALUES(avg_fraud_amount);

SELECT 'Data loading complete!' AS status;
SELECT COUNT(*) AS daily_stats_rows FROM daily_fraud_stats;
SELECT COUNT(*) AS account_profile_rows FROM account_profiles;
