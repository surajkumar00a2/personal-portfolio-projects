#!/bin/bash

echo "=========================================="
echo "SETTING UP S3 DATA LAKE"
echo "=========================================="
echo ""

# Generate unique bucket name
BUCKET_NAME="weather-data-platform-$(openssl rand -hex 4)"
echo "Bucket name: $BUCKET_NAME"

# Save bucket name
echo $BUCKET_NAME > config/bucket-name.txt

# Create bucket
aws s3 mb s3://$BUCKET_NAME

# Create folder structure
echo "Creating folder structure..."
aws s3api put-object --bucket $BUCKET_NAME --key data/bronze/
aws s3api put-object --bucket $BUCKET_NAME --key data/silver/
aws s3api put-object --bucket $BUCKET_NAME --key data/gold/
aws s3api put-object --bucket $BUCKET_NAME --key metrics/quality/
aws s3api put-object --bucket $BUCKET_NAME --key metrics/alerts/
aws s3api put-object --bucket $BUCKET_NAME --key scripts/
aws s3api put-object --bucket $BUCKET_NAME --key temp/

echo ""
echo "✓ S3 bucket created: $BUCKET_NAME"
echo "✓ Folder structure created"
echo ""
echo "Bucket name saved to: config/bucket-name.txt"
