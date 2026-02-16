#!/bin/bash

echo "=========================================="
echo "AUTOMATION STATUS CHECK"
echo "=========================================="
echo ""

AWS_REGION=$(aws configure get region)
LAMBDA_FUNCTION=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `weather-ingestion`)].FunctionName' --output text)

# Check EventBridge rules
echo "1. EventBridge Rules:"
aws events list-rules --query 'Rules[?contains(Name, `weather`)].{Name:Name,State:State}' --output table

echo ""
echo "2. Glue Crawler:"
aws glue get-crawlers --query 'Crawlers[?contains(Name, `weather`)].{Name:Name,Schedule:Schedule,State:State}' --output table

echo ""
echo "3. Recent Lambda Invocations (last 24 hours):"
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION \
  --start-time $(date -u -v-24H +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || echo "2026-02-09T00:00:00") \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum \
  --query 'Datapoints[?Sum > `0`]' \
  --output table

echo ""
echo "4. Recent Glue Job Runs:"
aws glue get-job-runs --job-name bronze-to-silver-transform --max-results 5 --query 'JobRuns[].{Started:StartedOn,State:JobRunState}' --output table 2>/dev/null || echo "No recent runs"

echo ""
echo "=========================================="
echo "STATUS SUMMARY"
echo "=========================================="
if aws events list-rules --query 'Rules[?contains(Name, `weather`) && State==`DISABLED`]' --output text | grep -q .; then
    echo "✓ Automation is PAUSED"
else
    echo "⚠️  Some automation may still be active"
fi
echo ""
