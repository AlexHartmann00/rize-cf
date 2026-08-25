import unittest
from pathlib import Path

from firebase_admin import delete_app, get_app
from flask import request
from functions_framework import create_app


class HttpFunctionStartupTest(unittest.TestCase):
    def tearDown(self):
        try:
            delete_app(get_app())
        except ValueError:
            pass

    def test_http_wrappers_start_and_validate_requests(self):
        app = create_app(
            target="create_pro_checkout",
            source=str(Path(__file__).with_name("main.py")),
        )

        checkout_response = app.test_client().get("/")

        self.assertEqual(checkout_response.status_code, 401)

        import main

        with app.test_request_context("/", method="POST", data={}):
            webhook_response = main.mollie_webhook(request)

        self.assertEqual(webhook_response.status_code, 400)

        with app.test_request_context("/", method="POST"):
            cancel_response = main.cancel_pro_subscription(request)

        self.assertEqual(cancel_response.status_code, 401)

        with app.test_request_context("/", method="POST"):
            profile_response = main.update_billing_profile(request)
            create_invoice_response = main.create_invoice(request)
            resend_response = main.resend_invoice(request)
            download_response = main.download_invoice(request)
            list_response = main.list_invoices(request)

        self.assertEqual(profile_response.status_code, 401)
        self.assertEqual(create_invoice_response.status_code, 401)
        self.assertEqual(resend_response.status_code, 401)
        self.assertEqual(download_response.status_code, 401)
        self.assertEqual(list_response.status_code, 401)


if __name__ == "__main__":
    unittest.main()
