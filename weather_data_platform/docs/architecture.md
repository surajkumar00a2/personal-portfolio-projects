# Architecture Documentation

## System Architecture
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INGESTION LAYER                                │
│                                                                             │
│  EventBridge (Cron)          Lambda (Python 3.11)                           │
│  Every 6 hours        ────►  • Fetch from OpenWeatherMap API                │
│  (00:00, 06:00,              • Schema validation                            │
│   12:00, 18:00)              • Quality metrics calculation                  │
│                              • Dual write: Data + Metrics                   │
│                                                                             │
│                              ↓                        ↓                     │
│                      S3 Bronze (JSON)        S3 Metrics (Parquet)           │
│                      Raw API responses       Quality events                 │
│                      date=YYYY-MM-DD/        date=YYYY-MM-DD/               │
│                      hour=HH/                hour=HH/                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                              │
                              │ (S3 Event + Schedule)
                              ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TRANSFORMATION LAYER                                │
│                                                                             │
│  Glue Workflow: weather-data-pipeline                                       │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Trigger: SCHEDULED (30min after ingestion)                          │    │
│  │                                                                     │    │
│  │ Job: bronze-to-silver-transform (PySpark)                           │    │
│  │ • Read JSON from Bronze                                             │    │
│  │ • Flatten nested structure                                          │    |
│  │ • Deduplicate (city + timestamp)                                    │    │
│  │ • Add quality flags                                                 │    │
│  │ • Write Parquet to Silver                                           │    │
│  │                                                                     │    │
│  │ Output: S3 Silver (Parquet) - year=YYYY/month=MM/day=DD/            │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                              │
│                              │ (On Success)                                 │
│                              ▼                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Trigger: CONDITIONAL (on Bronze→Silver success)                     │    │
│  │                                                                     │    │
│  │ Job: silver-to-gold-aggregations (PySpark)                          │    │
│  │ • Read Parquet from Silver                                          │    │
│  │ • Create 3 Gold tables:                                             │    │
│  │   1. weather_daily_summary (daily aggregations)                     │    │
│  │   2. quality_scorecard_daily (quality metrics)                      │    │
│  │   3. reliability_trends_weekly (weekly trends)                      │    │
│  │ • Write Parquet to Gold                                             │    │
│  │                                                                     │    │
│  │ Output: S3 Gold (Parquet) - year=YYYY/month=MM/ (3 tables)          │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                              │
                              │ (Daily 04:00)
                              ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ANALYTICS LAYER                                    │
│                                                                             │
│  Glue Crawler (Scheduled: Daily 04:00)                                      │
│  • Discovers new partitions                                                 │
│  • Updates Glue Data Catalog                                                │
│                                                                             │
│  Glue Data Catalog (Database: weather_data_lake)                            │
│  ├─ silver_weather_data                                                     │
│  ├─ gold_weather_daily_summary                                              │
│  ├─ gold_quality_scorecard_daily                                            │
│  ├─ gold_reliability_trends_weekly                                          │
│  └─ metrics_quality_events                                                  │
│                                                                             │
│  Amazon Athena (Serverless SQL)                                             │
│  • Query all layers with SQL                                                │
│  • Partition projection for fast queries                                    │
│  • 5 pre-built views for common patterns                                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      MONITORING & OBSERVABILITY                             │
│                                                                             │
│  CloudWatch Logs                    CloudWatch Metrics                      │
│  • /aws/lambda/weather-ingestion    • RecordsIngested                       │
│  • /aws-glue/jobs/...               • OverallQualityScore                   │
│                                      • APILatency                           │
│  CloudWatch Dashboard               • SchemaChanges                         │
│  • data-quality-monitoring          • MissingFieldsPerent                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### 1. Ingestion (Every 6 hours)
- **00:00, 06:00, 12:00, 18:00 UTC** - EventBridge triggers Lambda
- Lambda fetches weather data for 3 cities (London, New York, Tokyo)
- Validates schema, calculates quality metrics
- Writes:
  - Raw JSON → `s3://bucket/data/bronze/date=YYYY-MM-DD/hour=HH/`
  - Parquet metrics → `s3://bucket/metrics/quality/date=YYYY-MM-DD/hour=HH/`

### 2. Bronze → Silver (30 minutes after ingestion)
- **00:30, 06:30, 12:30, 18:30 UTC** - Glue job triggered by workflow
- Reads Bronze JSON files
- Transforms:
  - Flatten nested JSON structure
  - Convert temperatures Kelvin → Celsius
  - Deduplicate by (city_id, observation_timestamp)
  - Add quality flags
- Writes: `s3://bucket/data/silver/year=YYYY/month=MM/day=DD/` (Parquet)

### 3. Silver → Gold (Immediately after Silver)
- Conditional trigger (on Bronze→Silver success)
- Reads Silver Parquet
- Creates 3 aggregated tables:
  - **weather_daily_summary** - Daily weather stats per city
  - **quality_scorecard_daily** - Daily quality metrics
  - **reliability_trends_weekly** - Weekly trends
- Writes: `s3://bucket/data/gold/{table}/year=YYYY/month=MM/` (Parquet)

### 4. Catalog Update (Daily 04:00)
- Glue Crawler discovers new partitions
- Updates Glue Data Catalog
- Tables become queryable in Athena

---

## Technology Stack

| Layer | Service | Purpose |
|-------|---------|---------|
| **Ingestion** | Lambda (Python 3.11) | API calls, validation, quality checks |
| **Scheduling** | EventBridge | Trigger Lambda every 6 hours |
| **Storage** | S3 | Data lake (Bronze/Silver/Gold) |
| **Transformation** | Glue (PySpark) | ETL jobs |
| **Orchestration** | Glue Workflows | Job sequencing |
| **Catalog** | Glue Data Catalog | Schema management |
| **Analytics** | Athena | Serverless SQL queries |
| **Monitoring** | CloudWatch | Logs, metrics, dashboards |

