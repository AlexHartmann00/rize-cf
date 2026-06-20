import unittest

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
        app = create_app(target="create_pro_checkout", source="main.py")

        checkout_response = app.test_client().get("/")

        self.assertEqual(checkout_response.status_code, 401)

        import main

        with app.test_request_context("/", method="POST", data={}):
            webhook_response = main.mollie_webhook(request)

        self.assertEqual(webhook_response.status_code, 400)

        with app.test_request_context("/", method="POST"):
            cancel_response = main.cancel_pro_subscription(request)

        self.assertEqual(cancel_response.status_code, 401)


if __name__ == "__main__":
    unittest.main()
