from app.db import connect_db

def create_new_chat_session(user_id: int) -> int:
    conn = connect_db()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO chat_sessions (user_id) VALUES (%s)", (user_id,))
    session_id = cursor.lastrowid
    conn.commit()
    cursor.close()
    conn.close()
    return session_id


def save_chat_to_db(session_id: int, user_id: int, role: str, message: str) -> None:
    conn = connect_db()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO chat_history (session_id, user_id, role, message) VALUES (%s, %s, %s, %s)",
        (session_id, user_id, role, message),
    )
    conn.commit()
    cursor.close()
    conn.close()


def get_latest_session_id(user_id: int):
    conn = connect_db()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT session_id FROM chat_sessions WHERE user_id = %s ORDER BY start_time DESC LIMIT 1",
        (user_id,),
    )
    session = cursor.fetchone()
    cursor.close()
    conn.close()
    return session[0] if session else None


def get_chat_history(session_id: int, limit: int = 10):
    conn = connect_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        "SELECT role, message FROM chat_history WHERE session_id = %s ORDER BY timestamp ASC LIMIT %s",
        (session_id, limit),
    )
    chat = [{"role": row["role"], "content": row["message"]} for row in cursor.fetchall()]
    cursor.close()
    conn.close()
    return chat