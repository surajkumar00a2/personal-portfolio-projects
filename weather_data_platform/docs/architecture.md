```
┌──────────────────────────────────────────────────────────────────────┐
│                         INGESTION LAYER                              │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  EventBridge Rule (Cron)  ──►  Lambda (Ingestion)                    │
│  (Every 6 hours)                │                                    │
│                                 ├──► API Call (Alpha Vantage/        │
│                                 │     CoinGecko/OpenWeather)         │
│                                 │                                    │
│                                 ├──► Schema Validation               │
│                                 ├──► Data Quality Checks             │
│                                 │                                    │
│                                 ▼                                    │
│                          S3 Bronze (Raw JSON)                        │
│                          s3://bucket/bronze/                         │
│                            date=YYYY-MM-DD/                          │
│                            hour=HH/                                  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ (S3 Event Notification)
                                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      TRANSFORMATION LAYER                            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  S3 Event ──► Lambda (Orchestrator) ──► Glue Job (PySpark)           │
│                                           │                          │
│                                           ├──► Clean & Transform     │
│                                           ├──► Deduplicate           │
│                                           ├──► Type Casting          │
│                                           ├──► Business Logic        │
│                                           │                          │
│                                           ▼                          │
│                                    S3 Silver (Parquet)               │
│                                    s3://bucket/silver/               │
│                                      year=YYYY/month=MM/day=DD/      │
│                                                                      │
│                                           │                          │
│                                           ▼                          │
│                                    Glue Job (Aggregation)            │
│                                           │                          │
│                                           ▼                          │
│                                    S3 Gold (Parquet)                 │
│                                    s3://bucket/gold/                 │
│                                      metric_type/year=YYYY/          │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                        ANALYTICS LAYER                               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Glue Crawler ──► Glue Data Catalog                                  │
│                         │                                            │
│                         ▼                                            │
│                   Athena Queries                                     │
│                   (SQL Analytics)                                    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    MONITORING & OBSERVABILITY                        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  CloudWatch Logs ◄── All Lambda & Glue Jobs                          │
│  CloudWatch Metrics ◄── Custom Metrics (row counts, failures)        │
│  SNS Topic ◄── Error Notifications                                   │
│  DLQ (Dead Letter Queue) ◄── Failed Lambda Events                    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```