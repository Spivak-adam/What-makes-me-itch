from flask import Blueprint, request, jsonify
from ..db import connect_db

users_bp = Blueprint("users", __name__)


@users_bp.route("/user/<int:user_id>", methods=["GET"])
def get_user_data(user_id):
    conn = connect_db()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT name, username, email FROM users WHERE id = %s",
            (user_id,),
        )
        user = cursor.fetchone()

        if not user:
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

        return jsonify({
            "name": user["name"],
            "username": user["username"],
            "email": user["email"],
            "allergies": allergies
        }), 200

    finally:
        cursor.close()
        conn.close()


@users_bp.route("/update_user/<int:user_id>", methods=["PUT"])
def update_user(user_id):
    data = request.json or {}
    name = data.get("name")
    username = data.get("username")
    email = data.get("email")

    if not name or not username or not email:
        return jsonify({"error": "Missing name, username, or email"}), 400

    conn = connect_db()
    cursor = conn.cursor()

    try:
        cursor.execute(
            "UPDATE users SET name = %s, username = %s, email = %s WHERE id = %s",
            (name, username, email, user_id),
        )
        conn.commit()

        return jsonify({"message": "User updated successfully"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500

    finally:
        cursor.close()
        conn.close()

@users_bp.route("/add_allergy", methods=["POST"])
def add_allergy():
    data = request.get_json() or {}
    user_id = data.get("user_id")
    allergen_name = data.get("allergen_name")
    severity = data.get("severity", "mild")

    if not user_id or not allergen_name:
        return jsonify({"error": "Missing user_id or allergen_name"}), 400

    conn = connect_db()
    cursor = conn.cursor()

    try:
        cursor.execute(
            """
            INSERT INTO allergies (user_id, allergen_name, severity)
            VALUES (%s, %s, %s)
            """,
            (user_id, allergen_name, severity),
        )
        conn.commit()

        return jsonify({"message": "Allergy added successfully"}), 201

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


    