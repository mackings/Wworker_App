import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/Constant/urls.dart';


class StaffService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  StaffService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("📤 [STAFF REQUEST] => ${options.method} ${options.uri}");
          if (options.data != null) {
            debugPrint("📦 [DATA] => ${options.data}");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint("✅ [STAFF RESPONSE] => ${response.statusCode} ${response.requestOptions.uri}");
          debugPrint("📥 [RESPONSE DATA] => ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("❌ [STAFF ERROR] => ${e.requestOptions.uri}");
          debugPrint("📛 [MESSAGE] => ${e.message}");
          debugPrint("📛 [RESPONSE] => ${e.response?.data}");
          return handler.next(e);
        },
      ),
    );
  }

  // 🟢 1️⃣ CREATE STAFF
  Future<Map<String, dynamic>> createStaff({
    required String fullname,
    required String email,
    required String phoneNumber,
    required String position,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final body = {
        "fullname": fullname,
        "email": email,
        "phoneNumber": phoneNumber,
        "position": position,
        "password": password,
      };

      final response = await _dio.post(
        "/api/staff/create",
        data: body,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 2️⃣ GET ALL STAFF
  Future<Map<String, dynamic>> getAllStaff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.get(
        "/api/staff",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 3️⃣ GRANT ACCESS TO STAFF
  Future<Map<String, dynamic>> grantAccess(String staffId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.patch(
        "/api/staff/$staffId/grant",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 4️⃣ REVOKE ACCESS FROM STAFF
  Future<Map<String, dynamic>> revokeAccess(String staffId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.patch(
        "/api/staff/$staffId/revoke",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 5️⃣ DELETE STAFF
  Future<Map<String, dynamic>> deleteStaff(String staffId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.delete(
        "/api/staff/$staffId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🔴 ERROR HANDLER
  Map<String, dynamic> _handleError(DioException e) {
    debugPrint("⚠️ [HANDLE STAFF ERROR] => ${e.response?.data ?? e.message}");
    
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