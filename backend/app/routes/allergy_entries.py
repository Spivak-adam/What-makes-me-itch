from datetime import datetime
from flask import Blueprint, jsonify, request

from app.services.allergy_entry_service import create_allergy_entry

allergy_entries_bp = Blueprint("allergy_entries", __name__)


@allergy_entries_bp.route("/api/allergies", methods=["POST"])
def add_allergy_entry():
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                "error": "Request body is required"
            }), 400

        user_id = data.get("user_id")
        allergen_name = data.get("allergen_name")
        reaction = data.get("reaction")
        notes = data.get("notes")
        date_added = data.get("date_added")

        if not user_id:
            return jsonify({
                "error": "user_id is required"
            }), 400

        if not allergen_name or not allergen_name.strip():
            return jsonify({
                "error": "allergen_name is required"
            }), 400

        if not reaction or not reaction.strip():
            return jsonify({
                "error": "reaction is required"
            }), 400

        parsed_date = None
        if date_added:
            try:
                # Expecting something like: 2026-03-09 00:00:00
                parsed_date = datetime.strptime(date_added, "%Y-%m-%d %H:%M:%S")
            except ValueError:
                return jsonify({
                    "error": "date_added must be in format YYYY-MM-DD HH:MM:SS"
                }), 400

        result = create_allergy_entry(
            user_id=user_id,
            allergen_name=allergen_name.strip(),
            reaction=reaction.strip(),
            notes=notes.strip() if notes else None,
            date_added=parsed_date
        )

        return jsonify(result), 201

    except Exception as e:
        return jsonify({
            "error": "Failed to save allergy entry",
            "details": str(e)
        }), 500