
  create view "revenue_intelligence"."silver"."stg_online_retail__dbt_tmp"
    
    
  as (
    

WITH source AS (
    SELECT * FROM "revenue_intelligence"."bronze"."online_retail"
),

cleaned AS (
    SELECT
        TRIM(invoiceno)                            AS invoice_no,
        TRIM(stockcode)                            AS stock_code,
        TRIM(customerid::TEXT)                     AS customer_id,
        TRIM(country)                              AS country,
        INITCAP(TRIM(description))                 AS description,
        quantity::INT                              AS quantity,
        unitprice::NUMERIC(10,2)                   AS unit_price,
        invoicedate::DATE                          AS invoice_date,
        TO_CHAR(invoicedate::DATE,'YYYYMMDD')::INT AS date_key,

        CASE
            WHEN quantity < 0          THEN 'REFUND'
            WHEN invoiceno ILIKE 'C%'  THEN 'CREDIT_NOTE'
            ELSE 'SALE'
        END                                         AS transaction_type,

        CASE WHEN customerid IS NULL THEN TRUE ELSE FALSE END AS is_anonymous,
        CASE WHEN unitprice <= 0 THEN TRUE ELSE FALSE END AS is_zero_price,

        CASE WHEN stockcode IN
            ('POST','DOT','M','BANK CHARGES',
             'AMAZONFEE','PADS','D','CRUK')
             THEN TRUE ELSE FALSE END               AS is_non_product,

        _load_timestamp

    FROM source
    WHERE unitprice >= 0
),

deduped AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY invoice_no, stock_code, quantity, unit_price
            ORDER BY _load_timestamp
        ) AS rn
    FROM cleaned
)

SELECT *
FROM deduped
WHERE rn = 1
  AND NOT is_non_product
  AND NOT is_zero_price
  );