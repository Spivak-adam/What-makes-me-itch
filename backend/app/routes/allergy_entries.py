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
        severity = data.get("severity")
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
                parsed_date = datetime.strptime(
                    date_added,
                    "%Y-%m-%d %H:%M:%S"
                )

            except ValueError:
                return jsonify({
                    "error": "date_added must be in format YYYY-MM-DD HH:MM:SS"
                }), 400

        result = create_allergy_entry(
            user_id=user_id,
            allergen_name=allergen_name.strip(),
            reaction=reaction.strip(),
            severity=severity,
            notes=notes,
            product_id=None,
            date_added=parsed_date
        )

        return jsonify(result), 201

    except Exception as e:
        return jsonify({
            "error": "Failed to save allergy entry",
            "details": str(e)
        }), 500
    
@allergy_entries_bp.route("/api/scanned-product-entry", methods=["POST"])
def save_scanned_product_entry():
    try:
        data = request.get_json()

        user_id = data.get("user_id")
        product_name = data.get("product_name")
        ingredients = data.get("ingredients") or "No ingredients found"
        severity = data.get("severity", "mild")
        reaction = data.get("reaction")
        notes = data.get("notes")
        date_added = data.get("date_added")

        parsed_date = None

        if date_added:
            parsed_date = datetime.strptime(
                date_added,
                "%Y-%m-%d %H:%M:%S"
            )

        conn = connect_db()
        cur = conn.cursor()

        cur.execute("""
            INSERT INTO products (product_name, ingredients)
            VALUES (%s, %s)
            ON CONFLICT (product_name)
            DO UPDATE SET ingredients = EXCLUDED.ingredients
            RETURNING id;
        """, (product_name, ingredients))

        product_id = cur.fetchone()[0]

        conn.commit()

        cur.close()
        conn.close()

        result = create_allergy_entry(
            user_id=user_id,
            allergen_name=product_name,
            reaction=reaction,
            severity=severity,
            notes=notes,
            product_id=product_id,
            date_added=parsed_date
        )

        return jsonify(result), 201

    except Exception as e:
        return jsonify({
            "error": "Failed to save scanned product",
            "details": str(e)
        }), 500