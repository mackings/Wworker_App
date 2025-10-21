import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/Constant/urls.dart';


class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  AuthService() {
    // 🟣 Global Logging for all API calls
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint("📤 [REQUEST] => ${options.method} ${options.uri}");
        debugPrint("📦 [DATA] => ${options.data}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint("✅ [RESPONSE] => ${response.statusCode} ${response.requestOptions.uri}");
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
          await Future.delayed(const Duration(seconds: 1)); // short delay
          try {
            final response = await _dio.fetch(requestOptions);
            return handler.resolve(response);
          } catch (err) {
            return handler.next(err as DioException);
          }
        }

        return handler.next(e);
      },
    ));
  }

  // 🟢 SIGNUP
  Future<Map<String, dynamic>> signup({
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/api/auth/signup",
        data: {
          "email": email,
          "phoneNumber": phoneNumber,
          "password": password,
        },
      );
      return response.data;
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
      debugPrint("✅ [RESPONSE DATA] => $data");
      debugPrint("🧩 [DATA TYPE] => ${data["data"]?.runtimeType}");

      dynamic mainData = data["data"];

      // 🔹 Decode stringified JSON if needed
      if (mainData is String) {
        try {
          mainData = jsonDecode(mainData);
          debugPrint("🧩 [DECODED DATA] => $mainData");
        } catch (e) {
          debugPrint("⚠️ Could not decode string data: $e");
        }
      }

      if (mainData is List && mainData.isNotEmpty) {
        mainData = mainData.first;
      }

      if (mainData is! Map) {
        debugPrint("⚠️ Unexpected data structure: $mainData");
        return {"success": false, "message": "Invalid response format"};
      }

      final token = mainData["token"];
      final user = mainData["user"];
      final userId = user?["id"];

      if (data["success"] == true) {
        final prefs = await SharedPreferences.getInstance();

        if (token != null && token is String) {
          await prefs.setString("token", token);
          await prefs.setString("email", email);
        } else {
          debugPrint("⚠️ No token found in response");
        }

        if (userId != null && userId is String) {
          await prefs.setString("userId", userId);
        } else {
          debugPrint("⚠️ No user ID found in response");
        }
      }

      return data;
    } on DioException catch (e) {
      debugPrint("❌ [ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message": e.response?.data["message"] ?? e.message,
      };
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
        data: {
          "email": savedEmail,
          "method": method,
        },
      );

      final data = response.data;

      if (data["data"]?["userId"] != null) {
        await prefs.setString("userId", data["data"]["userId"]);
      }

      return data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 VERIFY OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String otp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("userId");

      if (userId == null) {
        return {"success": false, "message": "No user ID found for OTP verification"};
      }

      debugPrint("📤 [REQUEST] => POST ${Urls.baseUrl}/api/auth/verify-otp");
      debugPrint("📦 [DATA] => {userId: $userId, otp: $otp}");

      final response = await _dio.post(
        "/api/auth/verify-otp",
        data: {
          "userId": userId,
          "otp": otp,
        },
      );

      debugPrint("✅ [RESPONSE] => ${response.statusCode} ${response.realUri}");
      debugPrint("📥 [DATA] => ${response.data}");

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
  Future<Map<String, dynamic>> resetPassword({
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resetToken = prefs.getString("resetToken");

      if (resetToken == null) {
        return {"success": false, "message": "No reset token found"};
      }

      debugPrint("📤 [REQUEST] => POST ${Urls.baseUrl}/api/auth/reset-password");
      debugPrint("📦 [DATA] => {resetToken: $resetToken, password: $password}");

      final response = await _dio.post(
        "/api/auth/reset-password",
        data: {
          "resetToken": resetToken,
          "password": password,
        },
      );

      debugPrint("✅ [RESPONSE] => ${response.statusCode} ${response.realUri}");
      debugPrint("📥 [DATA] => ${response.data}");

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