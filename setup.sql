-- 1. Create and select the database
CREATE DATABASE IF NOT EXISTS loan_risk_analysis;
USE loan_risk_analysis;

-- 2. Create the borrower_profiles table
CREATE TABLE IF NOT EXISTS borrower_profiles (
    borrower_id INT PRIMARY KEY,
    credit_score INT,
    annual_income DECIMAL(12,2),
    employment_status VARCHAR(50),
    years_employed INT
);

-- 3. Create the loan_applications table
CREATE TABLE IF NOT EXISTS loan_applications (
    loan_id INT PRIMARY KEY,
    borrower_id INT,
    loan_amount DECIMAL(10,2),
    interest_rate DECIMAL(5,2),
    loan_purpose VARCHAR(50),
    dti_ratio DECIMAL(5,2),
    loan_status VARCHAR(20), -- 'Default' vs 'Paid' (or similar based on your CSV)
    FOREIGN KEY (borrower_id) REFERENCES borrower_profiles(borrower_id)
);