from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any, Mapping, Tuple
from zoneinfo import ZoneInfo

import os
import json

import requests
from firebase_admin import auth, firestore, initialize_app, messaging
from firebase_functions import firestore_fn, https_fn, scheduler_fn
from firebase_functions.params import SecretParam

from billing_service import (
    build_invoice_snapshot,
    default_business_profile,
    format_eur,
    get_or_create_invoice,
)
from email_service import (
    cancellation_message,
    invoice_message,
    payment_failed_message,
    send_email,
    subscription_ended_message,
)


initialize_app()

_db = None


def get_db():
    global _db
    if _db is None:
        _db = firestore.client()
    return _db


TZ = ZoneInfo("Europe/Berlin")
MOLLIE_API_URL = "https://api.mollie.com/v2"
MOLLIE_API_KEY = SecretParam("MOLLIE_API_KEY")
RESEND_API_KEY = SecretParam("RESEND_API_KEY")
PRO_PLANS = {
    "rize_pro_monthly": {
        "amount": "3.99",
        "description": "RIZE Pro Monatsabo",
        "interval": "1 month",
        "months": 1,
    },
    "rize_pro_yearly": {
        "amount": "39.90",
        "description": "RIZE Pro-Jahresabo",
        "interval": "12 months",
        "months": 12,
    },
}


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


