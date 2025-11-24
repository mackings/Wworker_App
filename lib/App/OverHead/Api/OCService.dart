import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/OverHead/Model/OCmodel.dart';
import 'package:wworker/Constant/urls.dart';




class OverheadCostService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  OverheadCostService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("📤 [OVERHEAD REQUEST]");
          debugPrint("➡️ URL: ${options.uri}");
          debugPrint("🧾 METHOD: ${options.method}");
          debugPrint("📋 HEADERS: ${options.headers}");
          if (options.data != null) {
            debugPrint("📦 BODY: ${options.data}");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint("✅ [OVERHEAD RESPONSE]");
          debugPrint("🔢 STATUS: ${response.statusCode}");
          debugPrint("📄 DATA: ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("❌ [OVERHEAD ERROR]");
          debugPrint("📛 MESSAGE: ${e.message}");
          debugPrint("📍 URL: ${e.requestOptions.uri}");
          if (e.response != null) {
            debugPrint("🔢 STATUS CODE: ${e.response?.statusCode}");
            debugPrint("📄 RESPONSE: ${e.response?.data}");
          }
          return handler.next(e);
        },
      ),
    );
  }

  // 🟢 CREATE OVERHEAD COST
  Future<Map<String, dynamic>> createOverheadCost({
    required String category,
    required String description,
    required String period,
    required double cost,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) throw Exception("No auth token found");

      debugPrint(
        "📤 [CREATE OVERHEAD] => POST ${Urls.baseUrl}/api/oc/create-oc",
      );

      final response = await _dio.post(
        "/api/oc/create-oc",
        data: {
          "category": category,
          "description": description,
          "period": period,
          "cost": cost,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint(
          "⚠️ [CREATE OVERHEAD ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message":
            e.response?.data?["message"] ?? "Failed to create overhead cost",
      };
    }
  }

  // 🟡 GET USER OVERHEAD COSTS
  Future<List<OverheadCost>> getOverheadCosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) throw Exception("No auth token found");

      debugPrint(
        "📤 [FETCH OVERHEAD COSTS] => GET ${Urls.baseUrl}/api/oc/get-oc",
      );

      final response = await _dio.get(
        "/api/oc/get-oc",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final List data = response.data["data"];

      return data.map((e) => OverheadCost.fromJson(e)).toList();
    } on DioException catch (e) {
      debugPrint(
          "⚠️ [FETCH OVERHEAD ERROR] => ${e.response?.data ?? e.message}");
      return [];
    }
  }


    // 🔴 DELETE OVERHEAD COST
  Future<Map<String, dynamic>> deleteOverheadCost(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) throw Exception("No auth token found");

      debugPrint(
        "📤 [DELETE OVERHEAD] => DELETE ${Urls.baseUrl}/api/oc/delete-oc/$id",
      );

      final response = await _dio.delete(
        "/api/oc/delete-oc/$id",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint(
          "⚠️ [DELETE OVERHEAD ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message":
            e.response?.data?["message"] ?? "Failed to delete overhead cost",
      };
    }
  }


}
