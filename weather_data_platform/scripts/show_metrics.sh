#!/bin/bash

echo "=========================================="
echo "CLOUDWATCH METRICS ANALYSIS"
echo "=========================================="
echo ""

# List ALL metrics in the DataPlatform/Quality namespace
echo "1. All Metrics in DataPlatform/Quality namespace:"
aws cloudwatch list-metrics \
  --namespace "DataPlatform/Quality" \
  --output json > /tmp/metrics.json

cat /tmp/metrics.json | jq -r '.Metrics[] | "\(.MetricName) - Dimensions: \(.Dimensions | map(.Name + "=" + .Value) | join(", "))"'

echo ""
echo "2. Raw JSON output (for debugging):"
cat /tmp/metrics.json | jq '.'

echo ""
echo "3. Metric data points (last 6 hours):"
METRICS=$(cat /tmp/metrics.json | jq -r '.Metrics[].MetricName' | sort -u)

for metric in $METRICS; do
    echo ""
    echo "--- $metric ---"
    aws cloudwatch get-metric-statistics \
      --namespace "DataPlatform/Quality" \
      --metric-name "$metric" \
      --start-time $(date -u -d '6 hours ago' +%Y-%m-%dT%H:%M:%S) \
      --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
      --period 21600 \
      --statistics Average,Sum,Maximum \
      --output table
done

echo ""
echo "=========================================="
echo "Saved full output to: /tmp/metrics.json"
echo "=========================================="