def workouts_for_day(user_ref, day_id: str):
    """Returns v2 session docs and falls back to the legacy date-keyed doc."""
    docs = list(
        user_ref.collection("workoutHistory")
        .where("dayKey", "==", day_id)
        .stream()
    )
    if docs:
        return docs
    legacy = user_ref.collection("workoutHistory").document(day_id).get()
    return [legacy] if legacy.exists else []


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
            title="Zeit für Deine Tagesaufgabe",
            body=(
                "Dein heutiges Training wartet auf Dich. "
                "Ein kurzer Impuls reicht."
            ),
        ),
        data={
            "type": "daily_task_reminder",
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
        workout_snaps = workouts_for_day(user_ref, yesterday_id)

        penalty = 0.0
        completion_ratio = None

        if not workout_snaps:
            penalty = 0.01
            completion_ratio = 0.0
        else:
            schedules = [(snap.to_dict() or {}).get("schedule") for snap in workout_snaps]

            (
                sum_completed,
                sum_planned,
                finished,
            ) = schedule_sums([entry for schedule in schedules if isinstance(schedule, list) for entry in schedule])

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
                "hadWorkoutDoc": bool(workout_snaps),
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
# Function 3: Tagesaufgabe reminder notifications
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

            # Suppress the reminder only when today's task is fully done.
            today_workouts = workouts_for_day(user_ref, today_id)
            if today_workouts and all(
                is_schedule_completed((snap.to_dict() or {}).get("schedule"))
                for snap in today_workouts
            ):
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
                "Tagesaufgabe reminder accepted by FCM: "
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
        "Tagesaufgabe reminder run complete: "
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


@scheduler_fn.on_schedule(schedule="30 16 * * *", timezone="Europe/Berlin")
def send_streak_reminders(event: scheduler_fn.ScheduledEvent) -> None:
    """Remind users with an active streak when today is still empty."""
    now = datetime.now(TZ)
    today_id = now.strftime("%Y-%m-%d")
    yesterday_id = (now.date() - timedelta(days=1)).strftime("%Y-%m-%d")
    for user_snap in get_db().collection("users").stream():
        data = user_snap.to_dict() or {}
        token = data.get("fcmToken")
        user_ref = user_snap.reference
        if not isinstance(token, str) or not token.strip():
            continue
        if data.get("lastStreakReminderDate") == today_id:
            continue
        today_workouts = workouts_for_day(user_ref, today_id)
        if today_workouts and all(
            is_schedule_completed((snap.to_dict() or {}).get("schedule"))
            for snap in today_workouts
        ):
            continue
        yesterday = workouts_for_day(user_ref, yesterday_id)
        if not any(is_schedule_completed((snap.to_dict() or {}).get("schedule")) for snap in yesterday):
            continue
        message = messaging.Message(
            token=token.strip(),
            notification=messaging.Notification(
                title="Deine Serie wartet auf Dich 🔥",
                body="Eine kurze Tagesaufgabe hält Deinen Lauf am Leben.",
            ),
            data={"type": "streak_reminder", "date": today_id, "route": "/home"},
        )
        try:
            messaging.send(message)
            user_ref.set({"lastStreakReminderDate": today_id}, merge=True)
        except messaging.UnregisteredError:
            remove_invalid_fcm_token(user_ref, user_snap.id)
        except Exception as error:
            print(f"Streak reminder failed: userId={user_snap.id}, error={error}")


def _mollie_headers(*, idempotency_key: str | None = None):
    key = MOLLIE_API_KEY.value
    if not key:
        raise RuntimeError("MOLLIE_API_KEY is not configured")
    headers = {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
    }
    if idempotency_key:
        headers["Idempotency-Key"] = idempotency_key[:255]
    return headers


def _resend_sender() -> str:
    return os.environ.get(
        "RESEND_FROM_EMAIL",
        "RIZE · Coach Flo <rechnung@coach-flo.de>",
    )


def _billing_reply_to() -> str:
    return os.environ.get("BILLING_REPLY_TO", "info@coach-flo.de")


def _invoice_business_profile() -> dict[str, str]:
    profile = default_business_profile()
    environment_fields = {
        "legalName": "INVOICE_LEGAL_NAME",
        "street": "INVOICE_STREET",
        "postalCity": "INVOICE_POSTAL_CITY",
        "phone": "INVOICE_PHONE",
        "email": "INVOICE_EMAIL",
        "website": "INVOICE_WEBSITE",
        "bankName": "INVOICE_BANK_NAME",
        "iban": "INVOICE_IBAN",
        "bic": "INVOICE_BIC",
    }
    for field, variable in environment_fields.items():
        configured = os.environ.get(variable)
        if configured:
            profile[field] = configured.strip()
    return profile


def _build_invoice_pdf(invoice: Mapping[str, Any]) -> bytes:
    # Import lazily so non-billing Function startup checks do not require the
    # PDF renderer before deployment dependencies have been installed.
    from invoice_pdf import build_invoice_pdf

    return build_invoice_pdf(invoice)


def _public_functions_base() -> str:
    return os.environ.get(
        "PUBLIC_FUNCTIONS_BASE_URL",
        "https://europe-west1-rize-11838.cloudfunctions.net",
    ).rstrip("/")


def _customer_identity(user_id: str) -> tuple[str, str]:
    user = auth.get_user(user_id)
    return user.display_name or "Sportler", user.email or ""


def _resolve_payment_user_id(payment: dict[str, Any]) -> str | None:
    metadata = payment.get("metadata") or {}
    if not isinstance(metadata, dict):
        metadata = {}
    user_id = metadata.get("userId")
    if user_id:
        return str(user_id)
    subscription_id = payment.get("subscriptionId")
    if not subscription_id:
        return None
    matches = list(
        get_db()
        .collection("users")
        .where("mollieSubscriptionId", "==", subscription_id)
        .limit(1)
        .stream()
    )
    return matches[0].id if matches else None


def _send_user_email_once(
    *,
    user_id: str,
    recipient: str,
    event_id: str,
    message,
) -> str | None:
    event_ref = (
        get_db().collection("users").document(user_id).collection("emailEvents").document(event_id)
    )
    existing = event_ref.get()
    existing_data = existing.to_dict() if existing.exists else {}
    if (existing_data or {}).get("status") == "sent":
        return (existing_data or {}).get("resendEmailId")

    event_ref.set(
        {
            "status": "sending",
            "recipient": recipient,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
    try:
        email_id = send_email(
            api_key=RESEND_API_KEY.value,
            sender=_resend_sender(),
            recipient=recipient,
            message=message,
            idempotency_key=event_id,
            reply_to=_billing_reply_to(),
        )
    except Exception as error:
        event_ref.set(
            {
                "status": "failed",
                "error": str(error)[:500],
                "updatedAt": firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )
        raise
    event_ref.set(
        {
            "status": "sent",
            "resendEmailId": email_id,
            "sentAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
    return email_id


def _create_and_send_payment_invoice(
    *,
    payment: dict[str, Any],
    user_id: str,
    user_data: dict[str, Any],
    plan_id: str,
    plan: dict[str, Any],
    force_send: bool = False,
) -> dict[str, Any]:
    customer_name, customer_email = _customer_identity(user_id)
    if not customer_email:
        raise RuntimeError(f"User {user_id} has no email address")
    snapshot = build_invoice_snapshot(
        payment=payment,
        user_id=user_id,
        customer_name=customer_name,
        customer_email=customer_email,
        user_data=user_data,
        plan_id=plan_id,
        plan=plan,
        now=datetime.now(TZ),
        business_profile=_invoice_business_profile(),
    )
    snapshot["taxNote"] = os.environ.get(
        "INVOICE_TAX_NOTE",
        str(snapshot["taxNote"]),
    )
    invoice, _ = get_or_create_invoice(get_db(), snapshot)
    payment_id = str(payment.get("id") or invoice.get("paymentId") or "")
    invoice_ref = get_db().collection("invoices").document(payment_id)
    if invoice.get("emailStatus") == "sent" and not force_send:
        return invoice

    pdf_bytes = _build_invoice_pdf(invoice)
    message = invoice_message(
        customer_name=customer_name,
        invoice_number=str(invoice["invoiceNumber"]),
        plan_name=str(plan.get("description") or invoice.get("description")),
        total_label=format_eur(invoice.get("total")),
        is_initial=str(payment.get("sequenceType") or "") == "first",
        pdf_bytes=pdf_bytes,
    )
    event_id = f"invoice-{payment_id}" if not force_send else f"invoice-{payment_id}-resend-{datetime.now(TZ).strftime('%Y%m%d%H%M%S')}"
    try:
        email_id = _send_user_email_once(
            user_id=user_id,
            recipient=customer_email,
            event_id=event_id,
            message=message,
        )
    except Exception as error:
        invoice_ref.set(
            {
                "emailStatus": "failed",
                "emailError": str(error)[:500],
                "updatedAt": firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )
        raise
    invoice_ref.set(
        {
            "emailStatus": "sent",
            "resendEmailId": email_id,
            "emailedAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
    invoice["emailStatus"] = "sent"
    invoice["resendEmailId"] = email_id
    return invoice


def _send_subscription_message(
    *,
    user_id: str,
    event_id: str,
    message,
) -> str | None:
    customer_name, customer_email = _customer_identity(user_id)
    if not customer_email:
        return None
    return _send_user_email_once(
        user_id=user_id,
        recipient=customer_email,
        event_id=event_id,
        message=message,
    )


def _subscription_start_date(months: int) -> str:
    """Return the same calendar day after the already-paid billing period."""
    today = datetime.now(TZ).date()
    month_index = today.month - 1 + months
    year = today.year + month_index // 12
    month = month_index % 12 + 1

    next_month = month % 12 + 1
    next_month_year = year + (1 if month == 12 else 0)
    last_day = (
        datetime(next_month_year, next_month, 1).date() - timedelta(days=1)
    ).day
    return today.replace(year=year, month=month, day=min(today.day, last_day)).isoformat()


@https_fn.on_request(region="europe-west1", secrets=[MOLLIE_API_KEY])
def create_pro_checkout(req: https_fn.Request) -> https_fn.Response:
    """Create Mollie's required first payment for the selected Pro plan."""
    authorization = req.headers.get("Authorization", "")
    if not authorization.startswith("Bearer "):
        return https_fn.Response("Unauthorized", status=401)
    try:
        decoded = auth.verify_id_token(authorization[7:])
        user_id = decoded["uid"]
        request_data = req.get_json(silent=True) or {}
        requested_plan = request_data.get("plan", "rize_pro_monthly")
        plan = PRO_PLANS.get(requested_plan)
        if plan is None:
            return https_fn.Response("Invalid plan", status=400)
        user_ref = get_db().collection("users").document(user_id)
        user = user_ref.get().to_dict() or {}
        customer_id = user.get("mollieCustomerId")
        if not customer_id:
            customer_response = requests.post(
                f"{MOLLIE_API_URL}/customers",
                headers=_mollie_headers(),
                json={"name": decoded.get("name"), "email": decoded.get("email"), "metadata": {"userId": user_id}},
                timeout=12,
            )
            customer_response.raise_for_status()
            customer_id = customer_response.json()["id"]
            user_ref.set({"mollieCustomerId": customer_id}, merge=True)
        public_base = _public_functions_base()
        app_url = os.environ.get("APP_RETURN_URL", "https://rize-11838.web.app/payment-complete")
        payment_response = requests.post(
            f"{MOLLIE_API_URL}/payments",
            headers=_mollie_headers(),
            json={
                "amount": {"currency": "EUR", "value": plan["amount"]},
                "description": plan["description"],
                "customerId": customer_id,
                "sequenceType": "first",
                "redirectUrl": app_url,
                "webhookUrl": f"{public_base}/mollie_webhook",
                "metadata": {"userId": user_id, "plan": requested_plan},
            },
            timeout=12,
        )
        payment_response.raise_for_status()
        payment = payment_response.json()
        user_ref.set(
            {
                "mollieInitialPaymentId": payment["id"],
                "subscriptionStatus": "pending",
                "pendingSubscriptionPlan": requested_plan,
            },
            merge=True,
        )
        return https_fn.Response(
            json.dumps({"checkoutUrl": payment["_links"]["checkout"]["href"]}),
            status=200,
            headers={"Content-Type": "application/json"},
        )
    except Exception as error:
        print(f"Mollie checkout failed: {error}")
        return https_fn.Response("Checkout unavailable", status=502)


@https_fn.on_request(
    region="europe-west1",
    secrets=[MOLLIE_API_KEY, RESEND_API_KEY],
)
def cancel_pro_subscription(req: https_fn.Request) -> https_fn.Response:
    """Cancel the authenticated user's active Mollie subscription."""
    authorization = req.headers.get("Authorization", "")
    if not authorization.startswith("Bearer "):
        return https_fn.Response("Unauthorized", status=401)
    try:
        decoded = auth.verify_id_token(authorization[7:])
        user_id = decoded["uid"]
        user_ref = get_db().collection("users").document(user_id)
        user = user_ref.get().to_dict() or {}
        customer_id = user.get("mollieCustomerId")
        subscription_id = user.get("mollieSubscriptionId")
        if not customer_id or not subscription_id:
            return https_fn.Response("No active subscription", status=409)

        subscription_url = (
            f"{MOLLIE_API_URL}/customers/{customer_id}/subscriptions/{subscription_id}"
        )
        current_response = requests.get(
            subscription_url,
            headers=_mollie_headers(),
            timeout=12,
        )
        current_response.raise_for_status()
        access_until = current_response.json().get("nextPaymentDate")

        response = requests.delete(
            subscription_url,
            headers=_mollie_headers(),
            timeout=12,
        )
        response.raise_for_status()
        subscription = response.json()
        user_ref.set(
            {
                "isPro": bool(access_until),
                "subscriptionStatus": "canceled",
                "proAccessUntil": access_until,
                "subscriptionCanceledAt": firestore.SERVER_TIMESTAMP,
                "mollieSubscriptionStatus": subscription.get("status", "canceled"),
            },
            merge=True,
        )
        customer_name, _ = _customer_identity(user_id)
        try:
            _send_subscription_message(
                user_id=user_id,
                event_id=f"subscription-canceled-{subscription_id}",
                message=cancellation_message(
                    customer_name=customer_name,
                    access_until=access_until,
                ),
            )
        except Exception as email_error:
            # The cancellation already succeeded at Mollie. Do not tell the
            # client it failed only because the confirmation mail is delayed.
            print(
                "Cancellation email failed: "
                f"userId={user_id}, subscriptionId={subscription_id}, error={email_error}"
            )
        return https_fn.Response(
            json.dumps({"status": "canceled", "accessUntil": access_until}),
            status=200,
            headers={"Content-Type": "application/json"},
        )
    except Exception as error:
        print(f"Mollie cancellation failed: {error}")
        return https_fn.Response("Cancellation unavailable", status=502)


@https_fn.on_request(
    region="europe-west1",
    secrets=[MOLLIE_API_KEY, RESEND_API_KEY],
)
def mollie_webhook(req: https_fn.Request) -> https_fn.Response:
    payment_id = req.form.get("id") or (req.get_json(silent=True) or {}).get("id")
    if not payment_id:
        return https_fn.Response("Missing id", status=400)
    try:
        response = requests.get(
            f"{MOLLIE_API_URL}/payments/{payment_id}",
            headers=_mollie_headers(),
            timeout=12,
        )
        response.raise_for_status()
        payment = response.json()
        metadata = payment.get("metadata") or {}
        if not isinstance(metadata, dict):
            metadata = {}
        user_id = _resolve_payment_user_id(payment)
        if not user_id:
            return https_fn.Response("OK", status=200)
        user_ref = get_db().collection("users").document(user_id)
        user = user_ref.get().to_dict() or {}
        payment_status = str(payment.get("status") or "")
        if payment_status == "paid":
            plan_id = metadata.get("plan") or user.get(
                "pendingSubscriptionPlan", "rize_pro_monthly"
            )
            plan = PRO_PLANS.get(plan_id, PRO_PLANS["rize_pro_monthly"])
            updates = {
                "isPro": True,
                "subscriptionStatus": "active",
                "subscriptionPlan": plan_id,
                "mollieLastPaymentId": payment_id,
                "mollieLastPaymentStatus": "paid",
                "mollieLastPaidAt": payment.get("paidAt"),
            }
            if (
                not user.get("mollieSubscriptionId")
                and payment.get("sequenceType") == "first"
            ):
                subscription_response = requests.post(
                    f"{MOLLIE_API_URL}/customers/{payment['customerId']}/subscriptions",
                    headers=_mollie_headers(
                        idempotency_key=f"rize-subscription-{payment_id}"
                    ),
                    json={
                        "amount": {"currency": "EUR", "value": plan["amount"]},
                        "interval": plan["interval"],
                        "startDate": _subscription_start_date(plan["months"]),
                        "description": plan["description"],
                        "webhookUrl": f"{_public_functions_base()}/mollie_webhook",
                        "metadata": {"userId": user_id, "plan": plan_id},
                    },
                    timeout=12,
                )
                subscription_response.raise_for_status()
                updates["mollieSubscriptionId"] = subscription_response.json()["id"]
            user_ref.set(updates, merge=True)
            user.update(updates)
            _create_and_send_payment_invoice(
                payment=payment,
                user_id=user_id,
                user_data=user,
                plan_id=str(plan_id),
                plan=plan,
            )
        elif payment_status in ("failed", "canceled", "expired"):
            is_recurring = payment.get("sequenceType") == "recurring" or bool(
                payment.get("subscriptionId")
            )
            subscription_status = "payment_failed" if is_recurring else payment_status
            user_ref.set(
                {
                    "subscriptionStatus": subscription_status,
                    "mollieLastPaymentId": payment_id,
                    "mollieLastPaymentStatus": payment_status,
                    "subscriptionPaymentIssueAt": firestore.SERVER_TIMESTAMP,
                },
                merge=True,
            )
            if is_recurring:
                plan_id = metadata.get("plan") or user.get(
                    "subscriptionPlan", "rize_pro_monthly"
                )
                plan = PRO_PLANS.get(plan_id, PRO_PLANS["rize_pro_monthly"])
                customer_name, _ = _customer_identity(user_id)
                _send_subscription_message(
                    user_id=user_id,
                    event_id=f"payment-{payment_id}-{payment_status}",
                    message=payment_failed_message(
                        customer_name=customer_name,
                        plan_name=str(plan["description"]),
                    ),
                )
        return https_fn.Response("OK", status=200)
    except Exception as error:
        print(f"Mollie webhook failed: paymentId={payment_id}, error={error}")
        return https_fn.Response("Retry", status=500)


def _verified_request_user(req: https_fn.Request) -> dict[str, Any] | None:
    authorization = req.headers.get("Authorization", "")
    if not authorization.startswith("Bearer "):
        return None
    try:
        return auth.verify_id_token(authorization[7:])
    except Exception:
        return None


def _json_response(payload: Mapping[str, Any], status: int = 200) -> https_fn.Response:
    return https_fn.Response(
        json.dumps(payload, ensure_ascii=False),
        status=status,
        headers={"Content-Type": "application/json; charset=utf-8"},
    )


@https_fn.on_request(region="europe-west1")
def update_billing_profile(req: https_fn.Request) -> https_fn.Response:
    """Store the authenticated user's invoice recipient details."""
    decoded = _verified_request_user(req)
    if decoded is None:
        return https_fn.Response("Unauthorized", status=401)
    if req.method not in ("POST", "PUT"):
        return https_fn.Response("Method not allowed", status=405)
    data = req.get_json(silent=True) or {}
    allowed = {
        "fullName": 120,
        "company": 120,
        "street": 160,
        "postalCode": 20,
        "city": 100,
        "country": 80,
        "vatId": 40,
    }
    profile: dict[str, str] = {}
    for key, max_length in allowed.items():
        value = str(data.get(key) or "").strip()
        if len(value) > max_length:
            return _json_response({"error": f"{key} is too long"}, status=400)
        profile[key] = value
    if not profile["fullName"]:
        return _json_response({"error": "fullName is required"}, status=400)
    if not profile["country"]:
        profile["country"] = "Deutschland"
    get_db().collection("users").document(decoded["uid"]).set(
        {
            "billingProfile": profile,
            "billingProfileUpdatedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
    return _json_response({"billingProfile": profile})


@https_fn.on_request(
    region="europe-west1",
    secrets=[MOLLIE_API_KEY, RESEND_API_KEY],
)
def create_invoice(req: https_fn.Request) -> https_fn.Response:
    """Admin-only backfill endpoint for a verified paid Mollie payment."""
    decoded = _verified_request_user(req)
    if decoded is None:
        return https_fn.Response("Unauthorized", status=401)
    if req.method != "POST":
        return https_fn.Response("Method not allowed", status=405)
    if decoded.get("admin") is not True and decoded.get("billingAdmin") is not True:
        return https_fn.Response("Forbidden", status=403)
    data = req.get_json(silent=True) or {}
    payment_id = str(data.get("paymentId") or "").strip()
    if not payment_id:
        return _json_response({"error": "paymentId is required"}, status=400)
    try:
        payment_response = requests.get(
            f"{MOLLIE_API_URL}/payments/{payment_id}",
            headers=_mollie_headers(),
            timeout=12,
        )
        payment_response.raise_for_status()
        payment = payment_response.json()
        if payment.get("status") != "paid":
            return _json_response({"error": "Payment is not paid"}, status=409)
        user_id = _resolve_payment_user_id(payment)
        if not user_id:
            return _json_response({"error": "Payment has no RIZE user"}, status=404)
        user_ref = get_db().collection("users").document(user_id)
        user_data = user_ref.get().to_dict() or {}
        metadata = payment.get("metadata") or {}
        if not isinstance(metadata, dict):
            metadata = {}
        plan_id = metadata.get("plan") or user_data.get(
            "subscriptionPlan", "rize_pro_monthly"
        )
        plan = PRO_PLANS.get(plan_id, PRO_PLANS["rize_pro_monthly"])
        invoice = _create_and_send_payment_invoice(
            payment=payment,
            user_id=user_id,
            user_data=user_data,
            plan_id=str(plan_id),
            plan=plan,
            force_send=bool(data.get("forceSend")),
        )
        return _json_response(
            {
                "invoiceId": payment_id,
                "invoiceNumber": invoice["invoiceNumber"],
                "emailStatus": invoice.get("emailStatus"),
            }
        )
    except Exception as error:
        print(f"Manual invoice creation failed: paymentId={payment_id}, error={error}")
        return _json_response({"error": "Invoice creation failed"}, status=502)


@https_fn.on_request(region="europe-west1", secrets=[RESEND_API_KEY])
def resend_invoice(req: https_fn.Request) -> https_fn.Response:
    """Email an existing invoice PDF again to its authenticated owner."""
    decoded = _verified_request_user(req)
    if decoded is None:
        return https_fn.Response("Unauthorized", status=401)
    if req.method != "POST":
        return https_fn.Response("Method not allowed", status=405)
    data = req.get_json(silent=True) or {}
    invoice_id = str(data.get("invoiceId") or "").strip()
    if not invoice_id:
        return _json_response({"error": "invoiceId is required"}, status=400)
    invoice_ref = get_db().collection("invoices").document(invoice_id)
    invoice_snap = invoice_ref.get()
    if not invoice_snap.exists:
        return https_fn.Response("Not found", status=404)
    invoice = invoice_snap.to_dict() or {}
    if invoice.get("userId") != decoded["uid"]:
        return https_fn.Response("Forbidden", status=403)
    try:
        customer_name, customer_email = _customer_identity(decoded["uid"])
        pdf_bytes = _build_invoice_pdf(invoice)
        plan = PRO_PLANS.get(
            invoice.get("planId"), PRO_PLANS["rize_pro_monthly"]
        )
        message = invoice_message(
            customer_name=customer_name,
            invoice_number=str(invoice["invoiceNumber"]),
            plan_name=str(plan["description"]),
            total_label=format_eur(invoice.get("total")),
            is_initial=invoice.get("sequenceType") == "first",
            pdf_bytes=pdf_bytes,
        )
        email_id = _send_user_email_once(
            user_id=decoded["uid"],
            recipient=customer_email,
            event_id=f"invoice-{invoice_id}-resend-{datetime.now(TZ).strftime('%Y%m%d%H%M%S')}",
            message=message,
        )
        invoice_ref.set(
            {
                "emailStatus": "sent",
                "resendEmailId": email_id,
                "emailedAt": firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )
        return _json_response({"status": "sent", "resendEmailId": email_id})
    except Exception as error:
        print(f"Invoice resend failed: invoiceId={invoice_id}, error={error}")
        return _json_response({"error": "Invoice email failed"}, status=502)


@https_fn.on_request(region="europe-west1")
def download_invoice(req: https_fn.Request) -> https_fn.Response:
    """Return an existing invoice PDF to its authenticated owner."""
    decoded = _verified_request_user(req)
    if decoded is None:
        return https_fn.Response("Unauthorized", status=401)
    if req.method != "GET":
        return https_fn.Response("Method not allowed", status=405)
    data = req.get_json(silent=True) or {}
    invoice_id = str(req.args.get("invoiceId") or data.get("invoiceId") or "").strip()
    if not invoice_id:
        return _json_response({"error": "invoiceId is required"}, status=400)
    invoice_snap = get_db().collection("invoices").document(invoice_id).get()
    if not invoice_snap.exists:
        return https_fn.Response("Not found", status=404)
    invoice = invoice_snap.to_dict() or {}
    if invoice.get("userId") != decoded["uid"]:
        return https_fn.Response("Forbidden", status=403)
    pdf_bytes = _build_invoice_pdf(invoice)
    invoice_number = str(invoice.get("invoiceNumber") or invoice_id)
    return https_fn.Response(
        pdf_bytes,
        status=200,
        headers={
            "Content-Type": "application/pdf",
            "Content-Disposition": f'attachment; filename="Rechnung-{invoice_number}.pdf"',
            "Cache-Control": "private, no-store",
        },
    )


@https_fn.on_request(region="europe-west1")
def list_invoices(req: https_fn.Request) -> https_fn.Response:
    """List invoice metadata for the authenticated user."""
    decoded = _verified_request_user(req)
    if decoded is None:
        return https_fn.Response("Unauthorized", status=401)
    if req.method != "GET":
        return https_fn.Response("Method not allowed", status=405)
    invoices = []
    query = (
        get_db()
        .collection("invoices")
        .where("userId", "==", decoded["uid"])
        .order_by("issueDate", direction=firestore.Query.DESCENDING)
        .limit(50)
    )
    for snapshot in query.stream():
        invoice = snapshot.to_dict() or {}
        invoices.append(
            {
                "invoiceId": snapshot.id,
                "invoiceNumber": invoice.get("invoiceNumber"),
                "issueDate": invoice.get("issueDate"),
                "description": invoice.get("description"),
                "total": invoice.get("total"),
                "currency": invoice.get("currency"),
                "paymentStatus": invoice.get("paymentStatus"),
                "emailStatus": invoice.get("emailStatus"),
            }
        )
    return _json_response({"invoices": invoices})


@scheduler_fn.on_schedule(
    schedule="15 4 * * *",
    timezone="Europe/Berlin",
    secrets=[MOLLIE_API_KEY, RESEND_API_KEY],
)
def reconcile_mollie_subscriptions(
    event: scheduler_fn.ScheduledEvent,
) -> None:
    """Detect Mollie-side subscription termination, which has no classic webhook."""
    users = get_db().collection("users").where(
        "subscriptionStatus", "in", ["active", "payment_failed"]
    ).stream()
    for user_snap in users:
        user = user_snap.to_dict() or {}
        customer_id = user.get("mollieCustomerId")
        subscription_id = user.get("mollieSubscriptionId")
        if not customer_id or not subscription_id:
            continue
        try:
            response = requests.get(
                f"{MOLLIE_API_URL}/customers/{customer_id}/subscriptions/{subscription_id}",
                headers=_mollie_headers(),
                timeout=12,
            )
            response.raise_for_status()
            subscription = response.json()
            mollie_status = str(subscription.get("status") or "")
            user_ref = get_db().collection("users").document(user_snap.id)
            if mollie_status == "active":
                if user.get("subscriptionStatus") != "active":
                    user_ref.set(
                        {
                            "subscriptionStatus": "active",
                            "mollieSubscriptionStatus": mollie_status,
                            "subscriptionPaymentIssueAt": firestore.DELETE_FIELD,
                        },
                        merge=True,
                    )
                continue
            if mollie_status not in ("canceled", "suspended", "completed"):
                continue
            access_until = subscription.get("nextPaymentDate")
            access_active = False
            if access_until:
                try:
                    access_active = datetime.fromisoformat(str(access_until)).date() >= datetime.now(TZ).date()
                except ValueError:
                    access_active = False
            user_ref.set(
                {
                    "isPro": access_active,
                    "subscriptionStatus": "canceled" if access_active else "ended",
                    "proAccessUntil": access_until,
                    "mollieSubscriptionStatus": mollie_status,
                    "subscriptionReconciledAt": firestore.SERVER_TIMESTAMP,
                },
                merge=True,
            )
            customer_name, _ = _customer_identity(user_snap.id)
            _send_subscription_message(
                user_id=user_snap.id,
                event_id=f"subscription-ended-{subscription_id}",
                message=subscription_ended_message(customer_name=customer_name),
            )
        except Exception as error:
            print(
                "Subscription reconciliation failed: "
                f"userId={user_snap.id}, subscriptionId={subscription_id}, error={error}"
            )
