-- =============================================================================
-- PROJECT  : Detection of Fraudulent Financial Transactions
-- FILE     : 03_analytical_queries.sql
-- PURPOSE  : All analytical SQL queries used for EDA and Power BI dashboards
-- NOTE     : These queries match the dashboards and graphs in the project
-- =============================================================================

USE fraud_detection;

-- =============================================================================
-- SECTION 1: OVERVIEW QUERIES (Used in Dashboard 1 - Overview)
-- =============================================================================

-- Query 1.1: Overall fraud summary (KPI cards in Power BI)
SELECT
    COUNT(*)                                                            AS total_transactions,
    SUM(is_fraud)                                                       AS total_fraud_cases,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate_percent,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2)       AS total_fraud_amount,
    ROUND(AVG(CASE WHEN is_fraud = 1 THEN amount END), 2)              AS avg_fraud_amount,
    ROUND(MAX(CASE WHEN is_fraud = 1 THEN amount END), 2)              AS max_fraud_amount
FROM transactions;

-- Query 1.2: Fraud count by transaction type
SELECT
    transaction_type,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate
FROM transactions
GROUP BY transaction_type
ORDER BY fraud_count DESC;

-- Query 1.3: Fraud count by payment channel
SELECT
    payment_channel,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2)       AS fraud_amount
FROM transactions
GROUP BY payment_channel
ORDER BY fraud_rate DESC;

-- =============================================================================
-- SECTION 2: TIME ANALYSIS (Used in Dashboard 2 - Time Trends)
-- =============================================================================

-- Query 2.1: Monthly fraud trend
SELECT
    DATE_FORMAT(transaction_timestamp, '%Y-%m')                         AS year_month,
    COUNT(*)                                                            AS total_transactions,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate_percent,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2)       AS fraud_amount
FROM transactions
GROUP BY DATE_FORMAT(transaction_timestamp, '%Y-%m')
ORDER BY year_month;

-- Query 2.2: Fraud by hour of the day (find peak fraud hours)
SELECT
    HOUR(transaction_timestamp)                                         AS hour_of_day,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate
FROM transactions
GROUP BY HOUR(transaction_timestamp)
ORDER BY hour_of_day;

-- Query 2.3: Fraud by day of the week (Monday=2 in MySQL)
SELECT
    DAYNAME(transaction_timestamp)                                      AS day_name,
    DAYOFWEEK(transaction_timestamp)                                    AS day_number,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate
FROM transactions
GROUP BY DAYNAME(transaction_timestamp), DAYOFWEEK(transaction_timestamp)
ORDER BY day_number;

-- =============================================================================
-- SECTION 3: LOCATION ANALYSIS (Used in Dashboard 3 - Geography)
-- =============================================================================

-- Query 3.1: Fraud by location/city
SELECT
    location,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2)       AS fraud_amount,
    ROUND(AVG(geo_anomaly_score), 4)                                    AS avg_geo_anomaly
FROM transactions
GROUP BY location
ORDER BY fraud_count DESC;

-- Query 3.2: Location and device combination for fraud
SELECT
    location,
    device_used,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate
FROM transactions
GROUP BY location, device_used
ORDER BY fraud_rate DESC;

-- =============================================================================
-- SECTION 4: MERCHANT & DEVICE ANALYSIS (Used in Dashboard 4)
-- =============================================================================

-- Query 4.1: Fraud by merchant category
SELECT
    merchant_category,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate,
    ROUND(AVG(amount), 2)                                               AS avg_amount,
    ROUND(AVG(CASE WHEN is_fraud = 1 THEN amount END), 2)              AS avg_fraud_amount
FROM transactions
GROUP BY merchant_category
ORDER BY fraud_rate DESC;

-- Query 4.2: Fraud by device type
SELECT
    device_used,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2)       AS fraud_amount
FROM transactions
GROUP BY device_used
ORDER BY fraud_count DESC;

-- Query 4.3: Cross analysis - merchant + device + fraud rate
SELECT
    merchant_category,
    device_used,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate
FROM transactions
GROUP BY merchant_category, device_used
HAVING total > 100                                          -- Only show groups with enough data
ORDER BY fraud_rate DESC
LIMIT 20;

-- =============================================================================
-- SECTION 5: AMOUNT & RISK SCORE ANALYSIS (Used in Dashboard 5)
-- =============================================================================

-- Query 5.1: Transaction amount buckets - how much do fraudsters steal?
SELECT
    CASE
        WHEN amount < 50    THEN '1. Under $50'
        WHEN amount < 200   THEN '2. $50 - $200'
        WHEN amount < 500   THEN '3. $200 - $500'
        WHEN amount < 1000  THEN '4. $500 - $1000'
        WHEN amount < 2000  THEN '5. $1000 - $2000'
        ELSE                     '6. Over $2000'
    END                                                                 AS amount_range,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate
FROM transactions
GROUP BY amount_range
ORDER BY amount_range;

-- Query 5.2: High-risk accounts (sorted by risk score)
SELECT
    account_id,
    total_transactions,
    fraud_count,
    ROUND(total_amount, 2)                                              AS total_amount,
    ROUND(avg_transaction_amount, 2)                                    AS avg_amount,
    risk_score,
    most_used_device,
    most_common_location
