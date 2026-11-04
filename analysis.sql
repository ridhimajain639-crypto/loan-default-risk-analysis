-- Ensure you are using the correct database
CREATE DATABASE IF NOT EXISTS loan_risk_analysis;
USE loan_risk_analysis;

-- ==========================================
-- STEP 1: EXPLORATORY DATA ANALYSIS (EDA)
-- ==========================================

-- 1. Check Data Types & Schema Structure
DESCRIBE borrower_profiles;
DESCRIBE loan_applications;

-- 2. Check Basic Stats (Min, Max, Averages for Numerical columns)
SELECT 
    MIN(credit_score) AS min_credit_score,
    MAX(credit_score) AS max_credit_score,
    ROUND(AVG(credit_score), 2) AS avg_credit_score,
    MIN(annual_income) AS min_income,
    MAX(annual_income) AS max_income
FROM borrower_profiles;

-- 3. Check for Null Values
SELECT 
    SUM(CASE WHEN credit_score IS NULL THEN 1 ELSE 0 END) AS null_credit_scores,
    SUM(CASE WHEN annual_income IS NULL THEN 1 ELSE 0 END) AS null_incomes
FROM borrower_profiles;

-- 4. Join the Two Tables on borrower_id
SELECT 
    l.loan_id,
    l.borrower_id,
    l.loan_amount,
    l.loan_status,
    b.credit_score,
    b.annual_income,
    b.employment_status
FROM loan_applications l
INNER JOIN borrower_profiles b 
    ON l.borrower_id = b.borrower_id
LIMIT 10;

-- ==========================================
-- STEP 2: SEGMENT ANALYSIS - CREDIT SCORE BUCKETS
-- ==========================================

WITH CreditBuckets AS (
    SELECT 
        l.loan_id,
        l.loan_status,
        CASE 
            WHEN b.credit_score BETWEEN 520 AND 599 THEN '520-599'
            WHEN b.credit_score BETWEEN 600 AND 649 THEN '600-649'
            WHEN b.credit_score BETWEEN 650 AND 699 THEN '650-699'
            WHEN b.credit_score BETWEEN 700 AND 749 THEN '700-749'
            WHEN b.credit_score >= 750 THEN '750+'
            ELSE 'Other'
        END AS credit_score_bucket
    FROM loan_applications l
    INNER JOIN borrower_profiles b ON l.borrower_id = b.borrower_id
)
SELECT 
    credit_score_bucket,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) AS total_defaults,
    ROUND(SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_percentage
FROM CreditBuckets
GROUP BY credit_score_bucket
ORDER BY default_rate_percentage DESC;
-- ==========================================
-- STEP 2: SEGMENT ANALYSIS - DTI RANGES
-- ==========================================

WITH DTIBuckets AS (
    SELECT 
        l.loan_id,
        l.loan_status,
        CASE 
            WHEN l.dti_ratio < 20 THEN 'Under 20%'
            WHEN l.dti_ratio BETWEEN 20 AND 29.99 THEN '20-29.9%'
            WHEN l.dti_ratio BETWEEN 30 AND 39.99 THEN '30-39.9%'
            WHEN l.dti_ratio BETWEEN 40 AND 49.99 THEN '40-49.9%'
            WHEN l.dti_ratio >= 50 THEN '50%+'
            ELSE 'Other'
        END AS dti_bucket
    FROM loan_applications l
    INNER JOIN borrower_profiles b ON l.borrower_id = b.borrower_id
)
SELECT 
    dti_bucket,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) AS total_defaults,
    ROUND(SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_percentage
FROM DTIBuckets
GROUP BY dti_bucket
ORDER BY default_rate_percentage DESC;

-- ===========================================================
-- STEP 2: Average loan amount compared by loan status/purpose
-- ===========================================================

SELECT 
    loan_purpose,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) AS total_defaults,
    ROUND(SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_percentage
FROM loan_applications
GROUP BY loan_purpose
ORDER BY default_rate_percentage DESC;


SELECT 
    loan_status,
    COUNT(*) AS total_loans,
    ROUND(AVG(loan_amount), 2) AS avg_loan_amount
FROM loan_applications
GROUP BY loan_status;

-- ==========================================
-- STEP 2: EMPLOYMENT & INCOME RISK ANALYSIS
-- ==========================================

SELECT 
    b.employment_status,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN l.loan_status = 'Default' THEN 1 ELSE 0 END) AS total_defaults,
    ROUND(SUM(CASE WHEN l.loan_status = 'Default' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_percentage,
    ROUND(AVG(b.annual_income), 2) AS avg_annual_income
FROM loan_applications l
INNER JOIN borrower_profiles b ON l.borrower_id = b.borrower_id
GROUP BY b.employment_status
ORDER BY default_rate_percentage DESC;

-- ==========================================
-- STEP 3: CORRELATION / RISK FACTOR ANALYSIS
-- ==========================================
-- Comparing average risk metrics between Defaulted and Paid Off loans

SELECT 
    l.loan_status,
    COUNT(*) AS total_loans,
    ROUND(AVG(b.credit_score), 2) AS avg_credit_score,
    ROUND(AVG(l.dti_ratio), 2) AS avg_dti_ratio,
    ROUND(AVG(b.annual_income), 2) AS avg_annual_income,
    ROUND(AVG(l.interest_rate), 2) AS avg_interest_rate,
    ROUND(AVG(l.loan_amount), 2) AS avg_loan_amount
FROM loan_applications l
INNER JOIN borrower_profiles b ON l.borrower_id = b.borrower_id
GROUP BY l.loan_status;

-- ==========================================
-- STEP 4: DATA EXPORTS FOR EXCEL VISUALIZATIONS
-- ==========================================

-- Row-level export for DTI vs. Default Status Scatter Plot in Excel
-- (Translates text status into binary numeric: 1 for Default, 0 for Paid Off)
SELECT 
    l.dti_ratio AS dti_ratio,
    CASE WHEN l.loan_status = 'Default' THEN 1 ELSE 0 END AS default_numeric
FROM loan_applications l;