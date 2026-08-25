from __future__ import annotations

import base64
from dataclasses import dataclass, field
from html import escape
from typing import Any, Mapping, Sequence

import requests


RESEND_EMAILS_URL = "https://api.resend.com/emails"


class EmailDeliveryError(RuntimeError):
    pass


@dataclass(frozen=True)
class EmailMessage:
    subject: str
    html: str
    text: str
    attachments: Sequence[Mapping[str, str]] = field(default_factory=tuple)
    tags: Sequence[Mapping[str, str]] = field(default_factory=tuple)


def send_email(
    *,
    api_key: str,
    sender: str,
    recipient: str,
    message: EmailMessage,
    idempotency_key: str,
    reply_to: str | None = None,
    timeout: int = 15,
) -> str:
    if not api_key:
        raise EmailDeliveryError("RESEND_API_KEY is not configured")
    if not recipient:
        raise EmailDeliveryError("Recipient email is missing")

    payload: dict[str, Any] = {
        "from": sender,
        "to": [recipient],
        "subject": message.subject,
        "html": message.html,
        "text": message.text,
    }
    if reply_to:
        payload["reply_to"] = reply_to
    if message.attachments:
        payload["attachments"] = list(message.attachments)
    if message.tags:
        payload["tags"] = list(message.tags)

    response = requests.post(
        RESEND_EMAILS_URL,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Idempotency-Key": idempotency_key[:256],
        },
        json=payload,
        timeout=timeout,
    )
    if response.status_code not in (200, 201):
        raise EmailDeliveryError(
            f"Resend returned HTTP {response.status_code}: {response.text[:300]}"
        )
    email_id = (response.json() or {}).get("id")
    if not email_id:
        raise EmailDeliveryError("Resend response did not contain an email id")
    return str(email_id)


def pdf_attachment(filename: str, content: bytes) -> Mapping[str, str]:
    return {
        "filename": filename,
        "content": base64.b64encode(content).decode("ascii"),
    }


def _layout(*, title: str, lead: str, body: str, cta: str | None = None) -> str:
    button = ""
    if cta:
        button = (
            '<p style="margin:28px 0 4px">'
            f'<a href="{escape(cta, quote=True)}" '
            'style="background:#176bc7;color:#fff;text-decoration:none;'
            'font-weight:700;padding:12px 18px;border-radius:10px;display:inline-block">'
            "RIZE öffnen</a></p>"
        )
    return f"""<!doctype html>
<html lang="de"><body style="margin:0;background:#f3f7fb;font-family:Arial,sans-serif;color:#102f55">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f3f7fb;padding:28px 12px">
<tr><td align="center"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:620px;background:#fff;border-radius:18px;overflow:hidden;border:1px solid #dce9f5">
<tr><td style="padding:25px 30px;background:#102f55;color:#fff"><div style="font-size:25px;font-weight:900;letter-spacing:.5px">RIZE</div><div style="font-size:11px;opacity:.72;letter-spacing:1px">PERSONAL TRAINING · COACH FLO</div></td></tr>
<tr><td style="padding:30px"><h1 style="font-size:23px;line-height:1.2;margin:0 0 16px;color:#102f55">{escape(title)}</h1><p style="font-size:16px;line-height:1.55;margin:0 0 18px">{lead}</p><div style="font-size:15px;line-height:1.6;color:#334e68">{body}</div>{button}</td></tr>
<tr><td style="padding:18px 30px;border-top:1px solid #e5edf5;color:#6b7c8f;font-size:12px;line-height:1.5">RIZE · Coach Flo<br>Bei Fragen antworte einfach auf diese E-Mail.</td></tr>
</table></td></tr></table></body></html>"""


