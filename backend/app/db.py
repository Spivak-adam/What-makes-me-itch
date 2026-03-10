import os
import mysql.connector
from urllib.parse import urlparse

def connect_db():
    db_url = os.getenv("MYSQL_PUBLIC_URL")

    # Production (Railway / Vercel)
    if db_url:
        parsed = urlparse(db_url)

        return mysql.connector.connect(
            host=parsed.hostname,
            port=parsed.port,
            user=parsed.username,
            password=parsed.password,
            database=parsed.path.lstrip("/")
        )

    # Local development
    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "localhost"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER"),
        password=os.getenv("MYSQL_PASSWORD"),
        database=os.getenv("MYSQL_DATABASE"),
    )