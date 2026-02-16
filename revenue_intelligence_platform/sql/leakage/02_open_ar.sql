-- ═══════════════════════════════════════════════════════════════
-- LEAKAGE VECTOR 2: Open Accounts Receivable
-- Method: Invoices with no matched payment record
-- Business risk: Revenue booked but cash never collected
-- Note: UCI dataset has no payment table — we simulate using
--       invoices older than 30 days as "expected paid"
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW gold.v_open_ar AS

SELECT
    fi.invoice_no,
    fi.invoice_date,
    fi.country,
    dc.segment,
    ROUND(SUM(fi.net_revenue)::numeric, 2)      AS invoice_total,
    CURRENT_DATE - fi.invoice_date              AS days_since_invoice,
    CASE
        WHEN CURRENT_DATE - fi.invoice_date > 90  THEN '90+ Days'
        WHEN CURRENT_DATE - fi.invoice_date > 60  THEN '61-90 Days'
        WHEN CURRENT_DATE - fi.invoice_date > 30  THEN '31-60 Days'
        ELSE                                           '0-30 Days'
    END                                         AS aging_bucket,
    CASE
        WHEN CURRENT_DATE - fi.invoice_date > 90
            THEN 'WRITE-OFF RISK'
        WHEN CURRENT_DATE - fi.invoice_date > 60
            THEN 'ESCALATE TO COLLECTIONS'
        WHEN CURRENT_DATE - fi.invoice_date > 30
            THEN 'FOLLOW-UP REQUIRED'
        ELSE    'WITHIN TERMS'
    END                                         AS collection_status

FROM gold.fact_invoice fi
LEFT JOIN gold.dim_customer dc
    ON fi.customer_surrogate_key = dc.customer_surrogate_key

WHERE fi.transaction_type = 'SALE'
  AND fi.net_revenue > 0
  AND fi.customer_surrogate_key IS NOT NULL

GROUP BY
    fi.invoice_no, fi.invoice_date, fi.country,
    dc.segment, CURRENT_DATE - fi.invoice_date;
