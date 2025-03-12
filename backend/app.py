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

if __name__ == "__main__":
    app.run(debug=True, port=5000)