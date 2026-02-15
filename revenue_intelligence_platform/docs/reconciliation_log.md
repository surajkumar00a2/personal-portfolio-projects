# Reconciliation Log

## Bronze vs Gold — Day 4

| Layer | Row Count | Total Revenue |
|---|---|---|
| Bronze Raw | ___ | £___ |
| Gold SALE | ___ | £___ |
| **Delta %** | | **___%** |

## Gap Explained By
- ~25% null CustomerID rows excluded from customer analysis
- ~2K zero-price rows excluded (test/admin entries)
- ~2K non-product StockCodes excluded (POST, DOT, BANK CHARGES etc.)
- ~5K duplicate rows deduplicated in Silver

## Status: PASSED / FAILED
