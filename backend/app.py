import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

import mysql.connector
from chat_ai import chat_with_ai

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


@app.route("/chat", methods=["POST"])
def chat_with_user():
    data = request.json
    user_id = data.get("user_id", "1")  # Default to "1" for testing
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




if __name__ == "__main__":
    app.run(debug=True, port=5000)