FROM account_profiles
WHERE fraud_count > 0
ORDER BY risk_score DESC
LIMIT 50;

-- Query 5.3: Spending deviation and velocity score vs fraud
SELECT
    ROUND(spending_deviation_score, 1)                                  AS deviation_bucket,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate
FROM transactions
WHERE spending_deviation_score IS NOT NULL
GROUP BY ROUND(spending_deviation_score, 1)
ORDER BY deviation_bucket;

-- Query 5.4: Velocity score analysis (high velocity = more risk?)
SELECT
    velocity_score,
    COUNT(*)                                                            AS total,
    SUM(is_fraud)                                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                         AS fraud_rate,
    ROUND(AVG(amount), 2)                                               AS avg_amount
FROM transactions
WHERE velocity_score IS NOT NULL
GROUP BY velocity_score
ORDER BY velocity_score;

-- =============================================================================
-- SECTION 6: FRAUD TYPE ANALYSIS (Used in Dashboard 6)
-- =============================================================================

-- Query 6.1: Fraud types breakdown
SELECT
    COALESCE(fraud_type, 'Not Fraud')                                   AS fraud_type,
    COUNT(*)                                                            AS count,
    ROUND(AVG(amount), 2)                                               AS avg_amount,
    ROUND(SUM(amount), 2)                                               AS total_amount,
    ROUND(AVG(spending_deviation_score), 4)                            AS avg_deviation,
    ROUND(AVG(velocity_score), 2)                                       AS avg_velocity
FROM transactions
WHERE is_fraud = 1 OR fraud_type IS NULL
GROUP BY fraud_type
ORDER BY count DESC;

-- Query 6.2: Fraud type by location
SELECT
    fraud_type,
    location,
    COUNT(*)                                                            AS count,
    ROUND(AVG(amount), 2)                                               AS avg_amount
FROM transactions
WHERE is_fraud = 1 AND fraud_type IS NOT NULL
GROUP BY fraud_type, location
ORDER BY fraud_type, count DESC;

-- =============================================================================
-- SECTION 7: ADVANCED / STORED PROCEDURE QUERIES
-- =============================================================================

-- Stored Procedure: Get full fraud profile for a specific account
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS GetAccountFraudProfile(IN p_account VARCHAR(20))
BEGIN
    -- Basic account info
    SELECT * FROM account_profiles WHERE account_id = p_account;

    -- Recent fraud transactions
    SELECT
        transaction_id,
        transaction_timestamp,
        amount,
        transaction_type,
        merchant_category,
        location,
        device_used,
        fraud_type,
        spending_deviation_score,
        velocity_score
    FROM transactions
    WHERE sender_account = p_account AND is_fraud = 1
    ORDER BY transaction_timestamp DESC
    LIMIT 20;
END //
DELIMITER ;

-- Stored Procedure: Refresh daily stats table
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS RefreshDailyStats()
BEGIN
    -- Clear old data
    TRUNCATE TABLE daily_fraud_stats;

    -- Re-calculate from transactions
    INSERT INTO daily_fraud_stats
        (stat_date, total_transactions, total_amount, fraud_count,
         fraud_amount, fraud_rate_percent, avg_fraud_amount)
    SELECT
        DATE(transaction_timestamp),
        COUNT(*),
        ROUND(SUM(amount), 2),
        SUM(is_fraud),
        ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2),
        ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2),
        ROUND(AVG(CASE WHEN is_fraud = 1 THEN amount END), 2)
    FROM transactions
    GROUP BY DATE(transaction_timestamp);

    SELECT CONCAT('Refreshed ', ROW_COUNT(), ' daily stat rows') AS message;
END //
DELIMITER ;

-- View: Easy view for Power BI to connect to fraud records
CREATE OR REPLACE VIEW vw_fraud_transactions AS
SELECT
    transaction_id,
    DATE(transaction_timestamp)                         AS transaction_date,
    YEAR(transaction_timestamp)                         AS year,
    MONTH(transaction_timestamp)                        AS month,
    HOUR(transaction_timestamp)                         AS hour,
    DAYNAME(transaction_timestamp)                      AS day_name,
    sender_account,
    receiver_account,
    amount,
    transaction_type,
    merchant_category,
    location,
    device_used,
    is_fraud,
    COALESCE(fraud_type, 'None')                        AS fraud_type_label,
    time_since_last_transaction,
    spending_deviation_score,
    velocity_score,
    geo_anomaly_score,
    payment_channel
FROM transactions;

-- View: Account risk summary for Power BI
CREATE OR REPLACE VIEW vw_account_risk AS
SELECT
    ap.account_id,
    ap.total_transactions,
    ap.fraud_count,
    ap.risk_score,
    CASE
        WHEN ap.risk_score = 0        THEN 'Low Risk'
        WHEN ap.risk_score < 0.05     THEN 'Medium Risk'
        ELSE                               'High Risk'
    END                                                 AS risk_level,
    ap.avg_transaction_amount,
    ap.most_used_device,
    ap.most_common_location
FROM account_profiles ap;

SELECT 'All queries and procedures created successfully!' AS status;
