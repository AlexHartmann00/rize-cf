import unittest
from pathlib import Path
from unittest.mock import Mock, patch
from types import SimpleNamespace
import inspect

from firebase_admin import delete_app, get_app
from flask import request
from functions_framework import create_app


class HttpFunctionStartupTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = create_app(
            target="create_pro_checkout",
            source=str(Path(__file__).with_name("main.py")),
        )
        import main

        cls.main = main

    @classmethod
    def tearDownClass(cls):
        try:
            delete_app(get_app())
        except ValueError:
            pass

    def test_http_wrappers_start_and_validate_requests(self):
        checkout_response = self.app.test_client().get("/")

        self.assertEqual(checkout_response.status_code, 401)

        with self.app.test_request_context("/", method="POST", data={}):
            webhook_response = self.main.mollie_webhook(request)

        self.assertEqual(webhook_response.status_code, 400)

        with self.app.test_request_context("/", method="POST"):
            cancel_response = self.main.cancel_pro_subscription(request)

        self.assertEqual(cancel_response.status_code, 401)

        with self.app.test_request_context("/", method="POST"):
            profile_response = self.main.update_billing_profile(request)
            create_invoice_response = self.main.create_invoice(request)
            resend_response = self.main.resend_invoice(request)
            download_response = self.main.download_invoice(request)
            list_response = self.main.list_invoices(request)

        self.assertEqual(profile_response.status_code, 401)
        self.assertEqual(create_invoice_response.status_code, 401)
        self.assertEqual(resend_response.status_code, 401)
        self.assertEqual(download_response.status_code, 401)
        self.assertEqual(list_response.status_code, 401)

    def test_cancel_is_idempotent_for_already_canceled_mollie_subscription(self):
        self.assertEqual(
            self.main.terminal_subscription_state("canceled", None),
            (False, "ended"),
        )
        self.assertIsNone(
            self.main.terminal_subscription_state("active", None)
        )
        self.assertEqual(
            self.main.terminal_subscription_state("canceled", "2099-01-01"),
            (True, "canceled"),
        )

    def test_successful_empty_mollie_response_does_not_require_json(self):
        response = Mock(content=b"")

        self.assertEqual(self.main.response_json_or_empty(response), {})
        response.json.assert_not_called()

    def test_paid_period_survives_missing_next_payment_date(self):
        user = {"mollieLastPaidAt": "2026-10-10T12:00:00Z",
                "subscriptionPlan": "rize_pro_monthly"}
        self.assertEqual(self.main.subscription_access_until(user), "2026-11-10")
        self.assertEqual(self.main.subscription_access_until({
            **user, "proAccessUntil": "2026-12-10"}), "2026-12-10")
        self.assertEqual(self.main._subscription_start_date(1, "2026-01-31T12:00:00Z"),
                         "2026-02-28")
        self.assertEqual(self.main.subscription_access_until({
            "mollieLastPaidAt": "2024-02-29T12:00:00Z",
            "subscriptionPlan": "rize_pro_yearly"}), "2025-02-28")
        self.assertIsNone(self.main.subscription_access_until({}))

    def test_expired_checkout_cannot_remove_paid_subscription(self):
        for status in ("expired", "canceled", "failed"):
            with self.subTest(status=status):
                db = Mock()
                user_ref = db.collection.return_value.document.return_value
                user_ref.get.return_value.to_dict.return_value = {
                    "isPro": True, "subscriptionStatus": "active",
                    "mollieLastPaidAt": "2026-10-10T12:00:00Z",
                    "mollieSubscriptionId": "sub_current",
                }
                response = Mock()
                response.json.return_value = {"id": "tr_old", "status": status,
                    "sequenceType": "first", "metadata": {"userId": "user"}}
                with patch.object(self.main, "get_db", return_value=db), patch.object(
                    self.main, "_mollie_headers", return_value={}
                ), patch.object(self.main.requests, "get", return_value=response):
                    with self.app.test_request_context("/", method="POST", data={"id": "tr_old"}):
                        result = self.main.mollie_webhook(request)
                self.assertEqual(result.status_code, 200)
                user_ref.set.assert_not_called()

    def test_current_unpaid_checkout_can_expire(self):
        db = Mock()
        user_ref = db.collection.return_value.document.return_value
        user_ref.get.return_value.to_dict.return_value = {"mollieInitialPaymentId": "tr_pending"}
        response = Mock()
        response.json.return_value = {"id": "tr_pending", "status": "expired",
            "sequenceType": "first", "metadata": {"userId": "user"}}
        with patch.object(self.main, "get_db", return_value=db), patch.object(
            self.main, "_mollie_headers", return_value={}
        ), patch.object(self.main.requests, "get", return_value=response):
            with self.app.test_request_context("/", method="POST", data={"id": "tr_pending"}):
                result = self.main.mollie_webhook(request)
        self.assertEqual(result.status_code, 200)
        self.assertEqual(user_ref.set.call_args.args[0]["subscriptionStatus"], "expired")

    def test_paid_webhook_persists_period_and_duplicate_does_not_extend_it(self):
        db = Mock()
        user_ref = db.collection.return_value.document.return_value
        user = {"mollieSubscriptionId": "sub_current"}
        user_ref.get.return_value.to_dict.side_effect = lambda: dict(user)
        user_ref.set.side_effect = lambda updates, **kwargs: user.update(updates)
        response = Mock()
        response.json.return_value = {"id": "tr_paid", "status": "paid", "mode": "test",
            "paidAt": "2026-10-10T12:00:00Z", "sequenceType": "first",
            "metadata": {"userId": "user", "plan": "rize_pro_monthly"}}
        with patch.object(self.main, "get_db", return_value=db), patch.object(
            self.main, "_mollie_headers", return_value={}
        ), patch.object(self.main.requests, "get", return_value=response), patch.object(
            self.main, "_create_and_send_payment_invoice"
        ):
            for _ in range(2):
                with self.app.test_request_context("/", method="POST", data={"id": "tr_paid"}):
                    result = self.main.mollie_webhook(request)
                self.assertEqual(result.status_code, 200)
                self.assertEqual(user["proAccessUntil"], "2026-11-10")
                self.assertTrue(user["isPro"])

    def test_nightly_reconciliation_restores_paid_period_without_next_payment(self):
        for status in ("active", "ended", "expired", "canceled"):
            with self.subTest(status=status):
                db = Mock()
                snapshot = Mock(id="user")
                snapshot.to_dict.return_value = {"subscriptionStatus": status,
                    "mollieCustomerId": "cst_test", "mollieSubscriptionId": "sub_test",
                    "mollieLastPaidAt": "2099-01-10T12:00:00Z",
                    "subscriptionPlan": "rize_pro_monthly"}
                db.collection.return_value.where.return_value.stream.return_value = [snapshot]
                response = Mock()
                response.json.return_value = {"status": "suspended", "nextPaymentDate": None}
                with patch.object(self.main, "get_db", return_value=db), patch.object(
                    self.main, "_mollie_headers", return_value={}
                ), patch.object(self.main.requests, "get", return_value=response), patch.object(
                    self.main, "_send_subscription_message"
                ) as send_message:
                    inspect.unwrap(self.main.reconcile_mollie_subscriptions)(Mock())
                query_statuses = db.collection.return_value.where.call_args.args[2]
                self.assertIn(status, query_statuses)
                updates = db.collection.return_value.document.return_value.set.call_args.args[0]
                self.assertTrue(updates["isPro"])
                self.assertEqual(updates["proAccessUntil"], "2099-02-10")
                send_message.assert_not_called()

    def test_private_billing_profile_requires_only_invoice_address(self):
        complete = {
            "fullName": "Alex Hartmann",
            "street": "Musterstraße 1",
            "postalCode": "12345",
            "city": "Berlin",
            "country": "Deutschland",
        }

        self.assertEqual(self.main.missing_billing_fields(complete), [])
        self.assertEqual(
            self.main.missing_billing_fields({**complete, "street": ""}),
            ["street"],
        )

    def test_partial_workout_reward_and_history_are_scaled_once(self):
        for kind in ("reps", "time"):
            with self.subTest(kind=kind):
                data = {"type": kind, "baseReps": 10, "baseSeconds": 10,
                        "intensityFactor": 1, "impactScore": .6,
                        "schedule": [{"plannedUnits": 1, "completedUnits": 1, "actualValue": 5}]}
                before = Mock(exists=False)
                after = Mock(exists=True)
                after.to_dict.return_value = data
                event = SimpleNamespace(params={"userId": "user", "workoutId": "workout"},
                                        data=SimpleNamespace(before=before, after=after))
                db = Mock()
                user_ref = db.collection.return_value.document.return_value
                user_ref.get.return_value = Mock(exists=True)
                user_ref.get.return_value.to_dict.return_value = {"intensityScore": .3}
                history_ref = user_ref.collection.return_value.document.return_value
                history_ref.get.return_value = Mock(exists=False)
                transaction = db.transaction.return_value
                with patch.object(self.main, "get_db", return_value=db), patch.object(
                    self.main.firestore, "transactional", side_effect=lambda fn: fn
                ):
                    inspect.unwrap(self.main.on_workout_written)(event)
                    writes = transaction.set.call_args_list
                    self.assertEqual(len(writes), 2)
                    reward = .034 * .5 / 1.2
                    self.assertAlmostEqual(writes[0].args[1]["intensityScore"], .3 + reward)
                    self.assertAlmostEqual(writes[1].args[1]["delta"], reward)
                    self.assertEqual(writes[1].args[1]["impactScore"], .3)
                    self.assertEqual(writes[1].args[1]["completionRatio"], .5)
                    transaction.reset_mock()
                    history_ref.get.return_value = Mock(exists=True)
                    inspect.unwrap(self.main.on_workout_written)(event)
                    transaction.set.assert_not_called()

    def test_multi_exercise_reward_uses_plan_size_and_legacy_fallback(self):
        for stored_count in (5, None):
            with self.subTest(stored_count=stored_count):
                data = {"type": "reps", "baseReps": 10, "impactScore": .6,
                        "planId": "plan", "planExerciseCount": stored_count,
                        "schedule": [{"plannedUnits": 1, "completedUnits": 1,
                                      "actualValue": 10}]}
                after = Mock(exists=True)
                after.to_dict.return_value = data
                event = SimpleNamespace(params={"userId": "user", "workoutId": "exercise"},
                                        data=SimpleNamespace(before=Mock(exists=False), after=after))
                db = Mock()
                user_ref = db.collection.return_value.document.return_value
                user_ref.get.return_value = Mock(exists=True)
                user_ref.get.return_value.to_dict.return_value = {"intensityScore": .5}
                collection = user_ref.collection.return_value
                collection.document.return_value.get.return_value = Mock(exists=False)
                collection.where.return_value.stream.return_value = [Mock()] * 5
                with patch.object(self.main, "get_db", return_value=db), patch.object(
                    self.main.firestore, "transactional", side_effect=lambda fn: fn
                ):
                    inspect.unwrap(self.main.on_workout_written)(event)
                writes = db.transaction.return_value.set.call_args_list
                self.assertAlmostEqual(writes[0].args[1]["intensityScore"],
                                       .5 + .014 / 1.2 / (5 ** .5))
                self.assertEqual(writes[1].args[1]["planExerciseCount"], 5)
                if stored_count is None:
                    collection.where.assert_called_once_with("planId", "==", "plan")
                else:
                    collection.where.assert_not_called()


if __name__ == "__main__":
    unittest.main()
