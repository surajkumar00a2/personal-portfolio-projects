# Data Quality Issues — UCI Online Retail

| Issue | Scale | Decision |
|---|---|---|
| CustomerID nulls | ~25% of rows | Exclude from customer analysis; track in audit |
| Negative Quantity (refunds) | ~8K rows | Classify as REFUND in staging model |
| InvoiceNo starting with "C" | subset | Classify as CREDIT_NOTE |
| UnitPrice = 0 | ~2K rows | Exclude; flag as is_zero_price |
| Non-product StockCodes | ~2K rows | Exclusion list: POST, DOT, M, BANK CHARGES, etc |
| Duplicate rows | ~5K rows | Deduplicate via ROW_NUMBER() in Silver |

## Key Numbers (fill in from your profiling output)
- Total rows: 541,909
- CustomerID null %: ___
- Refund rows: ___
- Refund revenue: £___
- Duplicate rows: ___
- UK revenue share: ___% of total
