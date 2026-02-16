{{ config(materialized='table') }}

WITH staging AS (
    SELECT * FROM {{ ref('stg_online_retail') }}
    WHERE transaction_type IN ('SALE', 'REFUND', 'CREDIT_NOTE')
),

with_keys AS (
    SELECT
        s.invoice_no,
        s.stock_code,
        s.transaction_type,
        s.quantity,
        s.unit_price,
        0::NUMERIC                              AS discount_amount,
        s.quantity * s.unit_price               AS line_revenue,
        s.quantity * s.unit_price               AS net_revenue,
        s.country,
        s.date_key,
        s.invoice_date,
        dc.customer_surrogate_key,
        dp.product_surrogate_key,
        FALSE                                   AS is_void,
        s._load_timestamp

    FROM staging s

    LEFT JOIN gold.dim_customer dc
        ON s.customer_id = dc.customer_id
        AND dc.is_current = TRUE

    LEFT JOIN gold.dim_product dp
        ON s.stock_code = dp.stock_code
        AND dp.is_current = TRUE
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY invoice_date, invoice_no
    )                                           AS invoice_line_key,
    invoice_no,
    invoice_date,
    stock_code,
    customer_surrogate_key,
    product_surrogate_key,
    date_key,
    transaction_type,
    quantity,
    unit_price,
    discount_amount,
    line_revenue,
    net_revenue,
    country,
    is_void,
    _load_timestamp

FROM with_keys