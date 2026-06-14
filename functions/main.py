from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any, Tuple
from zoneinfo import ZoneInfo

from firebase_admin import firestore, initialize_app, messaging
from firebase_functions import firestore_fn, scheduler_fn


initialize_app()

_db = None


def get_db():
    global _db
    if _db is None:
        _db = firestore.client()
    return _db


TZ = ZoneInfo("Europe/Berlin")


# -------------------------------------------------------------------
# General helpers
# -------------------------------------------------------------------

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
        except (TypeError, ValueError):
            completed_i = 0

        try:
            planned_i = int(planned)
        except (TypeError, ValueError):
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

        completed = entry.get("completedUnits", 0) or 0
        planned = entry.get("plannedUnits", 0) or 0

        try:
            completed_i = int(completed)
        except (TypeError, ValueError):
            completed_i = 0

        try:
            planned_i = int(planned)
        except (TypeError, ValueError):
            planned_i = 0

        sum_completed += completed_i
        sum_planned += planned_i

        if completed_i < planned_i:
            finished = False

    return sum_completed, sum_planned, finished


def compute_completion_delta(
    current_score: float,
    impact_score: float,
) -> float:
    """
    Increase rule:
      delta = 0.004 + 0.1 * (impactScore - currentScore)
      if impactScore > currentScore, otherwise 0.004.
    """
    base = 0.004
    bonus = 0.0

    if impact_score > current_score:
        bonus = 0.1 * (impact_score - current_score)

    return base + bonus


# -------------------------------------------------------------------
# Push-notification helpers
# -------------------------------------------------------------------

def parse_spin_reminder_time(value: Any) -> Tuple[int, int] | None:
    """
    Parses reminder times such as "8:0" and "08:00".

    Returns:
      (hour, minute), or None when the value is invalid.
    """
    if not isinstance(value, str):
        return None

    parts = value.strip().split(":")
    if len(parts) != 2:
        return None

    try:
        hour = int(parts[0])
        minute = int(parts[1])
    except (TypeError, ValueError):
        return None

    if not 0 <= hour <= 23:
        return None

    if not 0 <= minute <= 59:
        return None

    return hour, minute


def is_reminder_due(
    now_dt: datetime,
    target_hour: int,
    target_minute: int,
    window_minutes: int = 10,
) -> bool:
    """
    Returns True only after the configured reminder time and within the
    configured delivery window.

    A one-sided window prevents notifications from being sent before the
    user's selected time.
    """
    now_total = now_dt.hour * 60 + now_dt.minute
    target_total = target_hour * 60 + target_minute
    minutes_after_target = now_total - target_total

    return 0 <= minutes_after_target < window_minutes


def build_spin_reminder_message(
    fcm_token: str,
    today_id: str,
) -> messaging.Message:
    """
    Builds one cross-platform notification message.

    The top-level notification is understood by both Android and iOS.
    Platform-specific settings request prompt delivery and the default sound.
    """
    return messaging.Message(
        token=fcm_token,
        notification=messaging.Notification(
            title="Zeit für Deinen Daily Spin",
            body=(
                "Dein heutiges Training wartet auf Dich. "
                "Ein kurzer Impuls reicht."
            ),
        ),
        data={
            "type": "spin_reminder",
            "date": today_id,
            "route": "/home",
        },
        android=messaging.AndroidConfig(
            priority="high",
            ttl=timedelta(hours=2),
            notification=messaging.AndroidNotification(
                sound="default",
            ),
        ),
        apns=messaging.APNSConfig(
            headers={
                "apns-priority": "10",
                "apns-push-type": "alert",
                "apns-expiration": str(
                    int((datetime.now().timestamp()) + 2 * 60 * 60)
                ),
            },
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    sound="default",
                ),
            ),
        ),
    )


