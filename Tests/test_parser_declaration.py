from __future__ import annotations

from src.parser import parse_duplicate_validators, parse_field_rules
from src.validators.float_max import MaxFloatValidator
from src.validators.float_min import MinFloatValidator
from src.validators.null import NullValidator
from Tests.models import MigrationUser


def test_parse_field_rules_reads_annotated_markers() -> None:
    rules = {rule.field_name: rule.validators for rule in parse_field_rules(MigrationUser)}
    age_validators = rules["age"]
    assert any(isinstance(v, NullValidator) for v in age_validators)
    assert any(isinstance(v, MinFloatValidator) for v in age_validators)
    assert any(isinstance(v, MaxFloatValidator) for v in age_validators)


def test_parse_duplicate_validators_reads_column_markers_only() -> None:
    duplicates = parse_duplicate_validators(MigrationUser)
    fields = {validator.field_name for validator in duplicates}
    assert "email" in fields
    assert "country,city" in fields
