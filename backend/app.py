import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

import mysql.connector
from chat_ai import chat_with_ai

#for password management
from werkzeug.security import generate_password_hash, check_password_hash


load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app communication

# Connect to MySQL
def connect_db():
    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST"),  
        user=os.getenv("MYSQL_USER"),  
        password=os.getenv("MYSQL_PASSWORD"),  
        database=os.getenv("MYSQL_DATABASE")  
    )

conn = connect_db()
cursor = conn.cursor(dictionary=True)

@app.route("/", methods=["GET"])
def chat():
    test = "True" if cursor else "False"

    return f"Hello, this endpoint is working! Connected to database is {test}!"

#endpoint for signing up
@app.route("/signup", methods=["POST"])
def signup():
    data = request.json
    username = data.get("name")
    email = data.get("email")
    password = data.get("password")

    if not username or not email or not password:
        return jsonify({"error": "Missing required fields"}), 400

    conn = connect_db()
    cursor = conn.cursor(dictionary=True)

    # Check if email already exists
    cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
    if cursor.fetchone():
        conn.close()
        return jsonify({"error": "Email already in use"}), 409

    password_hash = generate_password_hash(password)

    cursor.execute(
        """
        INSERT INTO users (username, email, password_hash)
        VALUES (%s, %s, %s)
        """,
        (username, email, password_hash)
    )

    conn.commit()

    user_id = cursor.lastrowid
    conn.close()

    return jsonify({
        "message": "Account created successfully",
        "user_id": user_id
    }), 201


#endpoint for logging in
@app.route("/login", methods=["POST"])
def login():
    data = request.json
    email = data.get("email")
    password = data.get("password")

    if not email or not password:
        return jsonify({"error": "Missing email or password"}), 400

    conn = connect_db()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "SELECT id, password_hash FROM users WHERE email = %s",
        (email,)
    )
    user = cursor.fetchone()
    conn.close()

    if not user or not check_password_hash(user["password_hash"], password):
        return jsonify({"error": "Invalid email or password"}), 401

    return jsonify({
        "message": "Login successful",
        "user_id": user["id"]
    }), 200



@app.route("/chat", methods=["POST"])
def chat_with_user():
    data = request.json

    # added a real user tracker instead of defaulting to 1 for testing
    user_id = data.get("user_id")
    if not user_id:
        return jsonify({"error": "User not authenticated"}), 401


    user_message = data.get("message", "")
    new_chat = data.get("new_chat", False)  # Determine if a new chat should start

    if not user_message:
        return jsonify({"error": "Message cannot be empty"}), 400

    # Call the AI function and pass session details
    ai_response = chat_with_ai(user_id, user_message, new_chat)

    return jsonify({"response": ai_response})

@app.route("/chat/edit", methods=["PUT"])
def edit_message():
    data = request.json
    old_message = data.get("old_message")
    new_message = data.get("new_message")

    if not old_message or not new_message:
        return jsonify({"error": "Old message and new message are required"}), 400

    conn = connect_db()
    cursor = conn.cursor()

    # Update message where the old message text matches
    query = "UPDATE chat_history SET message = %s WHERE message = %s ORDER BY timestamp DESC LIMIT 1"
    cursor.execute(query, (new_message, old_message))
    conn.commit()
    conn.close()

    if cursor.rowcount > 0:
        return jsonify({"message": "Message updated successfully"}), 200
    else:
        return jsonify({"error": "Message not found"}), 404



@app.route("/chat/delete", methods=["DELETE"])
def delete_message():
    data = request.json
    message_text = data.get("message_text")

    if not message_text:
        return jsonify({"error": "Message text is required"}), 400

    conn = connect_db()
    cursor = conn.cursor()

    try:
        # Get the session_id of the message being deleted
        cursor.execute("""
            SELECT session_id, id FROM chat_history 
            WHERE message = %s AND role = 'user'
            ORDER BY timestamp ASC LIMIT 1
        """, (message_text,))
        
        user_message = cursor.fetchone()

        if not user_message:
            return jsonify({"error": "User message not found"}), 404

        session_id, user_message_id = user_message

        # Delete the user message first
        cursor.execute("DELETE FROM chat_history WHERE id = %s", (user_message_id,))

        # Find and delete the assistant's response that follows this message
        cursor.execute("""
            DELETE FROM chat_history 
            WHERE role = 'assistant' 
            AND session_id = %s 
            AND id > %s
            ORDER BY id ASC LIMIT 1
        """, (session_id, user_message_id))

        conn.commit()
        return jsonify({"status": "success"}), 200

    except Exception as e:
        conn.rollback()
        print(f"Error deleting message: {str(e)}")  # Debugging
        return jsonify({"error": str(e)}), 500

    finally:
        cursor.close()
        conn.close()

@app.route('/user/<int:user_id>', methods=['GET'])
def get_user_data(user_id):
    conn = connect_db()
    cursor = conn.cursor(dictionary=True)

    # Get user profile
    cursor.execute("SELECT username, email FROM users WHERE id = %s", (user_id,))
    user = cursor.fetchone()

    if not user:
        conn.close()
        return jsonify({"error": "User not found"}), 404

    # Get user allergies
    severity_order = {"severe": 1, "moderate": 2, "mild": 3}  # Define order manually
    cursor.execute("""
        SELECT allergen_name, severity 
        FROM allergies 
        WHERE user_id = %s 
        ORDER BY FIELD(severity, 'severe', 'moderate', 'mild')
    """, (user_id,))

    allergies = cursor.fetchall()
    conn.close()
    
    print(allergies)

    return jsonify({
        "username": user["username"],
        "email": user["email"],
        "allergies": allergies
    })

@app.route('/update_user/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    data = request.json
    username = data.get('username')
    email = data.get('email')

    if not username or not email:
        return jsonify({"error": "Missing username or email"}), 400

    conn = connect_db()
    cursor = conn.cursor()
    
    try:
        cursor.execute(
            "UPDATE users SET username = %s, email = %s WHERE id = %s",
            (username, email, user_id)
        )
        conn.commit()
        conn.close()
        return jsonify({"message": "User updated successfully"})
    except Exception as e:
        conn.rollback()
        conn.close()
        return jsonify({"error": str(e)}), 500


@app.route('/delete_allergy', methods=['DELETE'])
def delete_allergy():
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        allergen_name = data.get('allergen_name')

        if not user_id or not allergen_name:
            return jsonify({"error": "Missing user_id or allergen_name"}), 400

        
        conn = connect_db()
        cursor = conn.cursor()

        cursor.execute("DELETE FROM allergies WHERE user_id = %s AND allergen_name = %s", (user_id, allergen_name))
        conn.commit()

        conn.close()

        if cursor.rowcount == 0:
            return jsonify({"error": "Allergen not found"}), 404

        return jsonify({"message": "Allergen deleted successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True, port=5000)