import os
import mysql.connector, re

from openai import OpenAI
from dotenv import load_dotenv

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
    """Retrieve a user's past allergens from the allergies table."""
    conn = connect_db()
    cursor = conn.cursor(dictionary=True)
    query = """
        SELECT DISTINCT p.ingredients 
        FROM products p
        JOIN allergies a on p.id = a.product_id
        WHERE a.user_id = %s;
    """
    cursor.execute(query, (user_id,))
    past_allergens = [row["ingredients"] for row in cursor.fetchall()]
    conn.close()

    if past_allergens:
        return f"The user has reported issues with: {', '.join(past_allergens)}."
    return "No known allergens recorded yet."

def extract_product_and_ingredients(ai_response):
    """
    Extracts product names, ingredients, severity level, reaction type, and location from AI responses using regex.
    """
    product_name = None
    ingredients = None
    severity = None
    reaction = None
    location = None

    # Extracting product name
    product_pattern = r"Product:\s*([\w\s]+)"
    match = re.search(product_pattern, ai_response, re.IGNORECASE)
    if match:
        product_name = match.group(1).strip()

    # Extracting ingredients
    ingredient_pattern = r"Ingredients:\s*([\w\s,]+)"
    match = re.search(ingredient_pattern, ai_response, re.IGNORECASE)
    if match:
        ingredients = match.group(1).strip()

    # Extracting severity level
    severity_pattern = r"Severity:\s*(mild|moderate|severe)"
    match = re.search(severity_pattern, ai_response, re.IGNORECASE)
    if match:
        severity = match.group(1).strip()

    # Extracting reaction type
    reaction_pattern = r"Reaction:\s*([\w\s]+)"
    match = re.search(reaction_pattern, ai_response, re.IGNORECASE)
    if match:
        reaction = match.group(1).strip()

    # Extracting reaction location
    location_pattern = r"Location:\s*([\w\s]+)"
    match = re.search(location_pattern, ai_response, re.IGNORECASE)
    if match:
        location = match.group(1).strip()

    print(f"Extracted Data: Product={product_name}, Ingredients={ingredients}, Severity={severity}, Reaction={reaction}, Location={location}")

    return product_name, ingredients, severity, reaction, location

def save_product_to_db(product_name, ingredients):
    """
    Save detected products and ingredients to the database.
    """
    conn = connect_db()
    cursor = conn.cursor()

    print(f"Saving product to DB: product={product_name}, ingredients={ingredients}")

    # Check if product already exists
    query_check = "SELECT id FROM products WHERE product_name = %s"
    cursor.execute(query_check, (product_name,))
    existing_product = cursor.fetchone()

    if existing_product:
        print(f"Product already exists: ID {existing_product[0]}")
        conn.close()
        return existing_product[0]

    # Insert new product
    query_insert = """
        INSERT INTO products (product_name, ingredients)
        VALUES (%s, %s)
    """
    cursor.execute(query_insert, (product_name, ingredients))
    product_id = cursor.lastrowid  # Get new product ID

    conn.commit()
    print(f"Product saved with ID {product_id}")
    conn.close()
    
    return product_id

def save_allergy_to_db(user_id, allergen_name, severity, reaction, location, product_id=None):
    """
    Save an allergen to the allergies table, linking it to a product if applicable.
    """
    conn = connect_db()
    cursor = conn.cursor()

    print(f"Saving allergy: user={user_id}, allergen={allergen_name}, severity={severity}, reaction={reaction}, location={location}, product_id={product_id}")

    query = """
        INSERT INTO allergies (user_id, allergen_name, severity, reaction, location, product_id)
        VALUES (%s, %s, %s, %s, %s, %s)
    """
    cursor.execute(query, (user_id, allergen_name, severity, reaction, location, product_id))
    conn.commit()
    conn.close()

def is_known_allergen(ingredient, user_id):
    """
    Check if an ingredient is a known allergen for the user.
    """
    conn = connect_db()
    cursor = conn.cursor()
    
    query = "SELECT COUNT(*) FROM allergies WHERE user_id = %s AND allergen_name = %s"
    cursor.execute(query, (user_id, ingredient))
    result = cursor.fetchone()
    
    conn.close()
    return result[0] > 0  # Returns True if ingredient is a known allergen


# AI Chat Function (With Context for Each Session)
def chat_with_ai(user_id, user_input, new_chat=False):
    client = OpenAI(
        api_key=os.getenv("OPENAI_API_KEY")
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
                "You are an intelligent allergy-tracking assistant. Your job is to help users track allergies and symptoms."
                "\nWhen interacting, follow these key steps:"
    
                "\n\n **Identify Allergens & Triggers**"
                "\n- Ask users what they ate, touched, or were exposed to before symptoms occurred."
                "\n- Identify products and their ingredients if mentioned."
                "\n- Store detected ingredients in this format: 'Product: <name>. Ingredients: <list>'."

                "\n\n **Log Symptoms**"
                "\n- Ask for the type of reaction (e.g., itching, swelling, breathing difficulty)."
                "\n- Ask where on the body the reaction occurred."
                "\n- Ask for severity: mild, moderate, or severe."
                "\n- Log severity and reaction using this format: 'Product: <product>, Ingredients: <ingredients>, Severity: <severity>. Reaction: <reaction>. Location: <location>'."

                "\n\n **Analyze Ingredients & Provide Insights**"
                "\n- Compare detected ingredients with the user's past allergy records."
                "\n- Highlight new potential allergens."
                "\n- If confidence is above 80%, suggest possible allergens."

                "\n\n **User Control & Reminders**"
                "\n- Allow users to edit, confirm, or delete allergy records."
                "\n- Prompt users to log symptoms if they haven’t in a while."

                "\n\n **Reminder:**"
                "\n- You are NOT a doctor but can help users track their symptoms and suggest common allergens."
                "\n- Keep responses natural, asking only one relevant question at a time."
                "\n- Users cannot delete their allergies form the chat, they must do it from the profile page."
                "Don't use ** in any of the chats"

            )},
            {"role": "system", "content": allergy_context} ] + 
            chat_history + [{"role": "user", "content": user_input}]
        
    )

    ai_response = response.choices[0].message.content

    # Check if the AI response contains product & ingredient information
    product_name, ingredients, severity, reaction, location = extract_product_and_ingredients(ai_response)

    if product_name and ingredients:
        product_id = save_product_to_db(product_name, ingredients)

        if severity and reaction:
            save_allergy_to_db(user_id, product_name, severity, reaction, location, product_id)

    # Save chat messages to the session
    save_chat_to_db(session_id, user_id, "user", user_input)
    save_chat_to_db(session_id, user_id, "assistant", ai_response)

    return ai_response