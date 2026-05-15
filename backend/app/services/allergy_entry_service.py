from datetime import datetime
from app.db import connect_db


def create_allergy_entry(user_id, allergen_name, reaction, severity, notes=None, date_added=None):
    conn = None
    cursor = None

    try:
        conn = connect_db()
        cursor = conn.cursor(dictionary=True)
        
        location_value = notes if notes and notes.strip() else None

        if date_added:
            insert_query = """
                INSERT INTO allergies (
                    user_id,
                    allergen_name,
                    reaction,
                    severity,
                    location,
                    product_id,
                    date_added
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            values = (
                user_id,
                allergen_name,
                reaction,
                severity,
                location_value,
                None,
                date_added
            )
        else:
            insert_query = """
                INSERT INTO allergies (
                    user_id,
                    allergen_name,
                    severity,
                    reaction,
                    location,
                    product_id
                )
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            values = (
                user_id,
                allergen_name,
                reaction,
                severity,
                location_value,
                None
            )

        cursor.execute(insert_query, values)
        conn.commit()

        return {
            "success": True,
            "message": "Entry saved successfully",
            "entry_id": cursor.lastrowid
        }

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()