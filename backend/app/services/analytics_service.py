from collections import defaultdict
from datetime import datetime, timedelta
from app.db import connect_db


def get_time_bucket(dt_value):
    if dt_value is None:
        return "Unknown"

    hour = dt_value.hour

    if 5 <= hour < 12:
        return "Morning"
    elif 12 <= hour < 17:
        return "Afternoon"
    elif 17 <= hour < 21:
        return "Evenings"
    else:
        return "Night"


def build_empty_7_day_trend():
    today = datetime.now().date()
    trend = []

    for i in range(6, -1, -1):
        current_day = today - timedelta(days=i)
        trend.append({
            "day": current_day.strftime("%a"),
            "count": 0
        })

    return trend


def get_user_analytics_data(user_id):
    conn = None
    cursor = None

    try:
        conn = connect_db()
        cursor = conn.cursor(dictionary=True)

        # Weekly reaction count
        weekly_query = """
            SELECT COUNT(*) AS weekly_count
            FROM allergies
            WHERE user_id = %s
              AND date_added >= NOW() - INTERVAL 7 DAY
        """
        cursor.execute(weekly_query, (user_id,))
        weekly_result = cursor.fetchone()
        weekly_count = weekly_result["weekly_count"] if weekly_result else 0

        # 7-day trend
        trend_query = """
            SELECT DATE(date_added) AS entry_date, COUNT(*) AS total
            FROM allergies
            WHERE user_id = %s
              AND date_added >= CURDATE() - INTERVAL 6 DAY
            GROUP BY DATE(date_added)
            ORDER BY entry_date ASC
        """
        cursor.execute(trend_query, (user_id,))
        trend_rows = cursor.fetchall()

        trend_map = {}
        for row in trend_rows:
            trend_map[row["entry_date"]] = row["total"]

        trend_data = build_empty_7_day_trend()
        today = datetime.now().date()

        for i in range(6, -1, -1):
            current_day = today - timedelta(days=i)
            index = 6 - i
            trend_data[index]["count"] = trend_map.get(current_day, 0)

        # Most common trigger
        trigger_query = """
            SELECT allergen_name, COUNT(*) AS total
            FROM allergies
            WHERE user_id = %s
              AND allergen_name IS NOT NULL
              AND allergen_name <> ''
            GROUP BY allergen_name
            ORDER BY total DESC, allergen_name ASC
            LIMIT 1
        """
        cursor.execute(trigger_query, (user_id,))
        trigger_result = cursor.fetchone()
        most_common_trigger = (
            trigger_result["allergen_name"] if trigger_result else "N/A"
        )

        # Most frequent symptom
        symptom_query = """
            SELECT reaction, COUNT(*) AS total
            FROM allergies
            WHERE user_id = %s
              AND reaction IS NOT NULL
              AND reaction <> ''
            GROUP BY reaction
            ORDER BY total DESC, reaction ASC
            LIMIT 1
        """
        cursor.execute(symptom_query, (user_id,))
        symptom_result = cursor.fetchone()
        most_frequent_symptom = (
            symptom_result["reaction"] if symptom_result else "N/A"
        )

        # Total entries logged
        total_entries_query = """
            SELECT COUNT(*) AS total_entries
            FROM allergies
            WHERE user_id = %s
        """
        cursor.execute(total_entries_query, (user_id,))
        total_entries_result = cursor.fetchone()
        total_entries = (
            total_entries_result["total_entries"] if total_entries_result else 0
        )

        # Peak reaction time
        peak_time_query = """
            SELECT date_added
            FROM allergies
            WHERE user_id = %s
              AND date_added IS NOT NULL
        """
        cursor.execute(peak_time_query, (user_id,))
        time_rows = cursor.fetchall()

        bucket_counts = defaultdict(int)

        for row in time_rows:
            bucket = get_time_bucket(row["date_added"])
            bucket_counts[bucket] += 1

        peak_reaction_time = "N/A"
        if bucket_counts:
            peak_reaction_time = max(bucket_counts, key=bucket_counts.get)

        return {
            "weeklySummary": {
                "title": "This Week",
                "reactionCount": weekly_count
            },
            "reactionTrend": trend_data,
            "insights": {
                "mostCommonTrigger": most_common_trigger,
                "mostFrequentSymptom": most_frequent_symptom,
                "entriesLogged": total_entries,
                "peakReactionTime": peak_reaction_time
            }
        }

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()