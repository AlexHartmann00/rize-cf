"""Goal attainment from persisted repetitions/seconds, including legacy rounds."""
from math import isfinite, sqrt
from typing import Any, Mapping


def _number(value: Any, default: float = 0.0) -> float:
    try:
        result = float(value)
        return result if isfinite(result) else default
    except (TypeError, ValueError):
        return default


def workout_progress_units(workout: Mapping[str, Any]) -> tuple[float, float]:
    schedule = workout.get("schedule")
    if not isinstance(schedule, list):
        return 0.0, 0.0
    base = "baseReps" if workout.get("type") in ("reps", "dynamic") else "baseSeconds"
    default_target = _number(workout.get(base)) * _number(workout.get("intensityFactor"), 1)
    achieved = planned = 0.0
    for step in schedule:
        if not isinstance(step, dict):
            continue
        units = max(0.0, _number(step.get("plannedUnits")))
        target = _number(step.get("targetValue"), default_target)
        actual = step.get("actualValue")
        credit = (_number(actual) / target if actual is not None and target > 0
                  else _number(step.get("completedUnits")))
        achieved += max(0.0, min(units, credit))
        planned += units
    return achieved, planned


def workout_completion_ratio(workout: Mapping[str, Any]) -> float:
    achieved, planned = workout_progress_units(workout)
    return achieved / planned if planned > 0 else 0.0


def scaled_completion_delta(current_score: float, impact_score: float, ratio: float) -> float:
    """Scale the entire normal reward, including its minimum increment."""
    return (0.004 + 0.1 * max(0.0, impact_score - current_score)) * max(0.0, min(1.0, ratio))


def exercise_completion_delta(current_score: float, impact_score: float, ratio: float,
                              schedule_entries: int, exercise_count: int) -> float:
    """Sum of N exercise credits = mean credit * sqrt(N), before score caps."""
    return (scaled_completion_delta(current_score, impact_score, ratio)
            * schedule_entries / 1.2 / sqrt(max(1, exercise_count)))
