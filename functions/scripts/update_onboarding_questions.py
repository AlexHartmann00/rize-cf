#!/usr/bin/env python3
"""Update the four existing RIZE onboarding question documents in place."""

from __future__ import annotations

import argparse
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore


QUESTION_DOCUMENTS: dict[str, dict[str, Any]] = {
    "H9gt75orvs8q5gEXOhMY": {
        "id": "F1_age",
        "order": 1,
        "role": "safety_cap",
        "weightInScore": 0.0,
        "questionTitle": "Alter",
        "questionText": "Wie alt bist du?",
        "input": "number",
        "mapToRange": "ageCap",
        "ageCap": {
            "<30": 1.00,
            "30-44": 0.90,
            "45-59": 0.78,
            "60-69": 0.65,
            "70+": 0.52,
        },
        # Compatibility fallback for clients that do not support number input.
        "responseOptions": [
            {"optionText": "Unter 30 Jahre alt", "optionValue": 1.00},
            {"optionText": "30 bis 44 Jahre", "optionValue": 0.90},
            {"optionText": "45 bis 59 Jahre", "optionValue": 0.78},
            {"optionText": "60 bis 69 Jahre", "optionValue": 0.65},
            {"optionText": "70 Jahre oder älter", "optionValue": 0.52},
        ],
        "note": (
            "Deckelt den Startwert nur nach oben. Senkt einen aktiven Älteren "
            "nicht pauschal."
        ),
        "schemaVersion": 2,
    },
    "XQoB4sCY9TpWGxqQz4h7": {
        "id": "F2_capacity",
        "order": 2,
        "role": "score_primary",
        "weightInScore": 0.55,
        "questionTitle": "Belastbarkeit",
        "questionText": (
            "Wie belastbar fühlst du dich aktuell? Welche Aussage trifft am "
            "ehesten auf dich zu?"
        ),
        "input": "single_select",
        "responseOptions": [
            {
                "index": 1,
                "optionText": (
                    "Schon bei kurzen Wegen oder Treppensteigen komme ich "
                    "schnell außer Atem."
                ),
                "optionValue": 0.12,
            },
            {
                "index": 2,
                "optionText": (
                    "Zügiges Gehen und ein bis zwei Etagen Treppensteigen "
                    "schaffe ich problemlos."
                ),
                "optionValue": 0.38,
            },
            {
                "index": 3,
                "optionText": (
                    "Leichtes Joggen, längeres Treppensteigen oder moderates "
                    "Training sind für mich gut machbar."
                ),
                "optionValue": 0.62,
            },
            {
                "index": 4,
                "optionText": (
                    "Intensive körperliche Belastungen wie Laufen, Sport oder "
                    "Krafttraining kann ich ohne größere Probleme bewältigen."
                ),
                "optionValue": 0.88,
            },
        ],
        "note": (
            "Aufgabenbezogene Belastungsleiter, aber als Erinnerungsfrage "
            "Selbstauskunft."
        ),
        "schemaVersion": 2,
    },
    "fgiIjhxZKS4AXPDmKQV4": {
        "id": "F3_activity",
        "order": 3,
        "role": "score_secondary",
        "weightInScore": 0.45,
        "questionTitle": "Aktivität pro Woche",
        "questionText": (
            "Wie häufig kommst du pro Woche ins Schwitzen? Gemeint sind "
            "Aktivitäten wie Sport, Krafttraining, zügiges Gehen, Radfahren "
            "oder körperlich anstrengende Arbeit."
        ),
        "input": "single_select",
        "responseOptions": [
            {"index": 1, "optionText": "Nie", "optionValue": 0.10},
            {"index": 2, "optionText": "Einmal pro Woche", "optionValue": 0.30},
            {"index": 3, "optionText": "Zwei- bis dreimal pro Woche", "optionValue": 0.55},
            {
                "index": 4,
                "optionText": "Viermal pro Woche oder öfter",
                "optionValue": 0.80,
            },
        ],
        "note": (
            "Verhalten statt Gefühl. Beispiele umfassen bewusst alle "
            "Modalitäten einschließlich Krafttraining."
        ),
        "schemaVersion": 2,
    },
    "Q7Qvi6Jk2vEbGZt81ntU": {
        "id": "F4_returnToActivity",
        "order": 4,
        "role": "safety_multiplier",
        "weightInScore": 0.0,
        "questionTitle": "Trainingspause",
        "questionText": (
            "Bist du aktuell regelmäßig aktiv – oder kommst du nach einer "
            "Pause zurück?"
        ),
        "input": "single_select",
        "responseOptions": [
            {
                "index": 1,
                "optionText": "Durchgehend regelmäßig aktiv",
                "optionValue": 1.00,
                "multiplier": 1.00,
            },
            {
                "index": 2,
                "optionText": "Kurze Pause (bis zu drei Monate)",
                "optionValue": 0.93,
                "multiplier": 0.93,
            },
            {
                "index": 3,
                "optionText": "Längere Pause (drei bis zwölf Monate)",
                "optionValue": 0.85,
                "multiplier": 0.85,
            },
            {
                "index": 4,
                "optionText": "Sehr lange Pause (über ein Jahr)",
                "optionValue": 0.78,
                "multiplier": 0.78,
            },
        ],
        "note": "Detraining-Sicherheit. Dämpft nur nach unten.",
        "schemaVersion": 2,
    },
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("service_account", help="Path to a Firebase service account JSON")
    parser.add_argument("--apply", action="store_true", help="Commit the update")
    args = parser.parse_args()

    firebase_admin.initialize_app(credentials.Certificate(args.service_account))
    database = firestore.client()
    collection = database.collection("anamnesisQuestions")
    existing = {document.id: document for document in collection.stream()}
    expected_ids = set(QUESTION_DOCUMENTS)
    if set(existing) != expected_ids:
        raise RuntimeError(
            "Refusing to update: anamnesisQuestions document IDs changed. "
            f"Expected {sorted(expected_ids)}, found {sorted(existing)}"
        )

    for document_id, question in QUESTION_DOCUMENTS.items():
        print(
            f"{document_id}: {existing[document_id].to_dict().get('questionTitle')} "
            f"-> {question['id']} ({question['questionTitle']})"
        )

    if not args.apply:
        print("Dry run only. Re-run with --apply to commit.")
        return

    batch = database.batch()
    for document_id, question in QUESTION_DOCUMENTS.items():
        batch.set(collection.document(document_id), question)
    batch.commit()

    verified_by_document = {
        document.id: document.to_dict() for document in collection.stream()
    }
    for document_id, expected_question in QUESTION_DOCUMENTS.items():
        if verified_by_document.get(document_id) != expected_question:
            raise RuntimeError(f"Verification failed for {document_id}")

    verified = sorted(
        verified_by_document.values(), key=lambda question: question["order"]
    )
    print("Verified Firestore onboarding questions:")
    for question in verified:
        print(
            f"{question['order']}: {question['id']} | {question['input']} | "
            f"{len(question['responseOptions'])} compatibility options"
        )


if __name__ == "__main__":
    main()
