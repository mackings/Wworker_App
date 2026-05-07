import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Auth/Api/AuthService.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';

class CompanyService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  CompanyService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint(
            "📤 [COMPANY REQUEST] => ${options.method} ${options.uri}",
          );
          if (options.data != null) {
            debugPrint("📦 [DATA] => ${options.data}");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            "✅ [COMPANY RESPONSE] => ${response.statusCode} ${response.requestOptions.uri}",
          );
          debugPrint("📥 [RESPONSE DATA] => ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("❌ [COMPANY ERROR] => ${e.requestOptions.uri}");
          debugPrint("📛 [MESSAGE] => ${e.message}");
          debugPrint("📛 [RESPONSE] => ${e.response?.data}");
          return handler.next(e);
        },
      ),
    );

    _dio.interceptors.add(RetryTwiceInterceptor(_dio));
    _dio.interceptors.add(ApiFeedbackInterceptor());
  }

  // 🟢 CREATE COMPANY
  Future<Map<String, dynamic>> createCompany({
    required String companyName,
    String? companyEmail,
    String? companyPhone,
    String? companyAddress,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.post(
        "/api/auth/company",
        data: {
          "companyName": companyName,
          if (companyEmail != null) "companyEmail": companyEmail,
          if (companyPhone != null) "companyPhone": companyPhone,
          if (companyAddress != null) "companyAddress": companyAddress,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final data = response.data;

      if (data["success"] == true) {
        // Refresh user data to get updated companies list
        final authService = AuthService();
        final user = await authService.getMe();
        if (user["success"] == true && user["data"]["companies"] != null) {
          await prefs.setString(
            "companies",
            jsonEncode(user["data"]["companies"]),
          );
          if (user["data"]["activeCompany"] != null) {
            await prefs.setString(
              "activeCompany",
              jsonEncode(user["data"]["activeCompany"]),
            );
          }
          if (user["data"]["activeCompanyIndex"] != null) {
            await prefs.setInt(
              "activeCompanyIndex",
              user["data"]["activeCompanyIndex"],
            );
          }
        }
      }

      return data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 UPDATE COMPANY
  Future<Map<String, dynamic>> updateCompany({
    int? companyIndex,
    required String companyName,
    String? companyEmail,
    String? companyPhone,
    String? companyAddress,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      // Use active company index if not provided
      final index = companyIndex ?? prefs.getInt("activeCompanyIndex") ?? 0;

      final response = await _dio.patch(
        "/api/auth/company/$index",
        data: {
          "companyName": companyName,
          if (companyEmail != null) "companyEmail": companyEmail,
          if (companyPhone != null) "companyPhone": companyPhone,
          if (companyAddress != null) "companyAddress": companyAddress,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final data = response.data;

      if (data["success"] == true && data["data"]["company"] != null) {
        // Update stored companies
        final authService = AuthService();
        final user = await authService.getMe();
        if (user["success"] == true && user["data"]["companies"] != null) {
          await prefs.setString(
            "companies",
            jsonEncode(user["data"]["companies"]),
          );
          if (user["data"]["activeCompany"] != null) {
            await prefs.setString(
              "activeCompany",
              jsonEncode(user["data"]["activeCompany"]),
            );
          }
        }
      }

      return data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 SWITCH COMPANY
  Future<Map<String, dynamic>> switchCompany({
    required int companyIndex,
  }) async {
    return AuthService().switchCompany(companyIndex: companyIndex);
  }

  // 🟢 INVITE STAFF
  Future<Map<String, dynamic>> inviteStaff({
    required String fullname,
    required String email,
    required String phoneNumber,
    required String role,
    required String position,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.post(
        "/api/auth/invite-staff",
        data: {
          "fullname": fullname,
          "email": email,
          "phoneNumber": phoneNumber,
          "role": role,
          "position": position,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 GET COMPANY STAFF
  Future<Map<String, dynamic>> getCompanyStaff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.get(
        "/api/auth/staff",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 REVOKE STAFF ACCESS
  Future<Map<String, dynamic>> revokeStaffAccess({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.patch(
        "/api/auth/staff/$userId/revoke",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 RESTORE STAFF ACCESS
  Future<Map<String, dynamic>> restoreStaffAccess({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.patch(
        "/api/auth/staff/$userId/restore",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 REMOVE STAFF
  Future<Map<String, dynamic>> removeStaff({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.delete(
        "/api/auth/staff/$userId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ==================== PERMISSIONS METHODS ====================

  // 🟢 GET STAFF PERMISSIONS
  Future<Map<String, dynamic>> getStaffPermissions({
    required String staffId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.get(
        "/api/permission/$staffId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 UPDATE STAFF PERMISSIONS
  Future<Map<String, dynamic>> updateStaffPermissions({
    required String staffId,
    required Map<String, bool> permissions,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.put(
        "/api/permission/$staffId",
        data: {"permissions": permissions},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 GRANT SPECIFIC PERMISSION
  Future<Map<String, dynamic>> grantPermission({
    required String staffId,
    required String permission,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.post(
        "/api/permission/$staffId/grant",
        data: {"permission": permission},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 REVOKE SPECIFIC PERMISSION
  Future<Map<String, dynamic>> revokePermission({
    required String staffId,
    required String permission,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.post(
        "/api/permission/$staffId/revoke",
        data: {"permission": permission},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ==================== NOTIFICATIONS METHODS ====================

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

  // 🟢 MARK NOTIFICATION AS READ
  Future<Map<String, dynamic>> markNotificationAsRead({
    required String notificationId,
  }) async {
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
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
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
  Future<Map<String, dynamic>> deleteNotification({
    required String notificationId,
  }) async {
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
    debugPrint("⚠️ [COMPANY ERROR] => ${e.response?.data ?? e.message}");

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
