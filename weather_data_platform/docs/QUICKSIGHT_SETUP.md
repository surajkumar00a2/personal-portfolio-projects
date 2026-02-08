# QuickSight Dashboard Setup Guide

## Overview

This guide walks through creating visual dashboards in Amazon QuickSight for the Weather Data Platform.

**What you'll build:**
- Quality monitoring dashboard
- Weather analytics dashboard
- Schema stability tracker
- Real-time scorecard

---

## Prerequisites

### 1. Sign Up for QuickSight

1. Go to [QuickSight Console](https://quicksight.aws.amazon.com/)
2. Click "Sign up for QuickSight"
3. Choose "Standard Edition" (or Enterprise for advanced features)
4. Grant permissions:
   - ✅ Amazon Athena
   - ✅ Amazon S3 (select your bucket)
5. Finish setup ($9/month per user, first 30 days free)

### 2. Create Athena Data Source

1. In QuickSight, click **Datasets** → **New dataset**
2. Choose **Athena**
3. Data source name: `weather-data-lake`
4. Athena workgroup: `primary` (or your custom workgroup)
5. Click **Create data source**

---

## Dashboard 1: Data Quality Monitoring

### Create Dataset

1. **New dataset** → **Athena**
2. Database: `weather_data_lake`
3. Table: `qs_quality_trends_30d` (view we created)
4. Click **Select**
5. Choose **Directly query your data**
6. Name: `Quality Trends`
7. Click **Visualize**

### Create Visuals

#### Visual 1: Quality Score Trend
- **Type**: Line chart
- **X-axis**: `date`
- **Value**: `overall_quality_score`
- **Color**: `quality_status`
- **Title**: "Overall Quality Score (Last 30 Days)"
- **Settings**:
  - Y-axis range: 0-100
  - Add reference line at 80 (minimum acceptable)

#### Visual 2: Quality Dimensions
- **Type**: Line chart
- **X-axis**: `date`
- **Values**: 
  - `completeness_score`
  - `consistency_score`
  - `timeliness_score`
- **Title**: "Quality Dimensions Breakdown"

#### Visual 3: Issues Count
- **Type**: Bar chart
- **Y-axis**: `date`
- **Value**: `records_with_missing_fields`
- **Title**: "Records with Missing Fields"
- **Color**: Red gradient

#### Visual 4: Schema Changes Alert
- **Type**: KPI
- **Value**: `SUM(schema_changes_detected)`
- **Title**: "Schema Changes Detected"
- **Conditional formatting**: 
  - Green if 0
  - Red if > 0

### Save Dashboard
- Click **Save as** → "Data Quality Monitoring"
- Set refresh schedule: Daily at 5:00 AM

---

## Dashboard 2: Weather Analytics

### Create Dataset

1. **New dataset** → **Athena**
2. Database: `weather_data_lake`
3. Table: `qs_weather_summary_7d`
4. Name: `Weather Summary`
5. **Visualize**

### Create Visuals

#### Visual 1: Temperature Comparison
- **Type**: Line chart
- **X-axis**: `date`
- **Value**: `avg_temperature_celsius`
- **Color**: `city_name`
- **Title**: "Temperature Trends by City"

#### Visual 2: Temperature Range
- **Type**: Vertical bar chart
- **X-axis**: `city_name`
- **Values**:
  - `min_temperature_celsius` (bottom)
  - `max_temperature_celsius` (top)
- **Title**: "Daily Temperature Range"

#### Visual 3: Humidity Levels
- **Type**: Heat map
- **Rows**: `city_name`
- **Columns**: `date`
- **Values**: `avg_humidity_percent`
- **Title**: "Humidity Heat Map"
- **Color**: Blue gradient (darker = higher humidity)

#### Visual 4: Weather Conditions
- **Type**: Donut chart
- **Group by**: `dominant_weather_condition`
- **Value**: `COUNT(*)`
- **Title**: "Most Common Weather Conditions"

### Save Dashboard
- Name: "Weather Analytics"
- Refresh: Hourly during business hours

---

## Dashboard 3: City Comparison

### Create Dataset

1. **New dataset** → **Athena**
2. Table: `qs_city_comparison_monthly`
3. Name: `City Comparison`
4. **Visualize**

### Create Visuals

#### Visual 1: Average Temperature by City
- **Type**: Horizontal bar chart
- **Y-axis**: `city_name`
- **Value**: `avg_monthly_temp`
- **Color**: Temperature gradient
- **Title**: "Average Monthly Temperature"

#### Visual 2: Temperature Extremes
- **Type**: Clustered bar chart
- **X-axis**: `city_name`
- **Values**: 
  - `coldest_temp`
  - `warmest_temp`
- **Title**: "Temperature Extremes"

#### Visual 3: Data Availability
- **Type**: Tree map
- **Group by**: `city_name`
- **Size**: `total_observations`
- **Color**: `days_of_data`
- **Title**: "Data Coverage by City"

---

## Dashboard 4: Schema Stability

### Create Dataset

1. **New dataset** → **Athena**
2. Table: `qs_schema_stability_90d`
3. Name: `Schema Stability`
4. **Visualize**

### Create Visuals

#### Visual 1: Stability Timeline
- **Type**: Vertical stacked bar chart
- **X-axis**: `week_start_date`
- **Value**: Count
- **Color**: `stability_status`
- **Title**: "Weekly Stability Status"

#### Visual 2: Schema Changes
- **Type**: Line chart
- **X-axis**: `week_start_date`
- **Value**: `schema_changes`
- **Title**: "Schema Changes Over Time"

#### Visual 3: Quality Score Trend
- **Type**: Area chart
- **X-axis**: `week_start_date`
- **Value**: `avg_quality_score`
- **Title**: "Average Quality Score (Weekly)"
- **Fill**: Green gradient

---

## Dashboard 5: Real-Time Scorecard

### Create Dataset

1. **New dataset** → **Athena**
2. Table: `qs_realtime_scorecard`
3. **Important**: Set refresh to **SPICE** for faster loading
4. Name: `Real-Time Scorecard`
5. **Visualize**

### Create Visuals

#### Visual 1: City Status Cards
- **Type**: KPI (one per city)
- **Value**: `overall_quality_score`
- **Title**: `city` name
- **Conditional formatting**:
  - Green: >= 95
  - Yellow: 80-94
  - Red: < 80
- **Create 3 separate KPIs** (London, New York, Tokyo)

#### Visual 2: Latest Updates
- **Type**: Table
- **Columns**:
  - `city`
  - `last_update`
  - `overall_quality_score`
  - `status`
- **Sort**: By `last_update` DESC
- **Title**: "Latest Quality Checks"

#### Visual 3: Quality Score Gauge
- **Type**: Gauge
- **Value**: `AVG(overall_quality_score)`
- **Title**: "Overall Platform Quality"
- **Ranges**:
  - 0-60: Red
  - 60-80: Orange
  - 80-95: Yellow
  - 95-100: Green

---

## Advanced Features

### Auto-Refresh

1. Edit dashboard
2. Click **Refresh** (top right)
3. Set schedule:
   - **Quality Dashboard**: Every hour
   - **Weather Dashboard**: Every 6 hours
   - **Scorecard**: Every 15 minutes

### Email Alerts

1. Click **Share** → **Subscribe**
2. Choose recipients
3. Set threshold alerts:
   - Alert if `overall_quality_score < 80`
   - Alert if `schema_changes > 0`

### Mobile Access

1. Download QuickSight mobile app
2. Log in with AWS credentials
3. Access all dashboards on phone/tablet

---

## Cost Optimization

### SPICE vs Direct Query

**SPICE (In-Memory)**:
- ✅ Faster (sub-second queries)
- ✅ No Athena query costs
- ❌ Costs $0.25/GB/month
- **Best for**: Frequently accessed dashboards

**Direct Query**:
- ✅ Always up-to-date
- ✅ No SPICE storage cost
- ❌ Slower
- ❌ Athena query costs
- **Best for**: Infrequently accessed reports

**Recommendation**: 
- Real-Time Scorecard → SPICE (refreshed hourly)
- Quality/Weather Dashboards → Direct Query
- Historical Reports → SPICE (refreshed daily)

### Cost Estimate

| Component | Cost |
|-----------|------|
| QuickSight Standard (1 user) | $9/month |
| SPICE storage (1 GB) | $0.25/month |
| Athena queries (~100/month) | $0.01/month |
| **Total** | **~$9.26/month** |

**Note**: First 30 days free, first 1 GB SPICE free

---

## Troubleshooting

### "Table not found" error
**Solution**: Verify Athena views exist:
```sql
SHOW TABLES IN weather_data_lake LIKE 'qs_%';
```

### Dashboard loads slowly
**Solution**: 
1. Switch to SPICE for faster performance
2. Reduce date range (30 days → 7 days)
3. Add filters to limit data

### No data showing
**Solution**:
1. Check Glue crawler has run
2. Query table directly in Athena to verify data
3. Refresh QuickSight dataset

---

## Sample Dashboards

### Quality Monitoring Layout
```
┌─────────────────────────────────────────────────────┐
│  Data Quality Monitoring Dashboard                  │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌─────────────────┐  ┌───────────────────────────┐│
│  │ Quality Score   │  │ Quality Dimensions        ││
│  │ Trend Line      │  │ (Line Chart)              ││
│  │ (Last 30 Days)  │  │ - Completeness            ││
│  │                 │  │ - Consistency             ││
│  └─────────────────┘  │ - Timeliness              ││
│                       └───────────────────────────┘│
│  ┌─────────────────┐  ┌───────────────────────────┐│
│  │ Schema Changes  │  │ Missing Fields Trend      ││
│  │ (KPI: 0)        │  │ (Bar Chart)               ││
│  │ 🟢 No Changes   │  │                           ││
│  └─────────────────┘  └───────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

---

## Next Steps

1. **Create all 5 dashboards** following guides above
2. **Set up email subscriptions** for quality alerts
3. **Share dashboards** with team members
4. **Configure auto-refresh** based on data freshness needs
5. **Optimize costs** by choosing SPICE vs Direct Query wisely

**Time to complete**: 1-2 hours for all dashboards

