-- =============================================================================
-- PROJECT  : Detection of Fraudulent Financial Transactions
-- FILE     : 04_ERD_diagram.sql
-- PURPOSE  : Entity Relationship Diagram (ERD) description and relationships
--            This file documents the database structure visually using SQL
-- =============================================================================

-- =============================================================================
-- ERD OVERVIEW
-- =============================================================================
--
--  +---------------------+          +---------------------+
--  |    transactions     |          |   account_profiles  |
--  |---------------------|          |---------------------|
--  | PK transaction_id   |----+     | PK account_id       |
--  |    timestamp        |    |     |    first_seen       |
--  |    sender_account   |----+---->|    last_seen        |
--  |    receiver_account |          |    total_txns       |
--  |    amount           |          |    fraud_count      |
--  |    transaction_type |          |    risk_score       |
--  |    merchant_cat     |          |    most_used_device |
--  |    location         |          |    most_common_loc  |
--  |    device_used      |          +---------------------+
--  |    is_fraud         |
--  |    fraud_type       |          +---------------------+
--  |    velocity_score   |          |  model_predictions  |
--  |    deviation_score  |          |---------------------|
--  |    geo_anomaly      |          | PK id               |
--  |    payment_channel  |----+---->| FK transaction_id   |
--  |    ip_address       |    |     |    model_name       |
--  |    device_hash      |    |     |    predicted_fraud  |
--  +---------------------+    |     |    fraud_probability|
--                             |     |    actual_fraud     |
--  +---------------------+    |     +---------------------+
--  |  daily_fraud_stats  |    |
--  |---------------------|    |     +---------------------+
--  | PK stat_date        |    |     |   fraud_summary     |
--  |    total_txns       |<---+     |---------------------|
--  |    total_amount     |          | PK id               |
--  |    fraud_count      |          |    summary_date     |
--  |    fraud_amount     |          |    category         |
--  |    fraud_rate_pct   |          |    category_value   |
--  |    avg_fraud_amount |          |    total_txns       |
--  +---------------------+          |    fraud_count      |
--                                   |    fraud_amount     |
--                                   +---------------------+
--
-- RELATIONSHIPS:
-- [transactions] 1 --> N [model_predictions]  (one transaction = many model predictions)
-- [transactions] N --> 1 [account_profiles]   (many transactions from one account)
-- [transactions] N --> 1 [daily_fraud_stats]  (aggregated by date)
-- [fraud_summary] is a standalone aggregated table (no FK, refreshed by procedure)
--
-- =============================================================================

-- =============================================================================
-- TABLE DESCRIPTIONS
-- =============================================================================

-- transactions: The CORE table - every single financial transaction
-- - This is the biggest table with millions of rows
-- - Primary key: transaction_id (e.g. T100000)
-- - is_fraud = 1 means it was a fraud transaction
-- - All other tables reference or are derived from this table

-- account_profiles: One row per unique bank account
-- - Derived from transactions by aggregating sender_account
-- - risk_score = fraud_count / total_transactions
-- - Links to transactions via account_id = sender_account

-- model_predictions: Stores what each ML model predicted
-- - Each row = one model's prediction for one transaction
-- - Links back to transactions via transaction_id (foreign key)
-- - Used to compare multiple model performances

-- daily_fraud_stats: Pre-aggregated table for fast dashboard loading
-- - One row per calendar date
-- - Refreshed by stored procedure RefreshDailyStats()
-- - Used directly by Power BI for time-series dashboards

-- fraud_summary: Flexible summary table for any category grouping
-- - Can hold summaries by merchant_type, location, device, etc.
-- - Used by Power BI for slice-and-dice analysis

-- =============================================================================
-- RELATIONSHIP QUERIES - Prove the ERD is correct
-- =============================================================================

-- Show FK: model_predictions → transactions
SELECT
    mp.transaction_id,
    mp.model_name,
    mp.predicted_fraud,
    mp.actual_fraud,
    t.amount,
    t.transaction_type,
    t.is_fraud AS actual_label
FROM model_predictions mp
JOIN transactions t ON mp.transaction_id = t.transaction_id
LIMIT 10;

-- Show JOIN: transactions → account_profiles
SELECT
    t.transaction_id,
    t.sender_account,
    t.amount,
    t.is_fraud,
    ap.risk_score,
    ap.total_transactions AS account_total_txns,
    ap.fraud_count AS account_fraud_count
FROM transactions t
JOIN account_profiles ap ON t.sender_account = ap.account_id
WHERE t.is_fraud = 1
LIMIT 10;

-- Show JOIN: transactions → daily_fraud_stats
SELECT
    DATE(t.transaction_timestamp)   AS txn_date,
    COUNT(t.transaction_id)         AS transactions_today,
    d.fraud_count                   AS precomputed_fraud_count,
    d.fraud_rate_percent
FROM transactions t
JOIN daily_fraud_stats d ON DATE(t.transaction_timestamp) = d.stat_date
GROUP BY DATE(t.transaction_timestamp), d.fraud_count, d.fraud_rate_percent
ORDER BY txn_date DESC
LIMIT 10;

-- =============================================================================
-- DATA DICTIONARY
-- =============================================================================

-- Column explanation for non-technical readers:
-- transaction_id        : Unique code like "T100000" for each transaction
-- transaction_timestamp : Exact date and time of the transaction
-- sender_account        : The bank account that sent money
-- receiver_account      : The bank account that received money
-- amount                : Dollar value of the transaction
-- transaction_type      : withdrawal / deposit / transfer / payment
-- merchant_category     : Where the money was spent (grocery, travel, etc.)
-- location              : City name where transaction happened
-- device_used           : mobile / atm / pos (card machine) / web (browser)
-- is_fraud              : 1 = this transaction is FRAUD, 0 = this is NOT fraud
-- fraud_type            : The specific kind of fraud (e.g. money laundering)
-- time_since_last_txn   : Hours since the same account made a transaction
-- spending_deviation_score: How different this amount is from the user's normal spending
-- velocity_score        : How many transactions happened recently from this account
-- geo_anomaly_score     : Score showing if this location is unusual for the user
-- payment_channel       : How payment was made - card / ACH / wire_transfer / UPI
-- ip_address            : Internet address of the device used
-- device_hash           : Unique fingerprint/code for the device

SELECT 'ERD documentation complete' AS status;
