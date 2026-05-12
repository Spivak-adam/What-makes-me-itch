from flask import Blueprint, jsonify
from ..db import connect_db

analytics_bp = Blueprint("analytics", __name__)

@analytics_bp.route("/analytics/<int:user_id>", methods=["GET"])
def get_analytics(user_id):
    conn = connect_db()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT allergen_name, severity, date_added
            FROM allergies
            WHERE user_id = %s
            ORDER BY date_added DESC
            """,
            (user_id,),
        )
        allergies = cursor.fetchall()

        total = len(allergies)
        severe = sum(1 for a in allergies if a["severity"] == "severe")
        moderate = sum(1 for a in allergies if a["severity"] == "moderate")
        mild = sum(1 for a in allergies if a["severity"] == "mild")

        most_common_trigger = "None yet"
        if allergies:
            counts = {}
            for a in allergies:
                name = a["allergen_name"]
                counts[name] = counts.get(name, 0) + 1
            most_common_trigger = max(counts, key=counts.get)

        return jsonify({
            "total_entries": total,
            "severe_count": severe,
            "moderate_count": moderate,
            "mild_count": mild,
            "most_common_trigger": most_common_trigger,
            "recent_allergies": allergies[:5],
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        cursor.close()
        conn.close()
