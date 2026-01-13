from __future__ import annotations

from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from typing import Any, Tuple

from firebase_admin import initialize_app, firestore
from firebase_functions import firestore_fn, scheduler_fn


initialize_app()

_db = None

def get_db():
    global _db
    if _db is None:
        _db = firestore.client()
    return _db


TZ = ZoneInfo("Europe/Berlin")


# ----------------------------
# Helpers
# ----------------------------

def clamp_0_1(x: float) -> float:
    if x < 0.0:
        return 0.0
    if x > 1.0:
        return 1.0
    return x


def is_schedule_completed(schedule: Any) -> bool:
    """Completed iff for every entry: completedUnits >= plannedUnits."""
    if not isinstance(schedule, list) or len(schedule) == 0:
        return False

    for entry in schedule:
        if not isinstance(entry, dict):
            return False
        completed = entry.get("completedUnits", 0) or 0
        planned = entry.get("plannedUnits", 0) or 0
        try:
            completed_i = int(completed)
        except Exception:
            completed_i = 0
        try:
            planned_i = int(planned)
        except Exception:
            planned_i = 0

        if completed_i < planned_i:
            return False

    return True


def schedule_sums(schedule: Any) -> Tuple[int, int, bool]:
    """
    Returns:
      sum_completed, sum_planned, finished

    finished iff for every entry completedUnits >= plannedUnits.
    """
    if not isinstance(schedule, list) or len(schedule) == 0:
        return 0, 0, False

    sum_completed = 0
    sum_planned = 0
    finished = True

    for entry in schedule:
        if not isinstance(entry, dict):
            finished = False
            continue

        c = entry.get("completedUnits", 0) or 0
        p = entry.get("plannedUnits", 0) or 0

        try:
            c_i = int(c)
        except Exception:
            c_i = 0

        try:
            p_i = int(p)
        except Exception:
            p_i = 0

        sum_completed += c_i
        sum_planned += p_i

        if c_i < p_i:
            finished = False

    return sum_completed, sum_planned, finished


def compute_completion_delta(current_score: float, impact_score: float) -> float:
    """
    Increase rule (your spec):
      Δ = 0.004 + 0.1*(impactScore - currentScore) if impactScore > currentScore, else 0.004
    """
    base = 0.004
    bonus = 0.0
    if impact_score > current_score:
        bonus = 0.1 * (impact_score - current_score)
    return base + bonus


# -------------------------------------------------------------------
# Function 1: Trigger on workoutHistory create/update (reward once)
# -------------------------------------------------------------------