def remove_invalid_fcm_token(
    user_ref: firestore.DocumentReference,
    user_id: str,
) -> None:
    user_ref.set(
        {
            "fcmToken": firestore.DELETE_FIELD,
            "fcmTokenInvalidatedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
    print(f"Removed invalid FCM token for user {user_id}.")


# -------------------------------------------------------------------
# Function 1: Trigger on workoutHistory create/update
# -------------------------------------------------------------------

@firestore_fn.on_document_written(
    document="users/{userId}/workoutHistory/{workoutId}"
)
def on_workout_written(
    event: firestore_fn.Event[
        firestore_fn.Change[firestore_fn.DocumentSnapshot]
    ],
):
    """
    Fires on create, update and delete for:
      users/{userId}/workoutHistory/{workoutId}

    If a workout transitions from incomplete to completed, increase the
    user's intensityScore once, clamp it to [0, 1], and append a score-history
    entry.
    """
    user_id = event.params["userId"]
    workout_id = event.params["workoutId"]

    before_snap = event.data.before
    after_snap = event.data.after

    # Ignore deletes.
    if after_snap is None or not after_snap.exists:
        return

    after = after_snap.to_dict() or {}
    before = (
        before_snap.to_dict()
        if before_snap is not None and before_snap.exists
        else {}
    ) or {}

    schedule_after = after.get("schedule")
    schedule_before = before.get("schedule")

    # Only reward the transition from incomplete to complete.
    if not is_schedule_completed(schedule_after):
        return

    if is_schedule_completed(schedule_before):
        return

    number_of_units = len(schedule_after)
    impact_delta_factor = number_of_units / 1.2

    impact_score = after.get("impactScore")
    if impact_score is None:
        print(
            "Workout completed but impactScore is missing: "
            f"userId={user_id}, workoutId={workout_id}"
        )
        return

    user_ref = get_db().collection("users").document(user_id)

    @firestore.transactional
    def txn_update(transaction: firestore.Transaction):
        user_snap = user_ref.get(transaction=transaction)
        user_data = user_snap.to_dict() if user_snap.exists else {}

        try:
            current = float(user_data.get("intensityScore", 0.0) or 0.0)
        except (TypeError, ValueError):
            current = 0.0

        try:
            impact = float(impact_score)
        except (TypeError, ValueError):
            print(
                "Invalid impactScore: "
                f"value={impact_score}, workoutId={workout_id}"
            )
            return

        delta = (
            compute_completion_delta(current, impact)
            * impact_delta_factor
        )
        new_score = clamp_0_1(current + delta)

        if new_score == current:
            return

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

        history_ref = user_ref.collection("scoreHistory").document()
        transaction.set(
            history_ref,
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

    transaction = get_db().transaction()
    txn_update(transaction)


# -------------------------------------------------------------------
# Function 2: Daily intensity decay
# -------------------------------------------------------------------

@scheduler_fn.on_schedule(
    schedule="5 0 * * *",
    timezone="Europe/Berlin",
)
def nightly_intensity_decay(
    event: scheduler_fn.ScheduledEvent,
) -> None:
    """
    Shortly after midnight:

      - Inspect yesterday's workout document.
      - Apply the full decay when no workout exists.
      - Apply proportional decay when the workout is incomplete.
      - Apply no decay when it is complete.
      - Clamp intensityScore to [0, 1].
      - Append each change to scoreHistory.
    """
    now = datetime.now(TZ)
    yesterday = now.date() - timedelta(days=1)
    yesterday_id = yesterday.strftime("%Y-%m-%d")

    users_ref = get_db().collection("users")
    user_docs = users_ref.stream()

    batch = get_db().batch()
    writes = 0
    affected_users = 0

    for user_snap in user_docs:
        user_id = user_snap.id
        user_data = user_snap.to_dict() or {}

        try:
            current = float(user_data.get("intensityScore", 0.0) or 0.0)
        except (TypeError, ValueError):
            current = 0.0

        user_ref = users_ref.document(user_id)
        workout_ref = (
            user_ref
            .collection("workoutHistory")
            .document(yesterday_id)
        )
        workout_snap = workout_ref.get()

        penalty = 0.0
        completion_ratio = None

        if not workout_snap.exists:
            penalty = 0.01
            completion_ratio = 0.0
        else:
            workout = workout_snap.to_dict() or {}
            schedule = workout.get("schedule")

            (
                sum_completed,
                sum_planned,
                finished,
            ) = schedule_sums(schedule)

            if finished:
                penalty = 0.0
                completion_ratio = 1.0
            else:
                ratio = 0.0

                if sum_planned > 0:
                    ratio = sum_completed / sum_planned
                    ratio = max(0.0, min(1.0, ratio))

                completion_ratio = ratio
                penalty = 0.01 * (1.0 - ratio)

        if penalty <= 0.0:
            continue

        new_score = clamp_0_1(current - penalty)
        if new_score == current:
            continue

        batch.set(
            user_ref,
            {
                "intensityScore": new_score,
                "intensityScoreLastDecay": penalty,
                "intensityScoreDecayDate": yesterday_id,
                "intensityScoreUpdatedAt": firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )
        writes += 1

        history_ref = user_ref.collection("scoreHistory").document()
        batch.set(
            history_ref,
            {
                "ts": firestore.SERVER_TIMESTAMP,
                "type": "daily_decay",
                "date": yesterday_id,
                "previousScore": current,
                "delta": -penalty,
                "newScore": new_score,
                "completionRatio": completion_ratio,
                "hadWorkoutDoc": bool(workout_snap.exists),
            },
            merge=False,
        )
        writes += 1
        affected_users += 1

        # Stay safely below Firestore's 500-write batch limit.
        if writes >= 450:
            batch.commit()
            batch = get_db().batch()
            writes = 0

    if writes > 0:
        batch.commit()

    print(
        "Nightly decay complete: "
        f"date={yesterday_id}, affectedUsers={affected_users}"
    )


# -------------------------------------------------------------------
# Function 3: Daily Spin reminder notifications
# -------------------------------------------------------------------

@scheduler_fn.on_schedule(
    schedule="*/5 * * * *",
    timezone="Europe/Berlin",
)
def send_spin_reminders(
    event: scheduler_fn.ScheduledEvent,
) -> None:
    """
    Every five minutes:

      - Read each user's spinReminderTime.
      - Send only at or shortly after that time.
      - Skip the user when today's workoutHistory document already exists.
      - Skip when a reminder was already sent today.
      - Send an Android/iOS notification with explicit delivery options.
      - Remove stale registration tokens.
      - Write detailed summary logs for diagnosis.

    The existing workout-document check is intentionally preserved:
    any users/{userId}/workoutHistory/{today} document suppresses the reminder.
    """
    now = datetime.now(TZ)
    today_id = now.strftime("%Y-%m-%d")

    users_ref = get_db().collection("users")

    processed = 0
    configured = 0
    due = 0
    sent = 0

    skipped_existing_workout = 0
    skipped_already_sent = 0
    missing_tokens = 0
    invalid_reminder_times = 0
    invalid_tokens = 0
    send_failures = 0

    for user_snap in users_ref.stream():
        processed += 1

        user_id = user_snap.id
        user_data = user_snap.to_dict() or {}
        user_ref = users_ref.document(user_id)

        try:
            raw_reminder_time = user_data.get("spinReminderTime")
            if not raw_reminder_time:
                continue

            configured += 1

            parsed = parse_spin_reminder_time(raw_reminder_time)
            if parsed is None:
                invalid_reminder_times += 1
                print(
                    "Invalid spinReminderTime: "
                    f"userId={user_id}, value={raw_reminder_time!r}"
                )
                continue

            reminder_hour, reminder_minute = parsed

            if not is_reminder_due(
                now_dt=now,
                target_hour=reminder_hour,
                target_minute=reminder_minute,
                window_minutes=10,
            ):
                continue

            due += 1

            # Prevent duplicate reminders during the ten-minute send window.
            if user_data.get("lastSpinReminderDate") == today_id:
                skipped_already_sent += 1
                continue

            # Intentionally preserve the application's existing semantics:
            # any workout document for today suppresses the reminder.
            workout_ref = (
                user_ref
                .collection("workoutHistory")
                .document(today_id)
            )
            workout_snap = workout_ref.get()

            if workout_snap.exists:
                skipped_existing_workout += 1
                continue

            raw_token = user_data.get("fcmToken")
            if not isinstance(raw_token, str) or not raw_token.strip():
                missing_tokens += 1
                print(f"No usable FCM token for user {user_id}.")
                continue

            fcm_token = raw_token.strip()
            message = build_spin_reminder_message(
                fcm_token=fcm_token,
                today_id=today_id,
            )

            try:
                message_id = messaging.send(message)

            except messaging.UnregisteredError as error:
                invalid_tokens += 1
                print(
                    "FCM token is no longer registered: "
                    f"userId={user_id}, error={error}"
                )
                remove_invalid_fcm_token(user_ref, user_id)
                continue

            except messaging.SenderIdMismatchError as error:
                send_failures += 1
                print(
                    "FCM sender-ID mismatch. The token was created by a "
                    "different Firebase project: "
                    f"userId={user_id}, error={error}"
                )
                continue

            except messaging.ThirdPartyAuthError as error:
                send_failures += 1
                print(
                    "FCM/APNs authentication failed. Check the APNs key or "
                    "certificate in Firebase: "
                    f"userId={user_id}, error={error}"
                )
                continue

            except messaging.QuotaExceededError as error:
                send_failures += 1
                print(
                    "FCM quota exceeded: "
                    f"userId={user_id}, error={error}"
                )
                continue

            except Exception as error:
                send_failures += 1
                print(
                    "FCM send failed: "
                    f"userId={user_id}, "
                    f"errorType={type(error).__name__}, "
                    f"error={error}"
                )
                continue

            # Only mark the reminder as sent after FCM accepted it.
            user_ref.set(
                {
                    "lastSpinReminderDate": today_id,
                    "lastSpinReminderSentAt":
                        firestore.SERVER_TIMESTAMP,
                    "lastSpinReminderMessageId": message_id,
                },
                merge=True,
            )

            sent += 1
            print(
                "Spin reminder accepted by FCM: "
                f"userId={user_id}, messageId={message_id}"
            )

        except Exception as error:
            send_failures += 1
            print(
                "Unexpected reminder-processing error: "
                f"userId={user_id}, "
                f"errorType={type(error).__name__}, "
                f"error={error}"
            )

    print(
        "Spin reminder run complete: "
        f"date={today_id}, "
        f"time={now.strftime('%H:%M:%S')}, "
        f"processed={processed}, "
        f"configured={configured}, "
        f"due={due}, "
        f"sent={sent}, "
        f"existingWorkout={skipped_existing_workout}, "
        f"alreadySent={skipped_already_sent}, "
        f"missingToken={missing_tokens}, "
        f"invalidReminderTime={invalid_reminder_times}, "
        f"invalidToken={invalid_tokens}, "
        f"sendFailures={send_failures}"
    )
