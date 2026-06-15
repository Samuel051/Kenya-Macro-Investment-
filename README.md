# Kenya Macro Investment Dashboard: Buy-Side Capital Allocation Model

An institutional-grade, two-page Power BI dashboard designed for buy-side investment analysts to stress-test historical country risk and evaluate medium-term capital deployment strategies in Kenya (2015–2029).

## 📊 Dashboard Architecture Overview
The analytics platform is structurally separated into two focused, high-density pages to mimic a corporate transaction data-room:
1. **Page 1: Kenya Macro Investment Review: Sovereign Risk & Structural Credit Shocks (2015-2024)**
   * Isolates historical policy impacts, including the interest rate cap era, private credit freezes, and monetary tightening cycles.
2. **Page 2: Medium-Term Capital Allocation Strategy & Sector Alpha Horizon (2025-2029)**
   * Projects top-down structural growth trajectories and identifies macroeconomic inflection points utilizing localized IMF and World Bank baseline outlook targets.

---

## 🛠️ Technology Stack & Engineering Pipeline
* **Database Backend:** PostgreSQL (pgAdmin 4)
* **Data Transformation:** SQL Schema Views & Data Pipe Construction
* **BI Engine:** Power BI Desktop
* **Modeling & Metrics:** Advanced DAX (Data Analysis Expressions)

---

## 💾 Database Implementation (SQL View)
To ensure clean data separation without breaking old schemas, a unified, forward-looking database view was engineered to interpolate 5 years of medium-term forecasting metrics over the historical backbone.

```sql
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
VALUES 
(2025, 4.9, 67.7, 15.4, 5.8, 1.8, 'FORECAST'),
(2026, 4.5, 67.5, 15.3, 5.9, 1.9, 'FORECAST'),
(2027, 4.7, 63.2, 13.8, 6.1, 2.1, 'FORECAST'),
(2028, 5.0, 59.4, 11.9, 6.4, 2.3, 'FORECAST'),
(2029, 5.0, 55.0, 10.5, 6.5, 2.5, 'FORECAST');
```

---

## 🧮 Semantic Layer & Advanced DAX Calculations
To drive high-performance, dynamic KPI cards that react cleanly to localized year slicers without cross-contaminating historical averages, the following measures were deployed:

### Dynamic Forecast GDP KPI
```dax
Dynamic Forecast GDP = AVERAGE('v_ib_kenya_full_forecast_2029'[gdp_growth_pct]) / 100
```

### Dynamic Forecast Debt to GDP Anchor
```dax
Dynamic Forecast Debt to GDP = AVERAGE('v_ib_kenya_full_forecast_2029'[debt_to_gdp_pct]) / 100
```

### Dynamic Forecast Banking Sector NPL (Asset Quality)
```dax
Dynamic Forecast NPL = AVERAGE('v_ib_kenya_full_forecast_2029'[npl_pct]) / 100
```
*(All KPI measures are formatted as Percentages within the Power BI data model)*

---

## 📈 Strategic Insights Explored
* **Asset Quality Inflection:** Tracking banking sector Non-Performing Loans (NPLs) as they cool from a historical cycle peak of 17.6% down to a projected 10.5% by 2029.
* **Sovereign Debt De-risking:** Visualizing the sovereign debt consolidation glidepath down toward Kenya's long-term 55.0% Debt-to-GDP baseline target.
* **Sector Alpha Rotation:** Demonstrating the widening growth delta of asset-light **ICT** expansion over capital-intensive manufacturing under high interest rate regimes.

---
*Developed as a professional portfolio asset for corporate finance, private equity, and investment banking data analytics.*
