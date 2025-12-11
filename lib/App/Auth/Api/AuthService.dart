import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/Constant/urls.dart';


class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  AuthService() {
    // 🟣 Global Logging for all API calls
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("📤 [REQUEST] => ${options.method} ${options.uri}");
          debugPrint("📦 [DATA] => ${options.data}");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            "✅ [RESPONSE] => ${response.statusCode} ${response.requestOptions.uri}",
          );
          debugPrint("📥 [DATA] => ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          debugPrint("❌ [ERROR] => ${e.requestOptions.uri}");
          debugPrint("📛 [MESSAGE] => ${e.message}");

          if (e.response != null) {
            debugPrint("📄 [ERROR RESPONSE] => ${e.response?.data}");
          }

          // 🟠 Add Retry Logic (2 retries)
          final requestOptions = e.requestOptions;
          final retries = (requestOptions.extra["retries"] ?? 0) + 1;

          if (retries <= 2) {
            debugPrint("🔁 Retrying request... attempt #$retries");
            requestOptions.extra["retries"] = retries;
            await Future.delayed(const Duration(seconds: 1));
            try {
              final response = await _dio.fetch(requestOptions);
              return handler.resolve(response);
            } catch (err) {
              return handler.next(err as DioException);
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  // 🟢 SIGNUP - Company info is now optional
  Future<Map<String, dynamic>> signup({
    required String fullname,
    required String email,
    required String phoneNumber,
    required String password,
    String? companyName,
    String? companyEmail,
  }) async {
    try {
      final data = {
        "fullname": fullname,
        "email": email,
        "phoneNumber": phoneNumber,
        "password": password,
      };

      // Add company info only if provided
      if (companyName != null && companyName.isNotEmpty) {
        data["companyName"] = companyName;
        if (companyEmail != null && companyEmail.isNotEmpty) {
          data["companyEmail"] = companyEmail;
        }
      }

      final response = await _dio.post("/api/auth/signup", data: data);

      final responseData = response.data;

      // Save token and user data if signup successful
      if (responseData["success"] == true) {
        final prefs = await SharedPreferences.getInstance();
        final mainData = responseData["data"];

        if (mainData["token"] != null) {
          await prefs.setString("token", mainData["token"]);
        }

        if (mainData["user"] != null) {
          final user = mainData["user"];
          if (user["id"] != null) {
            await prefs.setString("userId", user["id"]);
          }
          if (user["email"] != null) {
            await prefs.setString("email", user["email"]);
          }
          if (user["role"] != null) {
            await prefs.setString("role", user["role"]);
          }
          // Save company if exists
          if (user["company"] != null) {
            await prefs.setString("company", jsonEncode(user["company"]));
          }
        }
      }

      return responseData;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 SIGNIN - Simplified
  Future<Map<String, dynamic>> signin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/api/auth/signin",
        data: {"email": email, "password": password},
      );

      final data = response.data;
      debugPrint("✅ [RESPONSE DATA] => $data");

      if (data["success"] == true) {
        final prefs = await SharedPreferences.getInstance();
        final mainData = data["data"];

        // Save token
        if (mainData["token"] != null) {
          await prefs.setString("token", mainData["token"]);
        }

        // Save user info
        if (mainData["user"] != null) {
          final user = mainData["user"];
          if (user["id"] != null) {
            await prefs.setString("userId", user["id"]);
          }
          if (user["email"] != null) {
            await prefs.setString("email", user["email"]);
          }
          if (user["role"] != null) {
            await prefs.setString("role", user["role"]);
          }
          if (user["position"] != null) {
            await prefs.setString("position", user["position"]);
          }
          // Save company if exists
          if (user["company"] != null) {
            await prefs.setString("company", jsonEncode(user["company"]));
          }
        }
      }

      return data;
    } on DioException catch (e) {
      debugPrint("❌ [ERROR] => ${e.response?.data ?? e.message}");
      return _handleError(e);
    }
  }

  // 🟢 UPDATE COMPANY INFO
  Future<Map<String, dynamic>> updateCompany({
    required String companyName,
    String? companyEmail,
    String? companyPhone,
    String? companyAddress,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No authentication token found"};
      }

      final response = await _dio.patch(
        "/api/auth/company",
        data: {
          "companyName": companyName,
          if (companyEmail != null) "companyEmail": companyEmail,
          if (companyPhone != null) "companyPhone": companyPhone,
          if (companyAddress != null) "companyAddress": companyAddress,
        },
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      final data = response.data;

      if (data["success"] == true && data["data"]["company"] != null) {
        await prefs.setString("company", jsonEncode(data["data"]["company"]));
      }

      return data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 INVITE STAFF - Creates full profile
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
        return {"success": false, "message": "No authentication token found"};
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
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
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
        return {"success": false, "message": "No authentication token found"};
      }

      final response = await _dio.get(
        "/api/auth/staff",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
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
        return {"success": false, "message": "No authentication token found"};
      }

      final response = await _dio.patch(
        "/api/auth/staff/$userId/revoke",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
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
        return {"success": false, "message": "No authentication token found"};
      }

      final response = await _dio.patch(
        "/api/auth/staff/$userId/restore",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 REMOVE STAFF
  Future<Map<String, dynamic>> removeStaff({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No authentication token found"};
      }

      final response = await _dio.delete(
        "/api/auth/staff/$userId",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 CHANGE PASSWORD
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No authentication token found"};
      }

      final response = await _dio.patch(
        "/api/auth/change-password",
        data: {
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        },
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 GET ME
  Future<Map<String, dynamic>> getMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No authentication token found"};
      }

      final response = await _dio.get(
        "/api/auth/me",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 FORGOT PASSWORD
  Future<Map<String, dynamic>> forgotPassword({String method = "email"}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString("email");

      if (savedEmail == null) {
        return {"success": false, "message": "No saved email found"};
      }

      final response = await _dio.post(
        "/api/auth/forgot-password",
        data: {"email": savedEmail, "method": method},
      );

      final data = response.data;

      if (data["userId"] != null) {
        await prefs.setString("userId", data["userId"]);
      }

      return data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 VERIFY OTP
  Future<Map<String, dynamic>> verifyOtp({required String otp}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("userId");

      if (userId == null) {
        return {
          "success": false,
          "message": "No user ID found for OTP verification",
        };
      }

      final response = await _dio.post(
        "/api/auth/verify-otp",
        data: {"userId": userId, "otp": otp},
      );

      final data = response.data;

      if (data["data"]?["resetToken"] != null) {
        await prefs.setString("resetToken", data["data"]["resetToken"]);
      }

      return data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 RESET PASSWORD
  Future<Map<String, dynamic>> resetPassword({required String password}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resetToken = prefs.getString("resetToken");

      if (resetToken == null) {
        return {"success": false, "message": "No reset token found"};
      }

      final response = await _dio.post(
        "/api/auth/reset-password",
        data: {"resetToken": resetToken, "password": password},
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🔹 Centralized Error Handler
  Map<String, dynamic> _handleError(DioException e) {
    debugPrint("⚠️ [HANDLE ERROR] => ${e.response?.data ?? e.message}");
    return {
      "success": false,
      "message": e.response?.data?["message"] ?? e.message,
    };
  }

  // 🟢 LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}