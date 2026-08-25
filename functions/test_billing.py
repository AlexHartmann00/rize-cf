from __future__ import annotations

import base64
from datetime import datetime
from io import BytesIO
import unittest
from unittest.mock import Mock, patch

from pypdf import PdfReader

from billing_service import build_invoice_snapshot, get_or_create_invoice
from email_service import (
    cancellation_message,
    invoice_message,
    payment_failed_message,
    send_email,
    subscription_ended_message,
)
from invoice_pdf import build_invoice_pdf


def sample_snapshot() -> dict:
    return build_invoice_snapshot(
        payment={
            "id": "tr_test_paid",
            "status": "paid",
            "sequenceType": "first",
            "paidAt": "2026-08-25T10:15:00+02:00",
            "amount": {"currency": "EUR", "value": "39.90"},
            "method": "creditcard",
        },
        user_id="user-1",
        customer_name="Andrea Hartmann",
        customer_email="andrea@example.com",
        user_data={
            "billingProfile": {
                "fullName": "Andrea Hartmann",
                "street": "Im Schrotmorgen 29",
                "postalCode": "38173",
                "city": "Sickte",
                "country": "Deutschland",
            }
        },
        plan_id="rize_pro_yearly",
        plan={"amount": "39.90", "description": "RIZE Pro-Jahresabo"},
        now=datetime.fromisoformat("2026-08-25T10:16:00+02:00"),
    )


class FakeSnapshot:
    def __init__(self, value):
        self._value = value
        self.exists = value is not None

    def to_dict(self):
        return dict(self._value or {})


class FakeDocument:
    def __init__(self, store, path):
        self.store = store
        self.path = path

    def get(self, transaction=None):
        return FakeSnapshot(self.store.get(self.path))


class FakeCollection:
    def __init__(self, store, path):
        self.store = store
        self.path = path

    def document(self, document_id):
        return FakeDocument(self.store, f"{self.path}/{document_id}")


class FakeTransaction:
    def __init__(self, store):
        self.store = store

    def set(self, reference, value, merge=False):
        if merge:
            current = dict(self.store.get(reference.path) or {})
            current.update(value)
            self.store[reference.path] = current
        else:
            self.store[reference.path] = dict(value)


class FakeDatabase:
    def __init__(self):
        self.store = {}

    def collection(self, name):
        return FakeCollection(self.store, name)

    def transaction(self):
        return FakeTransaction(self.store)


class BillingServiceTest(unittest.TestCase):
    def test_invoice_snapshot_contains_paid_subscription_data(self):
        invoice = sample_snapshot()

        self.assertEqual(invoice["paymentId"], "tr_test_paid")
        self.assertEqual(invoice["sequenceType"], "first")
        self.assertEqual(invoice["total"], "39.90")
        self.assertEqual(invoice["recipient"]["city"], "Sickte")
        self.assertEqual(invoice["taxRate"], "0.00")

    def test_invoice_number_is_allocated_once_per_payment(self):
        database = FakeDatabase()
        first, created = get_or_create_invoice(
            database,
            sample_snapshot(),
            transactional=lambda fn: fn,
            server_timestamp="SERVER_TIMESTAMP",
        )
        duplicate, duplicate_created = get_or_create_invoice(
            database,
            sample_snapshot(),
            transactional=lambda fn: fn,
            server_timestamp="SERVER_TIMESTAMP",
        )

        self.assertTrue(created)
        self.assertFalse(duplicate_created)
        self.assertEqual(first["invoiceNumber"], "RIZE-2026-000001")
        self.assertEqual(duplicate["invoiceNumber"], first["invoiceNumber"])
        self.assertEqual(
            database.store["billingCounters/invoices-2026"]["lastNumber"], 1
        )

    def test_pdf_is_a_single_readable_a4_invoice(self):
        invoice = sample_snapshot()
        invoice["invoiceNumber"] = "RIZE-2026-000001"

        pdf = build_invoice_pdf(invoice)
        reader = PdfReader(BytesIO(pdf))
        text = "\n".join(page.extract_text() or "" for page in reader.pages)

        self.assertTrue(pdf.startswith(b"%PDF"))
        self.assertEqual(len(reader.pages), 1)
        self.assertIn("RIZE-2026-000001", text)
        self.assertIn("Andrea Hartmann", text)
        self.assertIn("RIZE Pro-Jahresabo", text)
        self.assertNotIn("RIZE Pro Jahresabo", text)
        self.assertIn("39,90", text)
        self.assertIn("§ 19 UStG", text)

    @patch("email_service.requests.post")
    def test_resend_payload_contains_pdf_and_idempotency_key(self, post: Mock):
        response = Mock(status_code=200)
        response.json.return_value = {"id": "email-123"}
        response.text = ""
        post.return_value = response
        message = invoice_message(
            customer_name="Andrea Hartmann",
            invoice_number="RIZE-2026-000001",
            plan_name="RIZE Pro-Jahresabo",
            total_label="39,90 €",
            is_initial=True,
            pdf_bytes=b"%PDF-sample",
        )

        email_id = send_email(
            api_key="re_test",
            sender="RIZE <rechnung@example.com>",
            recipient="andrea@example.com",
            message=message,
            idempotency_key="invoice-tr_test_paid",
            reply_to="info@example.com",
        )

        self.assertEqual(email_id, "email-123")
        request = post.call_args
        self.assertEqual(
            request.kwargs["headers"]["Idempotency-Key"],
            "invoice-tr_test_paid",
        )
        attachment = request.kwargs["json"]["attachments"][0]
        self.assertEqual(attachment["filename"], "Rechnung-RIZE-2026-000001.pdf")
        self.assertEqual(base64.b64decode(attachment["content"]), b"%PDF-sample")

    def test_subscription_management_messages_have_plain_text_and_event_tags(self):
        messages = (
            cancellation_message(
                customer_name="Andrea Hartmann",
                access_until="2026-09-25",
            ),
            payment_failed_message(
                customer_name="Andrea Hartmann",
                plan_name="RIZE Pro Monatsabo",
            ),
            subscription_ended_message(customer_name="Andrea Hartmann"),
        )

        self.assertEqual(
            [message.tags[0]["value"] for message in messages],
            ["subscription_canceled", "payment_failed", "subscription_ended"],
        )
        for message in messages:
            self.assertIn("Andrea", message.html)
            self.assertIn("Andrea", message.text)
            self.assertTrue(message.subject)


if __name__ == "__main__":
    unittest.main()
