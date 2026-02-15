{{ config(materialized='table') }}

SELECT
    md5(customer_id || contract_type) AS contract_surrogate_key,
    customer_id,
    contract_type,
    payment_method,
    tenure_months,
    monthly_charges,
    churn_probability,
    CURRENT_DATE                     AS effective_from,
    '9999-12-31'::DATE               AS effective_to,
    TRUE                             AS is_current

FROM {{ ref('stg_telco_churn') }}
