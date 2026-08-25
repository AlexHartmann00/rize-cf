from __future__ import annotations

from pathlib import Path
import sys


FUNCTIONS_DIR = Path(__file__).resolve().parents[1]
REPO_DIR = FUNCTIONS_DIR.parent
sys.path.insert(0, str(FUNCTIONS_DIR))

from invoice_pdf import build_invoice_pdf


invoice = {
    "invoiceNumber": "RIZE-2026-000001",
    "issueDate": "25.08.2026",
    "serviceDate": "25.08.2026",
    "paymentStatus": "Bezahlt",
    "description": "RIZE Pro-Jahresabo",
    "currency": "EUR",
    "total": "39.90",
    "taxNote": "Gemäß § 19 UStG wird keine Umsatzsteuer berechnet.",
    "recipient": {
        "fullName": "Andrea Hartmann",
        "street": "Im Schrotmorgen 29",
        "postalCode": "38173",
        "city": "Sickte",
        "country": "Deutschland",
        "email": "andrea@example.com",
    },
    "business": {
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
    },
    "items": [
        {
            "description": "RIZE Pro-Jahresabo",
            "quantity": 1,
            "unit": "Abo",
            "unitPrice": "39.90",
            "total": "39.90",
        }
    ],
}

output = REPO_DIR / "output" / "pdf" / "rize_invoice_sample.pdf"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_bytes(build_invoice_pdf(invoice))
print(output)
