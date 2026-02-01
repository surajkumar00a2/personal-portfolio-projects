"""
Expected schema for OpenWeatherMap API response
Defines mandatory field, types and validation rules
"""

# Mandatory fields that must be present in every API response
MANDATORY_FIELDS = [
    'coord.lat',
    'coord.lon',
    'weather',
    'main.temp',
    'main.feels_like',
    'main.humidity',
    'main.pressure',
    'wind.speed',
    'clouds.all',
    'dt',
    'sys.country',
    'name',
    'cod'
]

# Expected data types for fields
# Format: 'field_path': (expected_type1, expected_type2,...)
EXPECTED_TYPES = {
    'coord.lat': (int, float),
    'coord.lon': (int, float),
    'main.temp': (int, float),
    'main.feels_like': (int, float),
    'main.temp_min': (int, float),
    'main.temp_max': (int, float),
    'main.humidity': int,
    'main.pressure': int,
    'wind.speed': (int, float),
    'wind.deg': int,
    'clouds.all': int,
    'dt': int,
    'name': str,
    'cod': int,
    'timezone': int,
    'id': int
}

# Valid value ranges for numeric fields
# Format: 'field_path': (min_value, max_value)
VALUE_RANGES = {
    'coord.lat': (-90, 90),
    'coord.lon': (-180, 180),
    'main.humidity': (0, 100),
    'clouds.all': (0, 100),
    'main.pressure': (800, 1100),  # Reasonable atmospheric pressure range
}

# Quality score weights
QUALITY_WEIGHTS = {
    'completeness': 0.4,    # 40% - Are all mandatory fields present?
    'consistency': 0.3,     # 30% - Do types and values match expectations?
    'timeliness': 0.2,      # 20% - Was data ingested on time?
    'availability': 0.1     # 10% - Was API available?
}