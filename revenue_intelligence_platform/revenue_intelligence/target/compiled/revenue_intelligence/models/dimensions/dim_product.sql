

WITH products AS (
    SELECT
        stock_code,
        MAX(description) AS description,
        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY unit_price) AS list_price
    FROM "revenue_intelligence"."silver"."stg_online_retail"
    WHERE transaction_type = 'SALE'
    GROUP BY stock_code
)

SELECT
    md5(stock_code)                  AS product_surrogate_key,
    stock_code,
    description,
    list_price,
    CURRENT_DATE                     AS effective_from,
    '9999-12-31'::DATE               AS effective_to,
    TRUE                             AS is_current

FROM products