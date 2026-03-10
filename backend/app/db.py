import os
import mysql.connector

def connect_db():

    # If running on Railway/Vercel (public DB)
    if os.getenv("MYSQL_PUBLIC_HOST"):
        return mysql.connector.connect(
            host=os.getenv("MYSQL_PUBLIC_HOST"),
            port=int(os.getenv("MYSQL_PUBLIC_PORT", "3306")),
            user=os.getenv("MYSQL_PUBLIC_USER"),
            password=os.getenv("MYSQL_PUBLIC_PASSWORD"),
            database=os.getenv("MYSQL_PUBLIC_DATABASE"),
        )

    # Otherwise assume local development
    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "localhost"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER"),
        password=os.getenv("MYSQL_PASSWORD"),
        database=os.getenv("MYSQL_DATABASE"),
    )