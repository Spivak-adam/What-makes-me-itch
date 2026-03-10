import 'package:flutter/foundation.dart';

class ApiConfig {
  // Local backend
  static const String localBaseUrl = "http://127.0.0.1:5000";

  // Production backend (change this)
  static const String prodBaseUrl = "https://api.what-makes-me-itch.vercel.app";

  static String get baseUrl {
    if (kReleaseMode) {
      return prodBaseUrl;
    } else {
      return localBaseUrl;
    }
  }
}