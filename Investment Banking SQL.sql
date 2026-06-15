select current_database();

-- DROP TABLES FIRST IF THEY ACCIDENTALLY EXIST TO START CLEAN
DROP TABLE IF EXISTS fact_sovereign_debt CASCADE;
DROP TABLE IF EXISTS fact_banking_stability CASCADE;
DROP TABLE IF EXISTS fact_monetary_indicators CASCADE;
DROP TABLE IF EXISTS fact_gdp_growth CASCADE;
DROP TABLE IF EXISTS dim_calendar CASCADE;

-- 1. Create the Calendar Dimension Table (Auto-calculates the decade)
CREATE TABLE dim_calendar (
    year_id INT PRIMARY KEY,
    decade INT GENERATED ALWAYS AS ((year_id / 10) * 10) STORED
);

-- 2. Create the GDP and Sector Growth Fact Table
CREATE TABLE fact_gdp_growth (
    year_id INT PRIMARY KEY REFERENCES dim_calendar(year_id),
    gdp_growth_pct NUMERIC(4,2),
    agriculture_growth_pct NUMERIC(4,2),
    manufacturing_growth_pct NUMERIC(4,2),
    financial_services_growth_pct NUMERIC(4,2),
    ict_growth_pct NUMERIC(4,2),
    real_estate_growth_pct NUMERIC(4,2)
);

-- 3. Create the Monetary and Markets Fact Table
CREATE TABLE fact_monetary_indicators (
    year_id INT PRIMARY KEY REFERENCES dim_calendar(year_id),
    inflation_pct NUMERIC(4,2),
    central_bank_rate_pct NUMERIC(4,2),
    avg_lending_rate_pct NUMERIC(4,2),
    t_bill_91_day_pct NUMERIC(4,2),
    kes_usd_exchange_rate NUMERIC(6,2)
);


-- 4. Create the Commercial Banking Stability Fact Table
CREATE TABLE fact_banking_stability (
    year_id INT PRIMARY KEY REFERENCES dim_calendar(year_id),
    total_assets_kes_trillion NUMERIC(4,2),
    total_deposits_kes_trillion NUMERIC(4,2),
    private_credit_growth_pct NUMERIC(4,2),
    npl_pct NUMERIC(4,2)
);


-- 5. Create the Fiscal Policy and Sovereign Debt Fact Table
CREATE TABLE fact_sovereign_debt (
    year_id INT PRIMARY KEY REFERENCES dim_calendar(year_id),
    total_public_debt_trillion NUMERIC(4,2),
    debt_to_gdp_pct NUMERIC(4,2)
);

--- Inserting data into dim_calendar
INSERT INTO dim_calendar (year_id) VALUES 
(2015), (2016), (2017), (2018), (2019), 
(2020), (2021), (2022), (2023), (2024);


--- The rest of the data for each table were imported in csv format


SELECT 
    c.year_id AS year,
    g.gdp_growth_pct AS gdp_growth,
    m.inflation_pct AS inflation,
    m.kes_usd_exchange_rate AS fx_rate,
    b.npl_pct AS banking_npl,
    d.debt_to_gdp_pct AS debt_gdp_ratio
FROM dim_calendar c
INNER JOIN fact_gdp_growth g ON c.year_id = g.year_id
INNER JOIN fact_monetary_indicators m ON c.year_id = m.year_id
INNER JOIN fact_banking_stability b ON c.year_id = b.year_id
INNER JOIN fact_sovereign_debt d ON c.year_id = d.year_id
ORDER BY year ASC;


------ EDA Analysis


---The Real Lending Rate (Inflation-Adjusted Cost of Capital).
SELECT 
    year_id AS year,
    avg_lending_rate_pct AS nominal_lending_rate,
    inflation_pct AS inflation,
    -- Calculate the true cost of borrowing
    (avg_lending_rate_pct - inflation_pct) AS real_lending_rate
FROM fact_monetary_indicators
ORDER BY year ASC;



--- Let's Test the Banking Stress Index (Credit Risk Score)
SELECT 
    year_id AS year,
    npl_pct AS non_performing_loans_pct,
    -- Financial modeling logic to score credit distress
    CASE 
        WHEN npl_pct < 8.0 THEN 'LOW RISK (Healthy Credit Market)'
        WHEN npl_pct BETWEEN 8.0 AND 12.0 THEN 'MODERATE RISK (Monitor Closely)'
        WHEN npl_pct BETWEEN 12.0 AND 15.0 THEN 'HIGH RISK (Stressed Asset Quality)'
        ELSE 'CRITICAL DISTRESS (Severe Systemic Risk)'
    END AS credit_risk_score