@firestore_fn.on_document_written(document="users/{userId}/workoutHistory/{workoutId}")
def on_workout_written(
    event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]],
):
    """
    Fires on create + update + delete for:
      users/{userId}/workoutHistory/{workoutId}

    If workout transitions from NOT completed -> completed (based on schedule),
    increase users/{userId}.intensityScore once, clamp to [0,1],
    and append to users/{userId}/scoreHistory.
    """
    user_id = event.params["userId"]
    workout_id = event.params["workoutId"]

    before_snap = event.data.before
    after_snap = event.data.after

    # Ignore deletes
    if after_snap is None or not after_snap.exists:
        return

    after = after_snap.to_dict() or {}
    before = (before_snap.to_dict() if before_snap and before_snap.exists else {}) or {}

    schedule_after = after.get("schedule")
    schedule_before = before.get("schedule")

    # Only act on transition: NOT completed → completed
    if not is_schedule_completed(schedule_after):
        return
    if is_schedule_completed(schedule_before):
        return  # already completed before; do not reward again

    #Increase improvement if multiple units were completed
    num_units = len(schedule_after)
    IMPACT_DELTA_FACTOR = num_units / 1.2

    impact_score = after.get("impactScore")
    if impact_score is None:
        print(f"Workout completed but impactScore missing: userId={user_id}, workoutId={workout_id}")
        return

    user_ref = get_db().collection("users").document(user_id)

    @firestore.transactional
    def txn_update(transaction: firestore.Transaction):
        user_snap = user_ref.get(transaction=transaction)
        user_data = user_snap.to_dict() if user_snap.exists else {}

        try:
            current = float(user_data.get("intensityScore", 0.0) or 0.0)
        except Exception:
            current = 0.0

        try:
            impact = float(impact_score)
        except Exception:
            print(f"Invalid impactScore (not numeric): {impact_score} for workoutId={workout_id}")
            return

        delta = compute_completion_delta(current, impact) * IMPACT_DELTA_FACTOR
        new_score = clamp_0_1(current + delta)

        # If clamping makes it identical, still record? Usually no.
        if new_score == current:
            return

        # Update user doc
        transaction.set(
            user_ref,
            {
                "intensityScore": new_score,
                "intensityScoreLastDelta": delta,
                "intensityScoreLastImpactScore": impact,
                "intensityScoreSourceWorkoutId": workout_id,
                "intensityScoreUpdatedAt": firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )

        # Append to scoreHistory (auto-id)
        hist_ref = user_ref.collection("scoreHistory").document()
        transaction.set(
            hist_ref,
            {
                "ts": firestore.SERVER_TIMESTAMP,
                "type": "workout_completed",
                "workoutId": workout_id,
                "impactScore": impact,
                "previousScore": current,
                "delta": delta,
                "newScore": new_score,
            },
            merge=False,
        )

    txn = get_db().transaction()
    txn_update(txn)


# -------------------------------------------------------------------
# Function 2: Scheduled daily decay shortly after midnight
# -------------------------------------------------------------------

@scheduler_fn.on_schedule(
    schedule="5 0 * * *",  # 00:05 every day
    timezone="Europe/Berlin",
)
def nightly_intensity_decay(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Each day shortly after midnight:
      - Look at yesterday's workout doc (id = YYYY-mm-dd).
      - If missing: intensityScore -= 0.01
      - If present but not finished: intensityScore -= 0.01 * (1 - sumCompleted/sumPlanned)
      - If finished: no change
      - Clamp intensityScore to [0, 1]
      - Append each change to users/{userId}/scoreHistory
    """
    now = datetime.now(TZ)
    yesterday = (now.date() - timedelta(days=1))
    y_id = yesterday.strftime("%Y-%m-%d")

    users_ref = get_db().collection("users")
    user_docs = users_ref.stream()

    batch = get_db().batch()
    writes = 0

    for user_snap in user_docs:
        user_id = user_snap.id
        user_data = user_snap.to_dict() or {}

        try:
            current = float(user_data.get("intensityScore", 0.0) or 0.0)
        except Exception:
            current = 0.0

        user_ref = users_ref.document(user_id)
        workout_ref = user_ref.collection("workoutHistory").document(y_id)
        workout_snap = workout_ref.get()

        penalty = 0.0
        completion_ratio = None  # for history/debug

        if not workout_snap.exists:
            # No workout yesterday -> full penalty
            penalty = 0.01
            completion_ratio = 0.0
        else:
            workout = workout_snap.to_dict() or {}
            schedule = workout.get("schedule")
            sum_completed, sum_planned, finished = schedule_sums(schedule)

            if finished:
                penalty = 0.0
                completion_ratio = 1.0
            else:
                ratio = 0.0
                if sum_planned > 0:
                    ratio = sum_completed / sum_planned
                    # clamp ratio into [0,1]
                    if ratio < 0.0:
                        ratio = 0.0
                    elif ratio > 1.0:
                        ratio = 1.0

                completion_ratio = ratio
                penalty = 0.01 * (1.0 - ratio)

        if penalty <= 0.0:
            continue

        new_score = clamp_0_1(current - penalty)
        if new_score == current:
            continue

        # Update user doc
        batch.set(
            user_ref,
            {
                "intensityScore": new_score,
                "intensityScoreLastDecay": penalty,
                "intensityScoreDecayDate": y_id,
                "intensityScoreUpdatedAt": firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )
        writes += 1

        # Append to scoreHistory (auto-id)
        hist_ref = user_ref.collection("scoreHistory").document()
        batch.set(
            hist_ref,
            {
                "ts": firestore.SERVER_TIMESTAMP,
                "type": "daily_decay",
                "date": y_id,
                "previousScore": current,
                "delta": -penalty,
                "newScore": new_score,
                "completionRatio": completion_ratio,
                "hadWorkoutDoc": bool(workout_snap.exists),
            },
            merge=False,
        )
        writes += 1

        # Firestore batch limit is 500 writes
        if writes >= 450:
            batch.commit()
            batch = get_db().batch()
            writes = 0

    if writes > 0:
        batch.commit()

    print(f"Nightly decay complete for date {y_id}.")
