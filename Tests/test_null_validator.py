from __future__ import annotations

from src.parser import parse_field_validators
from src.validators.null import NullValidator

from Tests.models import MigrationUser


def test_parse_field_validators_adds_null_validator_for_non_optional_field() -> None:
    validators = parse_field_validators(MigrationUser, "email", MigrationUser.__annotations__["email"])
    assert len(validators) == 1
    assert isinstance(validators[0], NullValidator)


def test_parse_field_validators_skips_optional_field() -> None:
    validators = parse_field_validators(MigrationUser, "nickname", MigrationUser.__annotations__["nickname"])
    assert validators == []