FROM fact_banking_stability
ORDER BY year ASC;



--- Modeling Sovereign Debt & Liquidity Crowding Out
SELECT 
    d.year_id AS year,
    d.debt_to_gdp_pct,
    m.t_bill_91_day_pct AS government_yield,
    b.private_credit_growth_pct AS lending_to_businesses,
    -- Calculate the "Crowding Out" pressure index
    ROUND((m.t_bill_91_day_pct / NULLIF(b.private_credit_growth_pct, 0)), 2) AS crowding_out_ratio
FROM fact_sovereign_debt d
JOIN fact_monetary_indicators m ON d.year_id = m.year_id
JOIN fact_banking_stability b ON d.year_id = b.year_id
ORDER BY year ASC;




----Packaging the EDA into a Unified SQL View for Power BI
CREATE OR REPLACE VIEW v_ib_kenya_macro_model AS
SELECT 
    c.year_id AS year,
    c.decade,
    g.gdp_growth_pct,
    g.agriculture_growth_pct,
    g.manufacturing_growth_pct,
    g.financial_services_growth_pct,
    g.ict_growth_pct,
    g.real_estate_growth_pct,
    m.inflation_pct,
    m.central_bank_rate_pct,
    m.avg_lending_rate_pct,
    m.t_bill_91_day_pct,
    m.kes_usd_exchange_rate,
    b.total_assets_kes_trillion,
    b.total_deposits_kes_trillion,
    b.private_credit_growth_pct,
    b.npl_pct,
    d.total_public_debt_trillion,
    d.debt_to_gdp_pct,
    
    -- Our 3 Modeled Portoflio Ratios
    (m.avg_lending_rate_pct - m.inflation_pct) AS real_lending_rate,
    ROUND((b.total_deposits_kes_trillion / NULLIF(b.total_assets_kes_trillion, 0)) * 100, 2) AS deposit_to_asset_ratio,
    
    CASE 
        WHEN b.npl_pct < 8.0 THEN 'LOW RISK'
        WHEN b.npl_pct BETWEEN 8.0 AND 12.0 THEN 'MODERATE RISK'
        WHEN b.npl_pct BETWEEN 12.0 AND 15.0 THEN 'HIGH RISK'
        ELSE 'CRITICAL DISTRESS'
    END AS credit_risk_score

FROM dim_calendar c
JOIN fact_gdp_growth g ON c.year_id = g.year_id
JOIN fact_monetary_indicators m ON c.year_id = m.year_id
JOIN fact_banking_stability b ON c.year_id = b.year_id
JOIN fact_sovereign_debt d ON c.year_id = d.year_id;



select * from v_ib_kenya_macro_model;


---- Unlocking the Sectoral & Financial Engine Insights
SELECT 
     year,
    -- Central Bank & Debt context
    central_bank_rate_pct AS cbr,
    total_public_debt_trillion AS sovereign_debt_kes_tn,
        -- High-Growth / Structural Sectors
    ict_growth_pct AS ict_growth,
    real_estate_growth_pct AS real_estate_growth,
    financial_services_growth_pct AS fin_services_growth,
        -- Volatile / Production Sectors
    agriculture_growth_pct AS agri_growth,
    manufacturing_growth_pct AS mfg_growth,
        -- System Liquidity Check (Assets vs Deposits)
    (total_assets_kes_trillion - total_deposits_kes_trillion) AS asset_deposit_gap_tn
FROM v_ib_kenya_macro_model
ORDER BY year ASC;


----FORECASTING
CREATE OR REPLACE VIEW v_ib_kenya_full_forecast_2029 AS
-- PART A: EXPOSE EXTRACTED HISTORICAL BACKBONE (2015-2024)
SELECT 
    year, 
    gdp_growth_pct, 
    debt_to_gdp_pct, 
    npl_pct, 
    ict_growth_pct, 
    manufacturing_growth_pct, 
    'HISTORICAL' AS timeline_phase
FROM v_ib_kenya_macro_model

UNION ALL

-- PART B: INTERPOLATE STRUCTURAL MEDIUM-TERM METRICS (2025-2029)
-- Schema sequence aligns to Part A columns
VALUES 
(2025, 4.9, 67.7, 15.4, 5.8, 1.8, 'FORECAST'),
(2026, 4.5, 67.5, 15.3, 5.9, 1.9, 'FORECAST'),
(2027, 4.7, 63.2, 13.8, 6.1, 2.1, 'FORECAST'),
(2028, 5.0, 59.4, 11.9, 6.4, 2.3, 'FORECAST'),
(2029, 5.0, 55.0, 10.5, 6.5, 2.5, 'FORECAST');


select * from v_ib_kenya_full_forecast_2029;




