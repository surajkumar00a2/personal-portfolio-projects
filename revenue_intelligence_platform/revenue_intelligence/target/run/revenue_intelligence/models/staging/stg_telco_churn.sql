
  create view "revenue_intelligence"."silver"."stg_telco_churn__dbt_tmp"
    
    
  as (
    

WITH source AS (
    SELECT * FROM "revenue_intelligence"."bronze"."telco_churn"
)

SELECT
    customerid                                AS customer_id,
    tenure::INT                               AS tenure_months,
    contract                                  AS contract_type,
    paymentmethod                             AS payment_method,
    monthlycharges::NUMERIC(10,2)             AS monthly_charges,
    NULLIF(TRIM(totalcharges), '')::NUMERIC(12,2) AS total_charges,

    CASE WHEN churn = 'Yes'
         THEN TRUE ELSE FALSE END             AS churn_flag,

    CASE
        WHEN contract = 'Month-to-month' AND tenure::INT < 12 THEN 0.45
        WHEN contract = 'Month-to-month' AND tenure::INT < 24 THEN 0.28
        WHEN contract = 'Month-to-month' THEN 0.18
        WHEN contract = 'One year' THEN 0.12
        WHEN contract = 'Two year' THEN 0.05
        ELSE 0.10
    END                                       AS churn_probability,

    CASE
        WHEN monthlycharges >= 90 THEN 'VIP'
        WHEN monthlycharges >= 60 THEN 'HIGH'
        WHEN monthlycharges >= 30 THEN 'MID'
        ELSE 'LOW'
    END                                       AS customer_segment

FROM source
  );