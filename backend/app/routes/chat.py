from flask import Blueprint, request, jsonify
from ..db import connect_db
from app.services.chat_ai_service import chat_with_ai

chat_bp = Blueprint("chat", __name__)

@chat_bp.route("/chat", methods=["POST"])
def chat_with_user():
    data = request.json or {}

    user_id = data.get("user_id")
    if not user_id:
        return jsonify({"error": "User not authenticated"}), 401

    user_message = data.get("message", "")
    new_chat = data.get("new_chat", False)

    if not user_message:
        return jsonify({"error": "Message cannot be empty"}), 400

    ai_response = chat_with_ai(user_id, user_message, new_chat)
    return jsonify({"response": ai_response}), 200


@chat_bp.route("/chat/edit", methods=["PUT"])
def edit_message():
    data = request.json or {}
    old_message = data.get("old_message")
    new_message = data.get("new_message")

    if not old_message or not new_message:
        return jsonify({"error": "Old message and new message are required"}), 400

    conn = connect_db()
    cursor = conn.cursor()

    query = """
        UPDATE chat_history
        SET message = %s
        WHERE message = %s
        ORDER BY timestamp DESC
        LIMIT 1
    """
    cursor.execute(query, (new_message, old_message))
    conn.commit()

    updated = cursor.rowcount > 0

    cursor.close()
    conn.close()

    if updated:
        return jsonify({"message": "Message updated successfully"}), 200
    return jsonify({"error": "Message not found"}), 404


@chat_bp.route("/chat/delete", methods=["DELETE"])
def delete_message():
    data = request.json or {}
    message_text = data.get("message_text")

    if not message_text:
        return jsonify({"error": "Message text is required"}), 400

    conn = connect_db()
    cursor = conn.cursor()

    try:
        cursor.execute(
            """
            SELECT session_id, id FROM chat_history
            WHERE message = %s AND role = 'user'
            ORDER BY timestamp ASC LIMIT 1
            """,
            (message_text,),
        )
        user_message = cursor.fetchone()

        if not user_message:
            return jsonify({"error": "User message not found"}), 404

        session_id, user_message_id = user_message

        cursor.execute("DELETE FROM chat_history WHERE id = %s", (user_message_id,))

        cursor.execute(
            """
            DELETE FROM chat_history
            WHERE role = 'assistant'
              AND session_id = %s
              AND id > %s
            ORDER BY id ASC LIMIT 1
            """,
            (session_id, user_message_id),
        )

        conn.commit()
        return jsonify({"status": "success"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500

    finally:
        cursor.close()
        conn.close()