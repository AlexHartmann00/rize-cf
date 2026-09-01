from __future__ import annotations

import base64
from datetime import datetime, timezone
from email.message import EmailMessage as MimeEmailMessage
from email.policy import SMTP
from email.utils import format_datetime
from pathlib import Path
import sys


FUNCTIONS_DIR = Path(__file__).resolve().parents[1]
REPO_DIR = FUNCTIONS_DIR.parent
sys.path.insert(0, str(FUNCTIONS_DIR))

from email_service import (
    EmailMessage,
    cancellation_message,
    invoice_message,
    payment_failed_message,
    subscription_ended_message,
)
from invoice_pdf import build_invoice_pdf


PREVIEW_DIR = REPO_DIR / "output" / "email-previews"
PDF_DIR = REPO_DIR / "output" / "pdf" / "email-examples"
SENDER = "RIZE · Coach Flo <rechnung@mail.coach-flo.de>"
RECIPIENT = "Andrea Hartmann <andrea@example.com>"


def invoice_data(
    *,
    number: str,
    issue_date: str,
    description: str,
    total: str,
    sequence_type: str,
) -> dict:
    return {
        "invoiceNumber": number,
        "issueDate": issue_date,
        "serviceDate": issue_date,
        "paymentStatus": "Bezahlt",
        "paymentMethod": "Mollie",
        "sequenceType": sequence_type,
        "description": description,
        "currency": "EUR",
        "total": total,
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
                "description": description,
                "quantity": 1,
                "unit": "Abo",
                "unitPrice": total,
                "total": total,
            }
        ],
    }


def write_email_preview(slug: str, message: EmailMessage) -> list[str]:
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    (PREVIEW_DIR / f"{slug}.html").write_text(message.html, encoding="utf-8")
    (PREVIEW_DIR / f"{slug}.txt").write_text(message.text + "\n", encoding="utf-8")

    mime = MimeEmailMessage(policy=SMTP)
    mime["From"] = SENDER
    mime["To"] = RECIPIENT
    mime["Reply-To"] = "info@coach-flo.de"
    mime["Subject"] = message.subject
    mime["Date"] = format_datetime(datetime(2026, 8, 25, 14, 30, tzinfo=timezone.utc))
    mime["Message-ID"] = f"<preview-{slug}@coach-flo.de>"
    mime["X-RIZE-Preview"] = "true"
    mime.set_content(message.text)
    mime.add_alternative(message.html, subtype="html")

    filenames: list[str] = []
    for attachment in message.attachments:
        filename = str(attachment["filename"])
        content = base64.b64decode(attachment["content"])
        mime.add_attachment(
            content,
            maintype="application",
            subtype="pdf",
            filename=filename,
        )
        filenames.append(filename)

    (PREVIEW_DIR / f"{slug}.eml").write_bytes(mime.as_bytes())
    return filenames


def main() -> None:
    PDF_DIR.mkdir(parents=True, exist_ok=True)

    initial_number = "RIZE-2026-000001"
    initial_pdf = build_invoice_pdf(
        invoice_data(
            number=initial_number,
            issue_date="2026-08-25",
            description="RIZE Pro-Jahresabo",
            total="39.90",
            sequence_type="first",
        )
    )
    initial_pdf_path = PDF_DIR / f"Rechnung-{initial_number}.pdf"
    initial_pdf_path.write_bytes(initial_pdf)

    renewal_number = "RIZE-2026-000002"
    renewal_pdf = build_invoice_pdf(
        invoice_data(
            number=renewal_number,
            issue_date="2026-09-25",
            description="RIZE Pro-Monatsabo",
            total="3.99",
            sequence_type="recurring",
        )
    )
    renewal_pdf_path = PDF_DIR / f"Rechnung-{renewal_number}.pdf"
    renewal_pdf_path.write_bytes(renewal_pdf)

    examples = [
        (
            "01_willkommen_mit_rechnung",
            "Aktivierung / Erstzahlung",
            invoice_message(
                customer_name="Andrea Hartmann",
                invoice_number=initial_number,
                plan_name="RIZE Pro-Jahresabo",
                total_label="39,90 €",
                is_initial=True,
                pdf_bytes=initial_pdf,
            ),
        ),
        (
            "02_verlaengerung_mit_rechnung",
            "Erfolgreiche Verlängerung",
            invoice_message(
                customer_name="Andrea Hartmann",
                invoice_number=renewal_number,
                plan_name="RIZE Pro-Monatsabo",
                total_label="3,99 €",
                is_initial=False,
                pdf_bytes=renewal_pdf,
            ),
        ),
        (
            "03_zahlung_fehlgeschlagen",
            "Fehlgeschlagene Abozahlung",
            payment_failed_message(
                customer_name="Andrea Hartmann",
                plan_name="RIZE Pro-Monatsabo",
            ),
        ),
        (
            "04_kuendigung",
            "Kündigungsbestätigung",
            cancellation_message(
                customer_name="Andrea Hartmann",
                access_until="2026-09-25",
            ),
        ),
        (
            "05_abo_beendet",
            "Abo endgültig beendet",
            subscription_ended_message(customer_name="Andrea Hartmann"),
        ),
    ]

    rows = []
    for slug, purpose, message in examples:
        attachments = write_email_preview(slug, message)
        attachment_label = ", ".join(attachments) if attachments else "Keine Anlage"
        rows.append(
            f"| {purpose} | [{slug}.eml]({slug}.eml) | "
            f"[{slug}.html]({slug}.html) | {attachment_label} |"
        )

    readme = """# RIZE E-Mail-Beispiele

Die `.eml`-Dateien enthalten die vollständige E-Mail mit Text- und HTML-Version.
Sie lassen sich beispielsweise mit Apple Mail oder Outlook öffnen. Die HTML-Dateien
sind schnelle Browser-Vorschauen. Absender und Empfänger sind Beispieldaten; es wurde
keine E-Mail versendet.

| Ereignis | Vollständige E-Mail | HTML-Vorschau | Anlage |
| --- | --- | --- | --- |
""" + "\n".join(rows) + "\n\nDie separaten PDF-Anlagen liegen unter `../pdf/email-examples/`.\n"
    (PREVIEW_DIR / "README.md").write_text(readme, encoding="utf-8")

    print(PREVIEW_DIR)
    print(initial_pdf_path)
    print(renewal_pdf_path)


if __name__ == "__main__":
    main()
