-- Monthly gross and net revenue with invoice count
-- Source: gold.fact_invoice + gold.dim_date

SELECT
    TO_CHAR(invoice_date, 'YYYY-MM')            AS month,
    COUNT(DISTINCT invoice_no)                  AS invoice_count,
    ROUND(SUM(line_revenue)::numeric, 2)        AS gross_revenue,
    ROUND(SUM(net_revenue)::numeric, 2)         AS net_revenue,
    COUNT(DISTINCT customer_surrogate_key)      AS unique_customers
FROM gold.fact_invoice
WHERE transaction_type = 'SALE'
GROUP BY 1
ORDER BY 1;
