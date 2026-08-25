from __future__ import annotations

from io import BytesIO
from pathlib import Path
from typing import Any, Mapping, Sequence

import reportlab
from reportlab.lib.colors import Color, HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas


BLUE = HexColor("#2F80C2")
DARK_BLUE = HexColor("#102F55")
MUTED = HexColor("#7B8794")
LIGHT_BLUE = HexColor("#EAF4FB")
BLACK = HexColor("#111827")
PAGE_WIDTH, PAGE_HEIGHT = A4
LEFT = 62.5
RIGHT = PAGE_WIDTH - 62.5
ASSET_DIR = Path(__file__).with_name("assets")
LOGO_PATH = ASSET_DIR / "rize_logo_r_blue_white.png"


def _register_fonts() -> tuple[str, str]:
    regular_name = "RizeSans"
    bold_name = "RizeSans-Bold"
    if regular_name in pdfmetrics.getRegisteredFontNames():
        return regular_name, bold_name

    fonts_dir = Path(reportlab.__file__).with_name("fonts")
    pdfmetrics.registerFont(TTFont(regular_name, str(fonts_dir / "Vera.ttf")))
    pdfmetrics.registerFont(TTFont(bold_name, str(fonts_dir / "VeraBd.ttf")))
    return regular_name, bold_name


FONT, FONT_BOLD = _register_fonts()


def _text(value: Any, fallback: str = "") -> str:
    if value is None:
        return fallback
    result = str(value).strip()
    return result or fallback


def _money(value: Any, currency: str = "EUR") -> str:
    try:
        amount = float(value)
    except (TypeError, ValueError):
        amount = 0.0
    formatted = f"{amount:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return f"{formatted} €" if currency == "EUR" else f"{formatted} {currency}"


def _date_label(value: Any) -> str:
    raw = _text(value)
    if len(raw) >= 10 and raw[4:5] == "-" and raw[7:8] == "-":
        return f"{raw[8:10]}.{raw[5:7]}.{raw[:4]}"
    return raw


def _draw_right(canvas: Canvas, text: str, x: float, y: float, font: str, size: float) -> None:
    canvas.setFont(font, size)
    canvas.drawRightString(x, y, text)


def _draw_wrapped(
    canvas: Canvas,
    text: str,
    x: float,
    y: float,
    max_width: float,
    *,
    font: str = FONT,
    size: float = 9.5,
    leading: float = 13,
    max_lines: int = 4,
) -> float:
    words = text.split()
    lines: list[str] = []
    current: list[str] = []
    for word in words:
        candidate = " ".join((*current, word))
        if current and pdfmetrics.stringWidth(candidate, font, size) > max_width:
            lines.append(" ".join(current))
            current = [word]
        else:
            current.append(word)
    if current:
        lines.append(" ".join(current))

    canvas.setFont(font, size)
    for index, line in enumerate(lines[:max_lines]):
        canvas.drawString(x, y - index * leading, line)
    return y - min(len(lines), max_lines) * leading


def _recipient_lines(invoice: Mapping[str, Any]) -> list[str]:
    recipient = invoice.get("recipient") or {}
    if not isinstance(recipient, Mapping):
        recipient = {}
    lines = [
        _text(recipient.get("fullName"), "RIZE Kunde"),
        _text(recipient.get("company")),
        _text(recipient.get("street")),
        " ".join(
            part
            for part in (
                _text(recipient.get("postalCode")),
                _text(recipient.get("city")),
            )
            if part
        ),
        _text(recipient.get("country")),
    ]
    compact = [line for line in lines if line]
    if len(compact) == 1:
        email = _text(recipient.get("email"))
        if email:
            compact.append(email)
    return compact


def _business(invoice: Mapping[str, Any]) -> Mapping[str, Any]:
    value = invoice.get("business") or {}
    return value if isinstance(value, Mapping) else {}


