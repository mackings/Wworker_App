import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/Constant/urls.dart';

class PermissionService {
 final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  PermissionService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("📤 [PERMISSION REQUEST] => ${options.method} ${options.uri}");
          if (options.data != null) {
            debugPrint("📦 [DATA] => ${options.data}");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            "✅ [PERMISSION RESPONSE] => ${response.statusCode} ${response.requestOptions.uri}",
          );
          debugPrint("📥 [RESPONSE DATA] => ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("❌ [PERMISSION ERROR] => ${e.requestOptions.uri}");
          debugPrint("📛 [MESSAGE] => ${e.message}");
          debugPrint("📛 [RESPONSE] => ${e.response?.data}");
          return handler.next(e);
        },
      ),
    );
  }

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

  // 🔴 ERROR HANDLER
  Map<String, dynamic> _handleError(DioException e) {
    debugPrint("⚠️ [PERMISSION ERROR] => ${e.response?.data ?? e.message}");

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