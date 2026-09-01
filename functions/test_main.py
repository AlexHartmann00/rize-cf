import unittest
from pathlib import Path
from unittest.mock import Mock

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


if __name__ == "__main__":
    unittest.main()
