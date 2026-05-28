from __future__ import annotations

from dataclasses import dataclass
from types import NoneType, UnionType
from typing import Annotated, Any, Union, get_args, get_origin, get_type_hints

from sqlalchemy.orm import InstrumentedAttribute, Mapped

from src.metadata import (
    FloatMax,
    FloatMin,
    NoNaN,
    Nullable,
    Required,
    Unique,
    UniqueComposite,
)
from src.validation_types import BaseValidator
from src.validators.duplicate import DuplicateValidator
from src.validators.float_max import MaxFloatValidator
from src.validators.float_min import MinFloatValidator
from src.validators.nan import NaNValidator
from src.validators.null import NullValidator

@dataclass(frozen=True, slots=True)
class FieldRuleSet:
    field_name: str
    validators: tuple[BaseValidator, ...]


def _is_optional(tp: Any) -> bool:
    origin = get_origin(tp)
    if origin is None:
        return False
    if origin in (UnionType, Union):
        return NoneType in get_args(tp)
    return NoneType in get_args(tp)


def _unwrap_mapped(tp: Any) -> Any:
    origin = get_origin(tp)
    args = get_args(tp)
    if origin is Mapped and args:
        return args[0]
    if args and getattr(origin, "__name__", "") == "Mapped":
        return args[0]
    return tp


def _split_annotated(tp: Any) -> tuple[Any, tuple[Any, ...]]:
    metadata: list[Any] = []
    current = tp
    while get_origin(current) is Annotated:
        args = get_args(current)
        current = args[0]
        metadata.extend(args[1:])
    return current, tuple(metadata)


def _normalize_field_type(field_type: Any) -> tuple[Any, tuple[Any, ...]]:
    inner = _unwrap_mapped(field_type)
    return _split_annotated(inner)


def _resolve_field_type(model_cls: type[Any], field_name: str, field_type: Any) -> Any:
    if isinstance(field_type, str):
        resolved = get_type_hints(model_cls, include_extras=True).get(field_name)
        if resolved is None:
            return field_type
        return resolved
    return field_type


def _should_require_non_null(base_type: Any, metadata: tuple[Any, ...]) -> bool:
    if any(isinstance(meta, Nullable) for meta in metadata):
        return False
    if any(isinstance(meta, Required) for meta in metadata):
        return True
    return not _is_optional(base_type)


def _field_validators_from_metadata(
    field_name: str,
    base_type: Any,
    metadata: tuple[Any, ...],
) -> list[BaseValidator]:
    validators: list[BaseValidator] = []

    if _should_require_non_null(base_type, metadata):
        validators.append(NullValidator(field_name=field_name))

    for meta in metadata:
        if isinstance(meta, NoNaN):
            validators.append(NaNValidator(field_name=field_name))
        elif isinstance(meta, FloatMin):
            validators.append(
                MinFloatValidator(
                    field_name=field_name,
                    min_val=meta.value,
                    epsilon=meta.epsilon,
                )
            )
        elif isinstance(meta, FloatMax):
            validators.append(
                MaxFloatValidator(
                    field_name=field_name,
                    max_val=meta.value,
                    epsilon=meta.epsilon,
                )
            )
    return validators


def parse_field_validators(
    model_cls: type[Any],
    field_name: str,
    field_type: Any,
) -> list[BaseValidator]:
    attr = getattr(model_cls, field_name, None)
    if not isinstance(attr, InstrumentedAttribute):
        return []

    field_type = _resolve_field_type(model_cls, field_name, field_type)
    base_type, metadata = _normalize_field_type(field_type)
    return _field_validators_from_metadata(field_name, base_type, metadata)


def parse_field_rules(model_cls: type[Any]) -> list[FieldRuleSet]:
    rules: list[FieldRuleSet] = []
    for field_name, field_type in getattr(model_cls, "__annotations__", {}).items():
        validators = parse_field_validators(model_cls, field_name, field_type)
        if validators:
            rules.append(FieldRuleSet(field_name=field_name, validators=tuple(validators)))
    return rules


def parse_duplicate_validators(model_cls: type[Any]) -> list[DuplicateValidator]:
    targets: set[tuple[str, ...]] = set()

    for field_name, field_type in getattr(model_cls, "__annotations__", {}).items():
        field_type = _resolve_field_type(model_cls, field_name, field_type)
        _, metadata = _normalize_field_type(field_type)
        for meta in metadata:
            if isinstance(meta, Unique):
                targets.add((field_name,))
            elif isinstance(meta, UniqueComposite):
                targets.add(meta.columns)

    return [
        DuplicateValidator(field_name=",".join(columns), columns=columns)
        for columns in sorted(targets)
    ]
