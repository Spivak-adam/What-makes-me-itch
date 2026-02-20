from flask import Blueprint, request, jsonify
from ..db import connect_db

users_bp = Blueprint("users", __name__)

@users_bp.route("/user/<int:user_id>", methods=["GET"])
def get_user_data(user_id):
    conn = connect_db()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT username, email FROM users WHERE id = %s", (user_id,))
    user = cursor.fetchone()

    if not user:
        cursor.close()
        conn.close()
        return jsonify({"error": "User not found"}), 404

    cursor.execute(
        """
        SELECT allergen_name, severity
        FROM allergies
        WHERE user_id = %s
        ORDER BY FIELD(severity, 'severe', 'moderate', 'mild')
        """,
        (user_id,),
    )
    allergies = cursor.fetchall()

    cursor.close()
    conn.close()

    return jsonify({
        "username": user["username"],
        "email": user["email"],
        "allergies": allergies
    }), 200


@users_bp.route("/update_user/<int:user_id>", methods=["PUT"])
def update_user(user_id):
    data = request.json or {}
    username = data.get("username")
    email = data.get("email")

    if not username or not email:
        return jsonify({"error": "Missing username or email"}), 400

    conn = connect_db()
    cursor = conn.cursor()

    try:
        cursor.execute(
            "UPDATE users SET username = %s, email = %s WHERE id = %s",
            (username, email, user_id),
        )
        conn.commit()
        return jsonify({"message": "User updated successfully"}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


@users_bp.route("/delete_allergy", methods=["DELETE"])
def delete_allergy():
    data = request.get_json() or {}
    user_id = data.get("user_id")
    allergen_name = data.get("allergen_name")

    if not user_id or not allergen_name:
        return jsonify({"error": "Missing user_id or allergen_name"}), 400

    conn = connect_db()
    cursor = conn.cursor()

    try:
        cursor.execute(
            "DELETE FROM allergies WHERE user_id = %s AND allergen_name = %s",
            (user_id, allergen_name),
        )
        conn.commit()

        if cursor.rowcount == 0:
            return jsonify({"error": "Allergen not found"}), 404

        return jsonify({"message": "Allergen deleted successfully"}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()