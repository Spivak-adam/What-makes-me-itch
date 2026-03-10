from flask import Blueprint, jsonify
from app.services.analytics_service import get_user_analytics_data

analytics_bp = Blueprint("analytics", __name__)


@analytics_bp.route("/api/analytics/<int:user_id>", methods=["GET"])
def get_analytics(user_id):
    try:
        analytics_data = get_user_analytics_data(user_id)
        return jsonify(analytics_data), 200

    except Exception as e:
        return jsonify({
            "error": "Failed to fetch analytics",
            "details": str(e)
        }), 500


@analytics_bp.route("/api/analytics/health", methods=["GET"])
def analytics_health():
    return jsonify({
        "status": "ok",
        "service": "analytics"
    }), 200