{{ config(materialized='table') }}

WITH retail AS (
    SELECT
        customer_id,
        MIN(invoice_date) AS first_seen,
        MAX(country)      AS country
    FROM {{ ref('stg_online_retail') }}
    WHERE NOT is_anonymous
    GROUP BY customer_id
),

crm AS (
    SELECT
        customer_id,
        customer_segment,
        churn_flag,
        churn_probability,
        CASE
            WHEN total_charges >= 5000 THEN 'VIP'
            WHEN total_charges >= 2000 THEN 'HIGH'
            WHEN total_charges >= 500  THEN 'MID'
            ELSE 'LOW'
        END AS ltv_band
    FROM {{ ref('stg_telco_churn') }}
)

SELECT
    md5(r.customer_id)                     AS customer_surrogate_key,
    r.customer_id,
    r.country,
    r.first_seen,
    COALESCE(c.customer_segment, 'UNKNOWN') AS segment,
    COALESCE(c.churn_flag, FALSE)          AS churn_flag,
    COALESCE(c.churn_probability, 0.10)    AS churn_probability,
    COALESCE(c.ltv_band, 'MID')            AS ltv_band,
    CURRENT_DATE                           AS effective_from,
    '9999-12-31'::DATE                     AS effective_to,
    TRUE                                   AS is_current

FROM retail r
LEFT JOIN crm c USING (customer_id)
