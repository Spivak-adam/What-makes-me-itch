from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from ..db import connect_db

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/signup", methods=["POST"])
def signup():
    data = request.json or {}
    name = data.get("name")
    username = data.get("username")
    email = data.get("email")
    password = data.get("password")

    if not name or not username or not email or not password:
        return jsonify({"error": "Missing required fields"}), 400

    conn = connect_db()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("SELECT id FROM users WHERE username = %s", (username,))
        if cursor.fetchone():
            return jsonify({"error": "Username already in use"}), 409

        cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cursor.fetchone():
            return jsonify({"error": "Email already in use"}), 409

        password_hash = generate_password_hash(password)

        cursor.execute(
            """
            INSERT INTO users (name, username, email, password_hash)
            VALUES (%s, %s, %s, %s)
            """,
            (name, username, email, password_hash),
        )

        conn.commit()
        user_id = cursor.lastrowid

        return jsonify({
            "message": "Account created successfully",
            "user_id": user_id
        }), 201

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500

    finally:
        cursor.close()
        conn.close()


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.json or {}
    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"error": "Missing username or password"}), 400

    conn = connect_db()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT id, username, password_hash FROM users WHERE username = %s",
            (username,),
        )
        user = cursor.fetchone()

        if not user or not check_password_hash(user["password_hash"], password):
            return jsonify({"error": "Invalid username or password"}), 401

        return jsonify({
            "message": "Login successful",
            "user_id": user["id"],
            "username": user["username"]
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        cursor.close()
        conn.close()