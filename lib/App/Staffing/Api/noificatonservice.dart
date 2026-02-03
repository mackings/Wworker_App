import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';

class NotificationService {
    final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  NotificationService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("📤 [NOTIFICATION REQUEST] => ${options.method} ${options.uri}");
          if (options.data != null) {
            debugPrint("📦 [DATA] => ${options.data}");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            "✅ [NOTIFICATION RESPONSE] => ${response.statusCode} ${response.requestOptions.uri}",
          );
          debugPrint("📥 [RESPONSE DATA] => ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("❌ [NOTIFICATION ERROR] => ${e.requestOptions.uri}");
          debugPrint("📛 [MESSAGE] => ${e.message}");
          debugPrint("📛 [RESPONSE] => ${e.response?.data}");
          return handler.next(e);
        },
      ),
    );
  
    _dio.interceptors.add(ApiFeedbackInterceptor());
  }

  // 🟢 GET NOTIFICATIONS
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.get(
        "/api/notifications",
        queryParameters: {
          "page": page,
          "limit": limit,
          "unreadOnly": unreadOnly.toString(),
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 GET UNREAD COUNT
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.get(
        "/api/notifications/unread-count",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 MARK AS READ
  Future<Map<String, dynamic>> markAsRead({required String notificationId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.patch(
        "/api/notifications/$notificationId/read",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 MARK ALL AS READ
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.patch(
        "/api/notifications/read-all",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 DELETE NOTIFICATION
  Future<Map<String, dynamic>> deleteNotification({required String notificationId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.delete(
        "/api/notifications/$notificationId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🔴 ERROR HANDLER
  Map<String, dynamic> _handleError(DioException e) {
    debugPrint("⚠️ [NOTIFICATION ERROR] => ${e.response?.data ?? e.message}");

    if (e.response != null) {
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Request failed",
        "statusCode": e.response?.statusCode,
      };
    } else {
      return {
        "success": false,
        "message": e.message ?? "Network error occurred",
      };
    }
  }
}