def build_invoice_pdf(invoice: Mapping[str, Any]) -> bytes:
    """Render a paid RIZE subscription invoice as a single-page A4 PDF."""
    output = BytesIO()
    canvas = Canvas(output, pagesize=A4, pageCompression=1)
    invoice_number = _text(invoice.get("invoiceNumber"), "RIZE-ENTWURF")
    canvas.setTitle(f"Rechnung {invoice_number}")
    canvas.setAuthor(_text(_business(invoice).get("legalName"), "RIZE / Coach Flo"))
    canvas.setSubject("RIZE Pro Abonnement")

    business = _business(invoice)
    currency = _text(invoice.get("currency"), "EUR")
    items = invoice.get("items") or []
    if not isinstance(items, Sequence) or isinstance(items, (str, bytes)):
        items = []

    # Brand block, visually derived from the provided Coach Flo invoice.
    if LOGO_PATH.exists():
        canvas.drawImage(
            ImageReader(str(LOGO_PATH)),
            LEFT,
            PAGE_HEIGHT - 126,
            width=62,
            height=62,
            preserveAspectRatio=True,
            anchor="c",
            mask="auto",
        )
    canvas.setFillColor(DARK_BLUE)
    canvas.setFont(FONT_BOLD, 30)
    canvas.drawString(LEFT + 78, PAGE_HEIGHT - 88, "RIZE")
    canvas.setFont(FONT_BOLD, 12)
    canvas.drawString(LEFT + 80, PAGE_HEIGHT - 107, "PERSONAL TRAINING · COACH FLO")

    sender_line = " | ".join(
        part
        for part in (
            _text(business.get("brand"), "RIZE"),
            _text(business.get("legalName"), "Florian Ströhla"),
            _text(business.get("street"), "Goppelstr. 2"),
            _text(business.get("postalCity"), "95236 Stammbach"),
        )
        if part
    )
    canvas.setFillColor(MUTED)
    canvas.setFont(FONT, 8.5)
    canvas.drawString(LEFT, PAGE_HEIGHT - 175, sender_line)

    canvas.setFillColor(BLACK)
    recipient_y = PAGE_HEIGHT - 196
    for index, line in enumerate(_recipient_lines(invoice)):
        canvas.setFont(FONT_BOLD if index == 0 else FONT, 10.5)
        canvas.drawString(LEFT, recipient_y - index * 15, line)

    metadata_x = 320
    metadata_value_x = RIGHT
    metadata = (
        ("Rechnungsnummer", invoice_number, True),
        ("Rechnungsdatum", _date_label(invoice.get("issueDate")), False),
        ("Leistungsdatum", _date_label(invoice.get("serviceDate")), False),
        ("Zahlungsstatus", _text(invoice.get("paymentStatus"), "Bezahlt"), True),
    )
    metadata_y = PAGE_HEIGHT - 198
    for index, (label, value, bold) in enumerate(metadata):
        y = metadata_y - index * 18
        canvas.setFont(FONT_BOLD if bold else FONT, 8.6)
        canvas.drawString(metadata_x, y, label)
        _draw_right(canvas, value, metadata_value_x, y, FONT_BOLD if bold else FONT, 8.6)

    title_y = PAGE_HEIGHT - 310
    canvas.setFillColor(BLACK)
    canvas.setFont(FONT_BOLD, 20)
    canvas.drawString(LEFT, title_y, "Rechnung")
    canvas.setFont(FONT, 10)
    canvas.drawString(
        LEFT,
        title_y - 24,
        "Vielen Dank. Folgende Leistung wurde über Mollie bereits bezahlt:",
    )

    # A restrained watermark replaces the reference's fitness sketch.
    canvas.saveState()
    panel_left = LEFT
    panel_right = RIGHT
    content_left = panel_left + 14
    content_right = panel_right - 14
    canvas.setFillColor(LIGHT_BLUE)
    canvas.roundRect(
        panel_left,
        326,
        panel_right - panel_left,
        156,
        18,
        fill=1,
        stroke=0,
    )
    panel_clip = canvas.beginPath()
    panel_clip.roundRect(
        panel_left,
        326,
        panel_right - panel_left,
        156,
        18,
    )
    canvas.clipPath(panel_clip, stroke=0, fill=0)
    if LOGO_PATH.exists():
        canvas.setFillAlpha(0.035)
        canvas.drawImage(
            ImageReader(str(LOGO_PATH)),
            194,
            296,
            width=210,
            height=210,
            preserveAspectRatio=True,
            mask="auto",
        )
    canvas.restoreState()

    columns = (
        content_left,
        content_left + 34,
        content_left + 236,
        content_left + 314,
        content_right - 44,
        content_right,
    )
    header_y = title_y - 70
    canvas.setFillColor(BLACK)
    canvas.setFont(FONT_BOLD, 8.5)
    for text, x in zip(("Pos.", "Beschreibung", "Menge", "Einheit", "Einzel", "Gesamt"), columns):
        if text in ("Einzel", "Gesamt"):
            _draw_right(canvas, text, x, header_y, FONT_BOLD, 8.5)
        else:
            canvas.drawString(x, header_y, text)
    canvas.setStrokeColor(BLUE)
    canvas.setLineWidth(1.4)
    canvas.line(content_left, header_y - 7, content_right, header_y - 7)

    row_y = header_y - 28
    if not items:
        items = [
            {
                "description": _text(invoice.get("description"), "RIZE Pro Abonnement"),
                "quantity": 1,
                "unit": "Abo",
                "unitPrice": invoice.get("total", 0),
                "total": invoice.get("total", 0),
            }
        ]
    for index, item in enumerate(items[:5], start=1):
        if not isinstance(item, Mapping):
            continue
        canvas.setFillColor(BLACK)
        canvas.setFont(FONT, 8.7)
        canvas.drawString(columns[0], row_y, str(index))
        _draw_wrapped(
            canvas,
            _text(item.get("description"), "RIZE Pro Abonnement"),
            columns[1],
            row_y,
            columns[2] - columns[1] - 8,
            size=8.7,
            leading=11,
            max_lines=2,
        )
        canvas.drawString(columns[2], row_y, _text(item.get("quantity"), "1"))
        canvas.drawString(columns[3], row_y, _text(item.get("unit"), "Abo"))
        _draw_right(canvas, _money(item.get("unitPrice"), currency), columns[4], row_y, FONT, 8.7)
        _draw_right(canvas, _money(item.get("total"), currency), columns[5], row_y, FONT, 8.7)
        row_y -= 32

    total_y = 344
    canvas.setStrokeColor(BLUE)
    canvas.setLineWidth(1.4)
    canvas.line(350, total_y + 20, content_right, total_y + 20)
    canvas.setFillColor(DARK_BLUE)
    canvas.setFont(FONT_BOLD, 11)
    canvas.drawString(362, total_y, "Gesamtbetrag")
    _draw_right(
        canvas,
        _money(invoice.get("total"), currency),
        content_right,
        total_y,
        FONT_BOLD,
        11,
    )

    note_y = 286
    canvas.setFillColor(BLACK)
    note_y = _draw_wrapped(
        canvas,
        _text(
            invoice.get("taxNote"),
            "Gemäß § 19 UStG wird keine Umsatzsteuer berechnet.",
        ),
        LEFT,
        note_y,
        RIGHT - LEFT,
        size=9,
        leading=13,
        max_lines=2,
    )
    _draw_wrapped(
        canvas,
        "Der Rechnungsbetrag wurde bereits über Mollie bezahlt. Es ist keine weitere Zahlung erforderlich.",
        LEFT,
        note_y - 4,
        RIGHT - LEFT,
        size=9,
        leading=13,
        max_lines=2,
    )

    footer_top = 116
    canvas.setStrokeColor(BLUE)
    canvas.setLineWidth(1.4)
    canvas.line(LEFT, footer_top, RIGHT, footer_top)
    footer_y = footer_top - 18
    canvas.setFillColor(BLACK)
    canvas.setFont(FONT, 7.6)
    left_footer = [
        _text(business.get("legalName"), "Florian Ströhla"),
        _text(business.get("street"), "Goppelstr. 2"),
        _text(business.get("postalCity"), "95236 Stammbach"),
    ]
    center_footer = [
        _text(business.get("bankName")),
        _text(business.get("iban")),
        _text(business.get("bic")),
    ]
    right_footer = [
        _text(business.get("phone"), "0155 63125361"),
        _text(business.get("email"), "info@coach-flo.de"),
        _text(business.get("website"), "www.coach-flo.de"),
    ]
    for index, value in enumerate(left_footer):
        if value:
            canvas.drawString(LEFT, footer_y - index * 11, value)
    for index, value in enumerate(center_footer):
        if value:
            canvas.drawCentredString(PAGE_WIDTH / 2, footer_y - index * 11, value)
    for index, value in enumerate(right_footer):
        if value:
            canvas.drawRightString(RIGHT, footer_y - index * 11, value)

    canvas.setFillColor(MUTED)
    canvas.setFont(FONT, 7.5)
    canvas.drawCentredString(PAGE_WIDTH / 2, 35, "Seite 1/1")
    canvas.save()
    return output.getvalue()
