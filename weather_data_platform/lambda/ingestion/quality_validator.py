"""
Data Quality Validation Module
Validates API responses and calculates quality metrics
"""

import hashlib
import json
from typing import Dict, List, Tuple, Any
from datetime import datetime, timezone
from schema_definition import (
    MANDATORY_FIELDS,
    EXPECTED_TYPES,
    VALUE_RANGES,
    QUALITY_WEIGHTS
)

def flatten_dict(d:dict, parent_key:str='', sep:str='.')->dict:
    """
    Flatten nested dictionary for easier field access
    """
    items = []
    for k,v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        elif isinstance(v,list) and len(v)>0 and isinstance(v[0], dict):
            items.append((new_key, v))
        else:
            items.append((new_key, v))
    return dict(items)

def calculate_schema_fingerprint(data: dict)->str:
    """
    Generate schema fingerprint (MD5 hash of field + types)
    Used for schema drift detection
    Return: 8-character hash (e.g., 'a3f5c8d9')
    """
    flat_data = flatten_dict(data)

    # Create schema signature: {field: type}
    schema = {}
    for key, value in flat_data.items():
        if isinstance(value, dict):
            schema[key] = f"array<{type(value[0]).__name__ if value else 'Unknown'}>"
        else:
            schema[key] = type(value).__name__
    
    schema_str = json.dumps(schema, sort_keys=True)
    return hashlib.md5(schema_str.encode()).hexdigest()[:8]


def validate_field_presence(data: dict)-> Tuple[List[str], int, int]:
    """ 
    Check if mandatory fields are present and not null
    Returns:
        (Missing_fields, total_fields, populated_fields)
    """
    flat_data = flatten_dict(data)
    missing = []

    for field in MANDATORY_FIELDS:
        if field not in flat_data or flat_data[field] is None:
            missing.append(field)
    
    total = len(MANDATORY_FIELDS)
    populated = total - len(missing)
    return missing, total, populated


def validate_field_types(data: dict) -> List[Dict[str, Any]]:
    """
    Validate field types match expected type
    Returns: List of type errors
    """
    flat_data = flatten_dict(data)
    type_errors = []

    for field, expected_type in EXPECTED_TYPES.items():
        if field in flat_data and flat_data[field] is not None:
            value = flat_data[field]
            if not isinstance(value, expected_type):
                type_errors.append({
                    "field": field,
                    "expected_type": expected_type.__name__,
                    "actual_type": type(value).__name__,
                    "value": value
                })

    return type_errors

def validate_value_ranges(data: dict)-> List[Dict[str, Any]]:
    """
    Validate values within expected ranges
    returns: List of range violations
    """
    flat_data = flatten_dict(data)
    range_errors = []
    for field, (min_val, max_val) in VALUE_RANGES.items():
        if field in flat_data and flat_data[field] is not None:
            value = flat_data[field]
            if isinstance(value, (int, float)):
                if value < min_val or value > max_val:
                    range_errors.append({
                        'field':field,
                        'value':value,
                        'expected_range':f"{min_val} to {max_val}"
                    })
    return range_errors 

def calculate_completeness_score(populated_fields: int, total_fields:int)->float:
    """
    Calculate completeness score (0-100)
    Based on the percentage of mandatory fields that are populated
    """
    if total_fields == 0:
        return 100.0
    return round((populated_fields/total_fields)*100, 2)

def calculate_consistency_score(type_erros:List, range_erros:List)->float:
    """
    Calculate consistency score based on validation errors
    Penalizes:
    - Type mismatches
    - Value out of range
    """
    total_checks = len(EXPECTED_TYPES)+len(VALUE_RANGES)
    errors = len(type_erros) + len(range_erros)

    if errors == 0:
        return 100.0
    
    return max(0, round((1-errors/total_checks)*100,2))

def calculate_timeliness_score(scheduled_time:datetime, execution_time:datetime)->float:
    """
    Calculate timelinss score based on delay
    Scoring:
    -  100 points if on time (wihtin 1 minute)
    - -10 points per minute late
    - Minimum score = 0
    """
    delay_seconds = (execution_time - scheduled_time).total_seconds()
    delay_minutes = delay_seconds/60
    # Allow 1 minute grace period
    if delay_minutes <= 1:
        return 100.0
    score = max(0, 100-((delay_minutes-1)*10))
    return round(score,2)

def calculate_overall_quality_score(
        completeness_score:float,
        consistency_score:float,
        timeliness_score:float,
        availability_score:float
        )->float:
    """
    Calaculate overall quality score as weighted average
    Weights defined in schema_definition.QUALITY_WEIGHTS
    """
    overall = (
        completeness_score*QUALITY_WEIGHTS['completeness'] + 
        consistency_score*QUALITY_WEIGHTS['consistency'] + 
        timeliness_score*QUALITY_WEIGHTS['timeliness'] + 
        availability_score*QUALITY_WEIGHTS['availability']
    )
    
    return round(overall, 2)

def validate_data(data: dict, scheduled_time:datetime = None)-> Dict[str, Any]:
    """
    Run complete validation suite on API response
    ARg:
        data: API response dictionary
        scheduled_time: Expected ingestion time (for timeliness calculation)
    Returns:
        Dictionary conatining all quality metrics
    """
    execution_time = datetime.now(timezone.utc)

    # Field presence validation
    missing_fields, total_fields, populated_fields = validate_field_presence(data)

    # Type validation
    type_errors = validate_field_types(data)

    # Range validation
    range_errors = validate_value_ranges(data)

    # Schema fingerprint
    schema_version = calculate_schema_fingerprint(data)

    # Calculate individual scores
    completeness_score = calculate_completeness_score(populated_fields, total_fields)
    consistency_score = calculate_consistency_score(type_errors, range_errors)

    # Timeliness score (default to 100 if no scheduled time provided)
    if scheduled_time:
        timeliness_score = calculate_timeliness_score(scheduled_time, execution_time)
    else:
        timeliness_score = 100.0
    
    # Availability score (if we got here, API was available)
    availability_score = 100.0

    # Overall quality score
    overall_score = calculate_overall_quality_score(
        completeness_score,
        consistency_score,
        timeliness_score,
        availability_score
    )

    # Determine if there are issues
    has_issues = (
        len(missing_fields) > 0 or
        len(type_errors) > 0 or
        len(range_errors) > 0 or
        overall_score < 80
    )

    return {
        'validation_timestamp': execution_time.isoformat(),
        'schema_version': schema_version,
        'field_validation': {
            'total_fields': total_fields,
            'populated_fields': populated_fields,
            'missing_fields': missing_fields,
            'missing_count': len(missing_fields),
            'missing_percent': round((len(missing_fields) / total_fields) * 100, 2) if total_fields > 0 else 0
        },
        'type_validation': {
            'errors': type_errors,
            'error_count': len(type_errors)
        },
        'range_validation': {
            'errors': range_errors,
            'error_count': len(range_errors)
        },
        'quality_scores': {
            'completeness_score': completeness_score,
            'consistency_score': consistency_score,
            'timeliness_score': timeliness_score,
            'availability_score': availability_score,
            'overall_quality_score': overall_score
        },
        'has_issues': has_issues
    }