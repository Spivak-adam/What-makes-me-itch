import os
from openai import OpenAI
from dotenv import load_dotenv
import mysql.connector

load_dotenv()

# Connect to MySQL
def connect_db():
    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST"),  
        user=os.getenv("MYSQL_USER"),  
        password=os.getenv("MYSQL_PASSWORD"),  
        database=os.getenv("MYSQL_DATABASE")  
    )

# Create a new chat session
def create_new_chat_session(user_id):
    conn = connect_db()
    cursor = conn.cursor()
    query = "INSERT INTO chat_sessions (user_id) VALUES (%s)"
    cursor.execute(query, (user_id,))
    session_id = cursor.lastrowid  # Get the new session ID
    conn.commit()
    conn.close()
    return session_id

# Save chat message in MySQL
def save_chat_to_db(session_id, user_id, role, message):
    conn = connect_db()
    cursor = conn.cursor()
    query = "INSERT INTO chat_history (session_id, user_id, role, message) VALUES (%s, %s, %s, %s)"
    cursor.execute(query, (session_id, user_id, role, message))
    conn.commit()
    conn.close()

# Retrieve the latest active chat session for the user
def get_latest_session_id(user_id):
    conn = connect_db()
    cursor = conn.cursor()
    query = "SELECT session_id FROM chat_sessions WHERE user_id = %s ORDER BY start_time DESC LIMIT 1"
    cursor.execute(query, (user_id,))
    session = cursor.fetchone()
    conn.close()
    return session[0] if session else None

# Retrieve chat history for the current session
def get_chat_history(session_id, limit=10):
    conn = connect_db()
    cursor = conn.cursor(dictionary=True)
    query = "SELECT role, message FROM chat_history WHERE session_id = %s ORDER BY timestamp ASC LIMIT %s"
    cursor.execute(query, (session_id, limit))
    chat = [{"role": row["role"], "content": row["message"]} for row in cursor.fetchall()]
    conn.close()
    return chat

# Retrieve past allergy-related history (not chat history)
def get_allergy_history(user_id):
    conn = connect_db()
    cursor = conn.cursor(dictionary=True)
    query = """
        SELECT DISTINCT ingredients FROM allergies 
        WHERE user_id = %s
    """
    cursor.execute(query, (user_id,))
    past_allergens = [row["trigger"] for row in cursor.fetchall()]
    conn.close()

    if past_allergens:
        return f"The user has reported issues with: {', '.join(past_allergens)}."
    return "No known allergens recorded yet."


# AI Chat Function (With Context for Each Session)
def chat_with_ai(user_id, user_input, new_chat=False):
    client = OpenAI(
        api_key=os.getenv("OPENAI_API_KEY")  # Ensure your API key is set
    )

    # Start a new chat session if requested
    if new_chat:
        session_id = create_new_chat_session(user_id)
    else:
        session_id = get_latest_session_id(user_id)
        if session_id is None:  # If no active session, start a new one
            session_id = create_new_chat_session(user_id)

    # Retrieve chat history for this session (only last 10 messages)
    chat_history = get_chat_history(session_id)

    # Retrieve past allergy data (for AI context)
    allergy_context = get_allergy_history(user_id)

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": (
                "You are an intelligent allergy-tracking assistant. Your job is to:"
                "\n1️⃣ **Track allergy symptoms** (Ask users about symptoms, severity, and time of occurrence)."
                "\n2️⃣ **Identify possible triggers** (Ask users what they ate, touched, or were exposed to)."
                "\n3️⃣ **Analyze ingredients** (Compare with past allergy records to highlight new triggers)."
                "\n4️⃣ **Log data** (Save allergy reports in a database)."
                "\n5️⃣ **Provide AI-powered recommendations** (Suggest possible allergens if confidence >80%)."
                "\n6️⃣ **Allow modification of allergy records** (Users can edit, confirm, or delete entries)."
                "\n7️⃣ **Send reminders** (Prompt users to log symptoms if they haven't in a while)."
                "\n💡 You are NOT a doctor but can help users track their symptoms and suggest common allergens."
                "Do not number steps or have ** in your messages. Keep it one step at a time."
                
            )},
            {"role": "system", "content": allergy_context} ] + 
            chat_history + [{"role": "user", "content": user_input}]
        
    )

    
    ai_response = response.choices[0].message.content

    # Save chat messages to the session
    save_chat_to_db(session_id, user_id, "user", user_input)
    save_chat_to_db(session_id, user_id, "assistant", ai_response)

    return ai_response