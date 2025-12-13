import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/Constant/urls.dart';


class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  AuthService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("📤 [AUTH REQUEST] => ${options.method} ${options.uri}");
          debugPrint("📦 [DATA] => ${options.data}");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            "✅ [AUTH RESPONSE] => ${response.statusCode} ${response.requestOptions.uri}",
          );
          debugPrint("📥 [DATA] => ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          debugPrint("❌ [AUTH ERROR] => ${e.requestOptions.uri}");
          debugPrint("📛 [MESSAGE] => ${e.message}");

          if (e.response != null) {
            debugPrint("📄 [ERROR RESPONSE] => ${e.response?.data}");
          }

          // Retry Logic (2 retries)
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

  // 🟢 SIGNUP
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

      if (companyName != null && companyName.isNotEmpty) {
        data["companyName"] = companyName;
        if (companyEmail != null && companyEmail.isNotEmpty) {
          data["companyEmail"] = companyEmail;
        }
      }

      final response = await _dio.post("/api/auth/signup", data: data);
      final responseData = response.data;

      if (responseData["success"] == true) {
        await _saveUserData(responseData["data"]);
      }

      return responseData;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 SIGNIN
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

      if (data["success"] == true) {
        await _saveUserData(data["data"]);
      }

      return data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 SAVE USER DATA TO SHARED PREFERENCES
// services/auth_api.dart

// 🟢 SAVE USER DATA TO SHARED PREFERENCES
Future<void> _saveUserData(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();

  // Save token
  if (data["token"] != null) {
    await prefs.setString("token", data["token"]);
    debugPrint("✅ Token saved");
  }

  // Save user data
  if (data["user"] != null) {
    final user = data["user"];

    if (user["id"] != null) {
      await prefs.setString("userId", user["id"]);
      debugPrint("✅ User ID saved: ${user["id"]}");
    }

    if (user["fullname"] != null) {
      await prefs.setString("fullname", user["fullname"]);
      debugPrint("✅ Fullname saved: ${user["fullname"]}");
    }

    if (user["email"] != null) {
      await prefs.setString("email", user["email"]);
      debugPrint("✅ Email saved: ${user["email"]}");
    }

    if (user["phoneNumber"] != null) {
      await prefs.setString("phoneNumber", user["phoneNumber"]);
      debugPrint("✅ Phone number saved: ${user["phoneNumber"]}");
    }

    // ✅ Save companies array
    if (user["companies"] != null) {
      await prefs.setString("companies", jsonEncode(user["companies"]));
      debugPrint("✅ Companies saved: ${user["companies"].length} companies");
    } else {
      // ✅ Clear companies if null
      await prefs.remove("companies");
      debugPrint("🗑️ Companies cleared (user has no companies)");
    }

    // ✅ Save active company index
    if (user["activeCompanyIndex"] != null) {
      await prefs.setInt("activeCompanyIndex", user["activeCompanyIndex"]);
      debugPrint("✅ Active company index saved: ${user["activeCompanyIndex"]}");
    } else {
      await prefs.remove("activeCompanyIndex");
    }

    // ✅ Save active company data OR CLEAR if null
    if (user["activeCompany"] != null) {
      final activeCompany = user["activeCompany"];
      await prefs.setString("activeCompany", jsonEncode(activeCompany));
      
      // ✅ Save individual company fields for easy access
      if (activeCompany["name"] != null) {
        await prefs.setString("companyName", activeCompany["name"]);
        debugPrint("🏢 Active Company Name saved: ${activeCompany["name"]}");
      }
      
      if (activeCompany["email"] != null) {
        await prefs.setString("companyEmail", activeCompany["email"]);
      }
      
      if (activeCompany["phoneNumber"] != null) {
        await prefs.setString("companyPhoneNumber", activeCompany["phoneNumber"]);
      }
      
      if (activeCompany["address"] != null) {
        await prefs.setString("companyAddress", activeCompany["address"]);
      }
      
      if (activeCompany["role"] != null) {
        await prefs.setString("userRole", activeCompany["role"]);
        debugPrint("👤 User role saved: ${activeCompany["role"]}");
      }
      
      if (activeCompany["position"] != null) {
        await prefs.setString("userPosition", activeCompany["position"]);
        debugPrint("💼 User position saved: ${activeCompany["position"]}");
      }

      debugPrint("✅ Full Active Company saved: ${jsonEncode(activeCompany)}");
    } else {
      // ✅ IMPORTANT: Clear all company-related data if user has no active company
      await prefs.remove("activeCompany");
      await prefs.remove("companyName");
      await prefs.remove("companyEmail");
      await prefs.remove("companyPhoneNumber");
      await prefs.remove("companyAddress");
      await prefs.remove("userRole");
      await prefs.remove("userPosition");
      debugPrint("🗑️ Active company data cleared (user has no active company)");
    }
  }

  debugPrint("🎉 All user data saved successfully!");
}




  // 🟢 GET ACTIVE COMPANY NAME (Helper method)
  Future<String?> getActiveCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("companyName");
  }

  // 🟢 GET ACTIVE COMPANY DATA (Helper method)
  Future<Map<String, dynamic>?> getActiveCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final companyString = prefs.getString("activeCompany");
    
    if (companyString != null) {
      return jsonDecode(companyString);
    }
    
    return null;
  }

  // 🟢 GET USER ROLE (Helper method)
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userRole");
  }

  // 🟢 CHECK IF USER IS OWNER/ADMIN (Helper method)
  Future<bool> canManageStaff() async {
    final role = await getUserRole();
    return role == 'owner' || role == 'admin';
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

      // ✅ Update stored data with fresh data from server
      if (response.data["success"] == true && response.data["data"] != null) {
        await _saveUserData({"user": response.data["data"]});
      }

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("🚪 User logged out - all data cleared");
  }

  // 🔹 Error Handler
  Map<String, dynamic> _handleError(DioException e) {
    debugPrint("⚠️ [AUTH ERROR] => ${e.response?.data ?? e.message}");
    return {
      "success": false,
      "message": e.response?.data?["message"] ?? e.message,
    };
  }
}