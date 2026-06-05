from __future__ import annotations

from typing import Any

from sqlalchemy import and_, func, or_, select
from sqlalchemy.orm import Session

from src.parser import parse_duplicate_validators, parse_field_rules
from src.validation_types import ModelT, ValidationError
from src.validators.duplicate import DuplicateValidator


class MigrationValidator:
    def __init__(self, session: Session) -> None:
        self.session = session

    def validate(self, model_cls: type[ModelT]) -> list[ValidationError]:
        errors: list[ValidationError] = []
        errors.extend(self._validate_field_rules(model_cls))
        errors.extend(self._validate_duplicate_rules(model_cls))
        return errors

    def validate_all(self, *model_classes: type[ModelT]) -> list[ValidationError]:
        all_errors: list[ValidationError] = []
        for model_cls in model_classes:
            all_errors.extend(self.validate(model_cls))
        return all_errors

    def validate_to_dataframe(self, model_cls: type[ModelT]) -> Any:
        from src.pandas_ import errors_to_dataframe

        return errors_to_dataframe(self.validate(model_cls))

    def _validate_field_rules(self, model_cls: type[ModelT]) -> list[ValidationError]:
        errors: list[ValidationError] = []
        table = model_cls.__table__
        pk_column = model_cls.__mapper__.primary_key[0]
        tablename = table.name

        for field_rule in parse_field_rules(model_cls):
            if field_rule.field_name not in table.c:
                continue

            column = table.c[field_rule.field_name]
            validators = list(field_rule.validators)
            if not validators:
                continue

            conditions = [validator.build_sql_condition(column) for validator in validators]
            query = select(pk_column, column).where(or_(*conditions)).execution_options(yield_per=5000)

            for pk_val, corrupt_val in self.session.execute(query):
                for validator in validators:
                    if not validator.matches_python(corrupt_val, pk=pk_val):
                        continue
                    errors.append(
                        ValidationError(
                            table=tablename,
                            id=self._normalize_id(pk_val),
                            field=field_rule.field_name,
                            error=validator.format_error(corrupt_val),
                            validator=validator.kind,
                        )
                    )
                    break
        return errors

    def _validate_duplicate_rules(self, model_cls: type[ModelT]) -> list[ValidationError]:
        errors: list[ValidationError] = []
        table = model_cls.__table__
        pk_column = model_cls.__mapper__.primary_key[0]
        tablename = table.name

        for validator in parse_duplicate_validators(model_cls):
            errors.extend(self._run_duplicate_validator(table, pk_column, tablename, validator))
        return errors

    def _run_duplicate_validator(
        self,
        table: Any,
        pk_column: Any,
        tablename: str,
        validator: DuplicateValidator,
    ) -> list[ValidationError]:
        errors: list[ValidationError] = []
        cols = [table.c[name] for name in validator.columns]
        grouped_duplicates = (
            select(*cols)
            .where(and_(*(col.is_not(None) for col in cols)))
            .group_by(*cols)
            .having(func.count() > 1)
            .subquery()
        )

        join_condition = and_(*(table.c[name] == grouped_duplicates.c[name] for name in validator.columns))
        query = (
            select(pk_column, *cols)
            .select_from(table.join(grouped_duplicates, join_condition))
            .execution_options(yield_per=5000)
        )

        for row in self.session.execute(query):
            pk_val = row[0]
            values = tuple(row[1:])
            value_repr: Any = values[0] if len(values) == 1 else values
            errors.append(
                ValidationError(
                    table=tablename,
                    id=self._normalize_id(pk_val),
                    field=",".join(validator.columns),
                    error=validator.format_error(value_repr),
                    validator=validator.kind,
                )
            )
        return errors

    @staticmethod
    def _normalize_id(value: Any) -> int | str:
        if isinstance(value, (int, str)):
            return value
        return str(value)