def invoice_message(
    *,
    customer_name: str,
    invoice_number: str,
    plan_name: str,
    total_label: str,
    is_initial: bool,
    pdf_bytes: bytes,
) -> EmailMessage:
    first_name = escape((customer_name or "Sportler").split()[0])
    if is_initial:
        title = "Willkommen bei RIZE Pro"
        lead = f"Hallo {first_name}, Dein RIZE Pro Abo ist jetzt aktiv."
        intro = "Vielen Dank für Dein Vertrauen."
        event = "subscription_started"
    else:
        title = "Dein RIZE Pro Abo wurde verlängert"
        lead = f"Hallo {first_name}, Deine nächste Abozahlung wurde erfolgreich verarbeitet."
        intro = "Dein Pro-Zugang läuft ohne Unterbrechung weiter."
        event = "subscription_renewed"
    body = (
        f"<p>{intro}</p><p><strong>Tarif:</strong> {escape(plan_name)}<br>"
        f"<strong>Betrag:</strong> {escape(total_label)}<br>"
        f"<strong>Rechnung:</strong> {escape(invoice_number)}</p>"
        "<p>Die Rechnung findest Du als PDF im Anhang. Der Betrag ist bereits bezahlt.</p>"
    )
    text = (
        f"Hallo {customer_name or 'Sportler'},\n\n{title}.\n"
        f"Tarif: {plan_name}\nBetrag: {total_label}\nRechnung: {invoice_number}\n\n"
        "Die Rechnung ist als PDF angehängt und bereits bezahlt.\n\nRIZE · Coach Flo"
    )
    return EmailMessage(
        subject=f"{title} · Rechnung {invoice_number}",
        html=_layout(title=title, lead=lead, body=body),
        text=text,
        attachments=(pdf_attachment(f"Rechnung-{invoice_number}.pdf", pdf_bytes),),
        tags=(
            {"name": "event", "value": event},
            {"name": "invoice", "value": invoice_number.replace("/", "-")},
        ),
    )


def cancellation_message(
    *, customer_name: str, access_until: str | None
) -> EmailMessage:
    first_name = escape((customer_name or "Sportler").split()[0])
    access_html = (
        f"Dein bereits bezahlter Pro-Zugang bleibt bis <strong>{escape(access_until)}</strong> aktiv."
        if access_until
        else "Es werden keine weiteren Abozahlungen eingezogen."
    )
    text_access = (
        f"Dein bereits bezahlter Pro-Zugang bleibt bis {access_until} aktiv."
        if access_until
        else "Es werden keine weiteren Abozahlungen eingezogen."
    )
    return EmailMessage(
        subject="Bestätigung Deiner RIZE Pro Kündigung",
        html=_layout(
            title="Dein RIZE Pro Abo wurde gekündigt",
            lead=f"Hallo {first_name}, wir bestätigen Deine Kündigung.",
            body=f"<p>{access_html}</p><p>Du kannst RIZE weiterhin mit dem kostenlosen Umfang nutzen.</p>",
        ),
        text=f"Hallo {customer_name or 'Sportler'},\n\nwir bestätigen Deine Kündigung. {text_access}\n\nRIZE · Coach Flo",
        tags=({"name": "event", "value": "subscription_canceled"},),
    )


def payment_failed_message(
    *, customer_name: str, plan_name: str
) -> EmailMessage:
    first_name = escape((customer_name or "Sportler").split()[0])
    return EmailMessage(
        subject="Problem mit Deiner RIZE Pro Zahlung",
        html=_layout(
            title="Deine Abozahlung war noch nicht erfolgreich",
            lead=f"Hallo {first_name}, die Zahlung für {escape(plan_name)} konnte noch nicht verarbeitet werden.",
            body=(
                "<p>Mollie kann die Abbuchung abhängig vom Zahlungsgrund erneut versuchen. "
                "Prüfe bitte Deine hinterlegte Zahlungsart. Wenn die Zahlung später erfolgreich ist, "
                "erhältst Du automatisch Deine Rechnung.</p>"
            ),
        ),
        text=(
            f"Hallo {customer_name or 'Sportler'},\n\ndie Zahlung für {plan_name} konnte noch nicht verarbeitet werden. "
            "Bitte prüfe Deine hinterlegte Zahlungsart.\n\nRIZE · Coach Flo"
        ),
        tags=({"name": "event", "value": "payment_failed"},),
    )


def subscription_ended_message(*, customer_name: str) -> EmailMessage:
    first_name = escape((customer_name or "Sportler").split()[0])
    return EmailMessage(
        subject="Dein RIZE Pro Abo ist beendet",
        html=_layout(
            title="Dein RIZE Pro Abo ist beendet",
            lead=f"Hallo {first_name}, Dein RIZE Pro Abo wurde beendet.",
            body=(
                "<p>Es werden keine weiteren Abozahlungen eingezogen. Du kannst RIZE weiterhin "
                "im kostenlosen Umfang nutzen und jederzeit erneut Pro aktivieren.</p>"
            ),
        ),
        text=(
            f"Hallo {customer_name or 'Sportler'},\n\nDein RIZE Pro Abo ist beendet. "
            "Es werden keine weiteren Abozahlungen eingezogen.\n\nRIZE · Coach Flo"
        ),
        tags=({"name": "event", "value": "subscription_ended"},),
    )
