import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/Constant/urls.dart';


class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

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
      return {
        "success": false,
        "message": e.response?.data["message"] ?? e.message,
      };
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
        data: {
          "email": email,
          "password": password,
        },
      );

      final data = response.data;

      // ✅ Save token
      if (data["success"] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["data"]["token"]);
      }

      return data;
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data["message"] ?? e.message,
      };
    }
  }

  // 🟢 For other API calls
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // 🟢 Logout (optional)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}
