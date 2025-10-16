import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Product/Model/ProModel.dart';
import 'package:wworker/Constant/urls.dart';

class ProductService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  ProductService() {
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
      onError: (DioException e, handler) {
        debugPrint("❌ [ERROR] => ${e.requestOptions.uri}");
        debugPrint("📛 [MESSAGE] => ${e.message}");
        if (e.response != null) {
          debugPrint("📄 [ERROR RESPONSE] => ${e.response?.data}");
        }
        return handler.next(e);
      },
    ));
  }

  // 🟢 CREATE PRODUCT (Multipart POST)
  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String subCategory,
    required String description,
    required String category,
    required String imagePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final formData = FormData.fromMap({
        "name": name,
        "subCategory": subCategory,
        "description": description,
        "category": category,
        "image": await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
      });

      final response = await _dio.post(
        "/api/product/",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 🟢 GET PRODUCTS
  Future<List<ProductModel>> getProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint("📤 [REQUEST] => GET ${Urls.baseUrl}/api/product/");

      final response = await _dio.get(
        "/api/product/",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      final data = response.data;

      if (data["success"] == true && data["data"] is List) {
        final products = (data["data"] as List)
            .map((json) => ProductModel.fromJson(json))
            .toList();
        return products;
      } else {
        return [];
      }
    } on DioException catch (e) {
      debugPrint("⚠️ [GET PRODUCTS ERROR] => ${e.response?.data ?? e.message}");
      return [];
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
}
