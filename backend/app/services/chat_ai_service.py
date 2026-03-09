import os
import re
from openai import OpenAI

from app.services.ai_prompt import SYSTEM_PROMPT
from app.services.chat_db_service import (
    create_new_chat_session,
    get_latest_session_id,
    get_chat_history,
    save_chat_to_db,
)
from app.services.allergy_db_service import (
    get_allergy_history,
    save_product_to_db,
    save_allergy_to_db,
)

def extract_product_and_ingredients(ai_response: str):
    """
    Extract product names, ingredients, severity level, reaction type, and location from AI responses using regex.
    Expected format:
      Product: <name>, Ingredients: <list>, Severity: <severity>. Reaction: <reaction>. Location: <location>
    """
    product_name = None
    ingredients = None
    severity = None
    reaction = None
    location = None

    product_pattern = r"Product:\s*([\w\s]+)"
    match = re.search(product_pattern, ai_response, re.IGNORECASE)
    if match:
        product_name = match.group(1).strip()

    ingredient_pattern = r"Ingredients:\s*([\w\s,]+)"
    match = re.search(ingredient_pattern, ai_response, re.IGNORECASE)
    if match:
        ingredients = match.group(1).strip()

    severity_pattern = r"Severity:\s*(mild|moderate|severe)"
    match = re.search(severity_pattern, ai_response, re.IGNORECASE)
    if match:
        severity = match.group(1).strip().lower()

    reaction_pattern = r"Reaction:\s*([\w\s]+)"
    match = re.search(reaction_pattern, ai_response, re.IGNORECASE)
    if match:
        reaction = match.group(1).strip()

    location_pattern = r"Location:\s*([\w\s]+)"
    match = re.search(location_pattern, ai_response, re.IGNORECASE)
    if match:
        location = match.group(1).strip()

    return product_name, ingredients, severity, reaction, location


def chat_with_ai(user_id: int, user_input: str, new_chat: bool = False) -> str:
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

    # Session handling
    if new_chat:
        session_id = create_new_chat_session(user_id)
    else:
        session_id = get_latest_session_id(user_id)
        if session_id is None:
            session_id = create_new_chat_session(user_id)

    chat_history = get_chat_history(session_id, limit=10)
    allergy_context = get_allergy_history(user_id)

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "system", "content": allergy_context},
            *chat_history,
            {"role": "user", "content": user_input},
        ],
    )

    ai_response = response.choices[0].message.content or ""

    # Parse + save extracted data
    product_name, ingredients, severity, reaction, location = extract_product_and_ingredients(ai_response)

    if product_name and ingredients:
        product_id = save_product_to_db(product_name, ingredients)
        if severity and reaction:
            # using product_name as allergen_name (same as your current behavior)
            save_allergy_to_db(user_id, product_name, severity, reaction, location or "", product_id)

    # Save messages
    save_chat_to_db(session_id, user_id, "user", user_input)
    save_chat_to_db(session_id, user_id, "assistant", ai_response)

    return ai_response