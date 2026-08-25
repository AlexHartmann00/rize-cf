from __future__ import annotations

from datetime import datetime
from decimal import Decimal, InvalidOperation
from typing import Any, Mapping


def _decimal(value: Any) -> Decimal:
    try:
        return Decimal(str(value)).quantize(Decimal("0.01"))
    except (InvalidOperation, TypeError, ValueError):
        return Decimal("0.00")


def format_eur(value: Any) -> str:
    amount = _decimal(value)
    return f"{amount:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".") + " €"


def default_business_profile() -> dict[str, str]:
    return {
        "brand": "RIZE",
        "legalName": "Florian Ströhla",
        "street": "Goppelstr. 2",
        "postalCity": "95236 Stammbach",
        "phone": "0155 63125361",
        "email": "info@coach-flo.de",
        "website": "www.coach-flo.de",
        "bankName": "C24 Bank",
        "iban": "IBAN: DE06 5002 4024 1520 0830 01",
        "bic": "BIC: DEFFDEFFXXX",
    }


def build_invoice_snapshot(
    *,
    payment: Mapping[str, Any],
    user_id: str,
    customer_name: str,
    customer_email: str,
    user_data: Mapping[str, Any],
    plan_id: str,
    plan: Mapping[str, Any],
    now: datetime,
    business_profile: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    amount = payment.get("amount") or {}
    if not isinstance(amount, Mapping):
        amount = {}
    total = _decimal(amount.get("value", plan.get("amount", "0.00")))
    currency = str(amount.get("currency") or "EUR")
    paid_at = str(payment.get("paidAt") or now.isoformat())
    service_date = paid_at[:10]
    issue_date = now.date().isoformat()
    billing_profile = user_data.get("billingProfile") or {}
    if not isinstance(billing_profile, Mapping):
        billing_profile = {}
    recipient = {
        "fullName": str(billing_profile.get("fullName") or customer_name or "RIZE Kunde"),
        "company": str(billing_profile.get("company") or ""),
        "street": str(billing_profile.get("street") or ""),
        "postalCode": str(billing_profile.get("postalCode") or ""),
        "city": str(billing_profile.get("city") or ""),
        "country": str(billing_profile.get("country") or "Deutschland"),
        "email": customer_email,
        "vatId": str(billing_profile.get("vatId") or ""),
    }
    description = str(plan.get("description") or payment.get("description") or "RIZE Pro Abonnement")
    return {
        "schemaVersion": 1,
        "userId": user_id,
        "paymentId": str(payment.get("id") or ""),
        "subscriptionId": str(payment.get("subscriptionId") or ""),
        "sequenceType": str(payment.get("sequenceType") or ""),
        "planId": plan_id,
        "description": description,
        "issueDate": issue_date,
        "serviceDate": service_date,
        "paidAt": paid_at,
        "paymentStatus": "Bezahlt",
        "paymentMethod": str(payment.get("method") or "Mollie"),
        "currency": currency,
        "subtotal": str(total),
        "taxRate": "0.00",
        "taxAmount": "0.00",
        "total": str(total),
        "taxNote": "Gemäß § 19 UStG wird keine Umsatzsteuer berechnet.",
        "recipient": recipient,
        "business": dict(business_profile or default_business_profile()),
        "items": [
            {
                "description": description,
                "quantity": 1,
                "unit": "Abo",
                "unitPrice": str(total),
                "total": str(total),
            }
        ],
        "createdAt": now.isoformat(),
    }


def get_or_create_invoice(
    db,
    snapshot: Mapping[str, Any],
    *,
    transactional=None,
    server_timestamp=None,
) -> tuple[dict[str, Any], bool]:
    payment_id = str(snapshot.get("paymentId") or "").strip()
    if not payment_id:
        raise ValueError("Payment id is required for invoice creation")
    issue_year = str(snapshot.get("issueDate") or "")[:4]
    if len(issue_year) != 4 or not issue_year.isdigit():
        raise ValueError("Invoice issue date must start with a four-digit year")

    invoice_ref = db.collection("invoices").document(payment_id)
    counter_ref = db.collection("billingCounters").document(f"invoices-{issue_year}")
    transaction = db.transaction()

    if transactional is None or server_timestamp is None:
        from firebase_admin import firestore

        transactional = transactional or firestore.transactional
        server_timestamp = server_timestamp or firestore.SERVER_TIMESTAMP

    @transactional
    def allocate(txn):
        existing = invoice_ref.get(transaction=txn)
        if existing.exists:
            return existing.to_dict() or {}, False
        counter = counter_ref.get(transaction=txn)
        counter_data = counter.to_dict() if counter.exists else {}
        next_number = int((counter_data or {}).get("lastNumber", 0)) + 1
        invoice_number = f"RIZE-{issue_year}-{next_number:06d}"
        invoice = dict(snapshot)
        invoice.update(
            {
                "invoiceNumber": invoice_number,
                "sequenceNumber": next_number,
                "status": "issued",
            }
        )
        txn.set(
            counter_ref,
            {"lastNumber": next_number, "updatedAt": server_timestamp},
            merge=True,
        )
        txn.set(invoice_ref, invoice, merge=False)
        return invoice, True

    return allocate(transaction)
