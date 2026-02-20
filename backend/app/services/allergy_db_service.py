from app.db import connect_db

def get_allergy_history(user_id: int) -> str:
    """Retrieve a user's past allergens from the allergies table (via products)."""
    conn = connect_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        """
        SELECT DISTINCT p.ingredients
        FROM products p
        JOIN allergies a ON p.id = a.product_id
        WHERE a.user_id = %s;
        """,
        (user_id,),
    )
    past_allergens = [row["ingredients"] for row in cursor.fetchall()]
    cursor.close()
    conn.close()

    if past_allergens:
        return f"The user has reported issues with: {', '.join(past_allergens)}."
    return "No known allergens recorded yet."


def save_product_to_db(product_name: str, ingredients: str) -> int:
    conn = connect_db()
    cursor = conn.cursor()

    # Check if product exists
    cursor.execute("SELECT id FROM products WHERE product_name = %s", (product_name,))
    existing = cursor.fetchone()
    if existing:
        product_id = existing[0]
        cursor.close()
        conn.close()
        return product_id

    cursor.execute(
        """
        INSERT INTO products (product_name, ingredients)
        VALUES (%s, %s)
        """,
        (product_name, ingredients),
    )
    product_id = cursor.lastrowid
    conn.commit()
    cursor.close()
    conn.close()
    return product_id


def save_allergy_to_db(
    user_id: int,
    allergen_name: str,
    severity: str,
    reaction: str,
    location: str,
    product_id=None,
) -> None:
    conn = connect_db()
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO allergies (user_id, allergen_name, severity, reaction, location, product_id)
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        (user_id, allergen_name, severity, reaction, location, product_id),
    )
    conn.commit()
    cursor.close()
    conn.close()


def is_known_allergen(user_id: int, ingredient: str) -> bool:
    conn = connect_db()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT COUNT(*) FROM allergies WHERE user_id = %s AND allergen_name = %s",
        (user_id, ingredient),
    )
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return (result[0] if result else 0) > 0