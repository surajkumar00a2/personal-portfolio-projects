#!/bin/bash

echo "=========================================="
echo "CREATING CLOUDWATCH DASHBOARD"
echo "=========================================="
echo ""

AWS_REGION=$(aws configure get region)

# Get the actual Lambda function name
LAMBDA_FUNCTION=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `weather-ingestion`)].FunctionName' --output text)

if [ -z "$LAMBDA_FUNCTION" ]; then
    echo "❌ Lambda function not found"
    exit 1
fi

echo "Found Lambda: $LAMBDA_FUNCTION"
echo ""

# Create dashboard JSON
cat > /tmp/dashboard.json <<DASHBOARD
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "DataPlatform/Quality", "OverallQualityScore", { "stat": "Average", "label": "Overall Quality Score" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${AWS_REGION}",
        "title": "Overall Quality Score (Last 7 Days)",
        "period": 21600,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100
          }
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Minimum Acceptable",
              "value": 80,
              "fill": "below",
              "color": "#d62728"
            },
            {
              "label": "Target",
              "value": 95,
              "color": "#2ca02c"
            }
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "DataPlatform/Quality", "CompletenessScore", { "stat": "Average", "color": "#2ca02c", "label": "Completeness" } ],
          [ ".", "ConsistencyScore", { "stat": "Average", "color": "#ff7f0e", "label": "Consistency" } ],
          [ ".", "TimelinesScore", { "stat": "Average", "color": "#1f77b4", "label": "Timeliness" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${AWS_REGION}",
        "title": "Quality Dimensions",
        "period": 21600,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [ "DataPlatform/Quality", "RecordsIngested", { "stat": "Sum", "label": "Total Records" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${AWS_REGION}",
        "title": "Records Ingested (Last 24 Hours)",
        "period": 21600,
        "yAxis": {
          "left": {
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 6,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [ "DataPlatform/Quality", "SchemaChanges", { "stat": "Sum", "color": "#d62728", "label": "Schema Changes" } ]
        ],
        "view": "singleValue",
        "region": "${AWS_REGION}",
        "title": "Schema Changes Detected",
        "period": 86400
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 6,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [ "DataPlatform/Quality", "APILatency", { "stat": "Average", "label": "Avg Latency" } ],
          [ "...", { "stat": "Maximum", "label": "Max Latency", "color": "#d62728" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${AWS_REGION}",
        "title": "API Latency (ms)",
        "period": 21600,
        "yAxis": {
          "left": {
            "min": 0
          }
        }
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 12,
      "width": 12,
      "height": 6,
      "properties": {
        "query": "SOURCE '/aws/lambda/${LAMBDA_FUNCTION}'\n| fields @timestamp, @message\n| filter @message like /ERROR/ or @message like /FAILED/ or @message like /Exception/\n| sort @timestamp desc\n| limit 20",
        "region": "${AWS_REGION}",
        "stacked": false,
        "title": "Recent Errors",
        "view": "table"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 12,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/Lambda", "Invocations", { "stat": "Sum", "label": "Invocations" }, { "region": "${AWS_REGION}" } ],
          [ ".", "Errors", { "stat": "Sum", "label": "Errors", "color": "#d62728" } ],
          [ ".", "Duration", { "stat": "Average", "yAxis": "right", "label": "Avg Duration (ms)" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${AWS_REGION}",
        "title": "Lambda Health (${LAMBDA_FUNCTION})",
        "period": 21600,
        "yAxis": {
          "left": {
            "min": 0
          },
          "right": {
            "min": 0
          }
        },
        "stat": "Average"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 18,
      "width": 24,
      "height": 1,
      "properties": {
        "markdown": "# 📊 Data Quality Monitoring Dashboard\n\n**Last updated:** Auto-refresh every 1 minute | **Data refresh:** Every 6 hours (00:00, 06:00, 12:00, 18:00 UTC)\n\n---\n\n### 🎯 Quality Score Interpretation:\n- **95-100:** Excellent - No issues detected\n- **80-94:** Good - Minor issues, acceptable\n- **60-79:** Warning - Investigate quality problems\n- **< 60:** Critical - Immediate action required\n\n### 📈 Metrics Explained:\n- **Completeness:** % of mandatory fields populated\n- **Consistency:** Schema matches expected structure\n- **Timeliness:** Data arrives on schedule\n- **API Latency:** Response time from OpenWeatherMap API"
      }
    }
  ]
}
DASHBOARD

# Create/update dashboard
echo "Creating dashboard..."
aws cloudwatch put-dashboard \
  --dashboard-name data-quality-monitoring \
  --dashboard-body file:///tmp/dashboard.json

rm /tmp/dashboard.json

echo "✓ Dashboard created/updated"
echo ""

echo "=========================================="
echo "DASHBOARD READY"
echo "=========================================="
echo ""
echo "View dashboard:"
echo "  https://console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=data-quality-monitoring"
echo ""
echo "Dashboard will show data after Lambda runs."
echo ""
echo "To populate data immediately:"
echo "  aws lambda invoke --function-name ${LAMBDA_FUNCTION} response.json"
echo ""
echo "Current metrics in CloudWatch:"
aws cloudwatch list-metrics --namespace "DataPlatform/Quality" --query 'Metrics[].MetricName' --output table 2>/dev/null || echo "  No metrics found yet"
echo ""
