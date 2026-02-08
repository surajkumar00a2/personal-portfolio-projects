# Testing Documentation

## Overview

Comprehensive test suite for the Weather Data Platform covering:
- Unit tests (quality validation logic)
- Integration tests (Lambda handler with mocked AWS)
- Data quality tests (PySpark transformations)

**Current Coverage: 91%**

---

## Running Tests

### Quick Start
```bash
# Run all tests
./scripts/run_tests.sh

# Or run specific test suites
pytest tests/unit/ -v                    # Unit tests only
pytest tests/integration/ -v             # Integration tests only
pytest tests/data_quality/ -v            # Data quality tests only
```

### With Coverage
```bash
# Generate coverage report
pytest tests/ -v --cov=lambda/ingestion --cov-report=html

# View report
open htmlcov/index.html
```

---

## Test Structure
```
tests/
├── unit/                           # Unit tests
│   └── test_quality_validator.py  # Quality validation logic (98% coverage)
│
├── integration/                    # Integration tests
│   ├── test_lambda_ingestion.py   # Basic Lambda tests
│   └── test_lambda_handler_coverage.py  # Extended Lambda tests (87% coverage)
│
├── data_quality/                   # Data quality tests
│   └── test_transformations.py    # PySpark transformation tests
│
├── fixtures/                       # Test fixtures (empty)
├── requirements.txt                # Test dependencies
└── pytest.ini                      # Pytest configuration
```

---

## Test Coverage by Module

| Module | Coverage | Missing Lines |
|--------|----------|---------------|
| quality_validator.py | 98% | 44, 116 |
| schema_definition.py | 100% | - |
| lambda_ingestion_v2.py | 87% | Error handling paths |
| **Overall** | **91%** | - |

---

## Test Categories

### Unit Tests (tests/unit/)

**Purpose**: Test individual functions in isolation

**Coverage**:
- ✅ Dictionary flattening
- ✅ Schema fingerprinting
- ✅ Field presence validation
- ✅ Type validation
- ✅ Range validation
- ✅ Quality score calculations
- ✅ Complete validation flow

**Example**:
```python
def test_completeness_score_perfect():
    score = calculate_completeness_score(populated_fields=10, total_fields=10)
    assert score == 100.0
```

### Integration Tests (tests/integration/)

**Purpose**: Test Lambda with mocked AWS services

**Uses**: moto (AWS mocking library)

**Coverage**:
- ✅ Weather API fetching
- ✅ S3 write operations (JSON + Parquet)
- ✅ CloudWatch metrics
- ✅ Complete Lambda handler flow
- ✅ Error handling
- ✅ Partial failures

**Example**:
```python
@mock_s3
def test_successful_write(mock_weather_data, mock_quality_metrics):
    result = write_to_s3("London", mock_weather_data, mock_quality_metrics)
    assert result is True
```

### Data Quality Tests (tests/data_quality/)

**Purpose**: Validate PySpark transformations

**Requires**: PySpark installed locally

**Coverage**:
- ✅ JSON → Parquet conversion
- ✅ Kelvin → Celsius conversion
- ✅ Deduplication logic
- ✅ Partition column addition
- ✅ Daily aggregations
- ✅ Quality scorecard aggregation
- ✅ Data constraints

**Example**:
```python
def test_temperature_conversion(spark):
    df = spark.createDataFrame([{"temp_kelvin": 273.15}])
    df = df.withColumn("temp_celsius", df.temp_kelvin - 273.15)
    assert df.collect()[0]['temp_celsius'] == 0.0
```

---

## Writing New Tests

### Unit Test Template
```python
def test_function_name():
    """Test description"""
    # Arrange
    input_data = {...}
    
    # Act
    result = function_under_test(input_data)
    
    # Assert
    assert result == expected_value
```

### Integration Test Template
```python
@mock_s3
def test_integration_scenario():
    """Test description"""
    # Setup mocks
    s3 = boto3.client('s3', region_name='us-east-1')
    s3.create_bucket(Bucket='test-bucket')
    
    # Act
    result = function_under_test()
    
    # Assert
    assert result is True
```

---

## CI/CD Integration

Tests run automatically on every push via GitHub Actions:
```yaml
# .github/workflows/tests.yml
- name: Run tests
  run: pytest tests/ --cov=lambda/ingestion --cov-fail-under=80
```

**Pipeline fails if coverage drops below 80%**

---

## Common Issues

### Issue: "Module not found"
**Solution**:
```bash
pip install -r tests/requirements.txt
pip install -r lambda/ingestion/requirements.txt
```

### Issue: PySpark tests fail
**Solution**: PySpark tests require local Spark installation
```bash
# Skip PySpark tests
pytest tests/unit tests/integration -v
```

### Issue: Moto version conflicts
**Solution**:
```bash
pip install --upgrade moto[all]==4.2.9
```

---

## Test Metrics

### Current Stats
- **Total Tests**: 45
- **Unit Tests**: 18
- **Integration Tests**: 22
- **Data Quality Tests**: 5
- **Coverage**: 91%
- **Execution Time**: ~8 seconds

### Coverage Goals
- Unit tests: 95%+ ✅
- Integration tests: 85%+ ✅
- Overall: 90%+ ✅

---

## Future Enhancements

- [ ] Add property-based testing (Hypothesis)
- [ ] Add mutation testing (mutmut)
- [ ] Add load/performance tests
- [ ] Add contract tests for API
- [ ] Add end-to-end tests with real AWS

