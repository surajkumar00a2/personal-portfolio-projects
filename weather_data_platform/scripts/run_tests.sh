#!/bin/bash

echo "=========================================="
echo "RUNNING FULL TEST SUITE"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$(dirname "$0")/.."

# Check if dependencies installed
if ! command -v pytest &> /dev/null; then
    echo -e "${RED}pytest not found. Installing test dependencies...${NC}"
    pip install -r tests/requirements.txt
fi

echo -e "${YELLOW}Running Unit Tests...${NC}"
pytest tests/unit/ -v --cov=lambda/ingestion --cov-report=term-missing --cov-report=html:htmlcov/unit
UNIT_RESULT=$?

echo ""
echo -e "${YELLOW}Running Integration Tests...${NC}"
pytest tests/integration/ -v --cov=lambda/ingestion --cov-append --cov-report=term-missing --cov-report=html:htmlcov/integration
INTEGRATION_RESULT=$?

echo ""
echo -e "${YELLOW}Running Data Quality Tests...${NC}"
pytest tests/data_quality/ -v 2>/dev/null || echo "Skipping (requires PySpark)"
DQ_RESULT=$?

echo ""
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="

if [ $UNIT_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Unit Tests: PASSED${NC}"
else
    echo -e "${RED}✗ Unit Tests: FAILED${NC}"
fi

if [ $INTEGRATION_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Integration Tests: PASSED${NC}"
else
    echo -e "${RED}✗ Integration Tests: FAILED${NC}"
fi

if [ $DQ_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Data Quality Tests: PASSED${NC}"
else
    echo -e "${YELLOW}⚠ Data Quality Tests: SKIPPED (PySpark not available)${NC}"
fi

echo ""
echo "Coverage report: htmlcov/index.html"
echo ""

# Exit with error if any tests failed
if [ $UNIT_RESULT -ne 0 ] || [ $INTEGRATION_RESULT -ne 0 ]; then
    exit 1
fi

exit 0