---

## Key Design Decisions

### 1. Serverless Architecture
**Decision**: Use only serverless services (Lambda, Glue, Athena)
**Rationale**: 
- Zero idle costs (scales to zero)
- No infrastructure management
- Pay only for actual usage
- Auto-scaling built-in

**Alternative Considered**: EC2 + Spark cluster
**Why Rejected**: $180/month minimum for 24/7 operation vs $1.61/month serverless

---

### 2. Medallion Architecture (Bronze/Silver/Gold)
**Decision**: Three-layer data lake pattern
**Rationale**:
- **Bronze**: Raw data preservation (immutable, reprocessable)
- **Silver**: Clean data for analysis (validated, deduplicated)
- **Gold**: Business-ready aggregations (optimized for queries)

**Benefit**: Clear separation of concerns, easy debugging

---

### 3. Parquet over JSON
**Decision**: Use Parquet for Silver/Gold/Metrics layers
**Rationale**:
- 70% smaller file size
- Columnar format = faster queries
- Type safety enforced
- Lower Athena costs (less data scanned)

**Measurement**: 
- Bronze JSON: 2.5 KB per record
- Silver Parquet: 0.8 KB per record
- **68% reduction**

---

### 4. Quality-First Design
**Decision**: Track data quality as first-class metric
**Rationale**:
- Detect API failures before they break dashboards
- Schema drift detection prevents silent errors
- Volume anomalies catch data pipeline issues
- Quality score (0-100) provides single KPI

**Uniqueness**: Most data lakes only track "did it run?". This tracks "is data reliable?"

---

### 5. No Bronze Athena Table
**Decision**: Don't create Athena table for Bronze layer
**Rationale**:
- Bronze is raw JSON (slow to query, inefficient)
- Used only for reprocessing, not analytics
- Forces analysts to use clean Silver/Gold layers
- Saves on Athena query costs

---

## Scalability

### Current Capacity
- **Ingestion**: 4 runs/day × 3 cities = 12 API calls/day
- **Data Volume**: ~30 MB/month
- **Cost**: $1.61/month

### Scaling to Production (100 cities, hourly)
- **Ingestion**: 24 runs/day × 100 cities = 2,400 API calls/day
- **Changes Required**:
  - Lambda: Fan-out pattern (SNS → parallel Lambdas)
  - Glue: Increase DPU from 2 → 10
  - S3: Add city partition to Silver/Gold
  - Athena: Partition projection with city dimension
- **Projected Cost**: ~$40/month (still serverless)

**No architectural changes needed** - serverless scales horizontally

---

## Cost Optimization Strategies

### 1. S3 Lifecycle Policies
- Bronze data → Deleted after 30 days (raw data not needed long-term)
- Silver data → Moved to IA storage after 90 days
- Metrics → Deleted after 90 days
- **Savings**: ~60% reduction in storage costs after 30 days

### 2. Partition Pruning
- All tables partitioned by time dimensions
- Athena queries scan only relevant partitions
- **Example**: `WHERE year=2026 AND month=1` scans 1/12th of data
- **Savings**: 90% reduction in query costs

### 3. Parquet Compression
- Snappy compression on all Parquet files
- **Savings**: 68% storage reduction vs JSON

### 4. Glue Job Bookmarks
- Bronze→Silver uses bookmarks to process only new files
- Avoids reprocessing entire dataset
- **Savings**: 95% reduction in Glue execution time

---

## Monitoring Strategy

### CloudWatch Metrics (Custom)
```
DataPlatform/Quality
├─ RecordsIngested (Count per city)
├─ OverallQualityScore (0-100)
├─ CompletenessScore (0-100)
├─ ConsistencyScore (0-100)
├─ APILatency (Milliseconds)
├─ MissingFieldsPercent (%)
└─ SchemaChanges (Count)
```

### CloudWatch Dashboard
- Quality score trend (7 days)
- Volume ingestion rate
- API latency (P50/P99)
- Schema stability indicator

### Athena for Retrospective Analysis
```sql
-- Identify quality degradation patterns
SELECT date, overall_quality_score
FROM gold_quality_scorecard_daily
WHERE overall_quality_score < 80;

-- Track schema drift history
SELECT * FROM v_schema_drift_history;
```

---

## Security Considerations

### Implemented
- ✅ IAM roles with least privilege
- ✅ API keys in Lambda environment variables
- ✅ S3 bucket policies (private by default)
- ✅ Glue job roles isolated per function

### Production Enhancements
- KMS encryption for S3 buckets
- Secrets Manager for API key rotation
- VPC endpoints for private AWS service access
- CloudTrail for audit logging
- Data retention policies (GDPR compliance)

---

## Failure Handling

### Lambda Ingestion Failures
- **Retry**: 3 attempts with exponential backoff
- **Partial Success**: Process remaining cities even if one fails
- **DLQ**: Dead Letter Queue for investigation
- **Alerting**: CloudWatch metric spike triggers notification

### Glue Job Failures
- **Auto-Retry**: 1 retry configured
- **Bookmarks**: Resume from last successful run
- **Monitoring**: CloudWatch logs capture full stack trace
- **Fallback**: Can manually reprocess from Bronze layer

### API Failures
- **Detection**: HTTP status code monitoring
- **Metrics**: APIAvailability score drops to 0
- **Response**: Continue processing other cities
- **Recovery**: Next scheduled run (6 hours later) retries