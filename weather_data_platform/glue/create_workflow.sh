#!/bin/bash

echo "=========================================="
echo "CREATING GLUE WORKFLOW"
echo "=========================================="
echo ""

AWS_REGION=$(aws configure get region)

# Create workflow
echo "Creating workflow: weather-data-pipeline..."
aws glue create-workflow \
  --name weather-data-pipeline \
  --description "Orchestrates Bronze→Silver→Gold transformations" \
  --max-concurrent-runs 1

echo "✓ Workflow created"
echo ""

# Add Bronze→Silver trigger
echo "Adding trigger: start-bronze-to-silver..."
aws glue create-trigger \
  --name start-bronze-to-silver \
  --type SCHEDULED \
  --schedule "cron(30 0,6,12,18 * * ? *)" \
  --actions JobName=bronze-to-silver-transform \
  --workflow-name weather-data-pipeline \
  --start-on-creation

echo "✓ Bronze→Silver trigger created (runs 30min after ingestion)"
echo ""

# Add Silver→Gold trigger (runs after Bronze→Silver succeeds)
echo "Adding trigger: start-silver-to-gold..."
aws glue create-trigger \
  --name start-silver-to-gold \
  --type CONDITIONAL \
  --predicate '{
    "Logical": "AND",
    "Conditions": [
      {
        "LogicalOperator": "EQUALS",
        "JobName": "bronze-to-silver-transform",
        "State": "SUCCEEDED"
      }
    ]
  }' \
  --actions JobName=silver-to-gold-aggregations \
  --workflow-name weather-data-pipeline \
  --start-on-creation

echo "✓ Silver→Gold trigger created (runs after Bronze→Silver succeeds)"
echo ""

echo "=========================================="
echo "WORKFLOW CREATED"
echo "=========================================="
echo ""
echo "Workflow: weather-data-pipeline"
echo ""
echo "Pipeline:"
echo "  1. Lambda ingests data → Bronze (every 6 hours: 00:00, 06:00, 12:00, 18:00)"
echo "  2. Glue Bronze→Silver (30min later: 00:30, 06:30, 12:30, 18:30)"
echo "  3. Glue Silver→Gold (immediately after Bronze→Silver succeeds)"
echo ""
echo "View workflow:"
echo "  https://console.aws.amazon.com/glue/home?region=$AWS_REGION#/v2/etl-configuration/workflows/view/weather-data-pipeline"
echo ""