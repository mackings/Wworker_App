import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Quotation/Model/MaterialCostModel.dart';
import 'package:wworker/App/Quotation/Model/Materialmodel.dart';
import 'package:wworker/Constant/urls.dart';



class MaterialService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  MaterialService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("📤 [REQUEST] => ${options.method} ${options.uri}");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint("✅ [RESPONSE] => ${response.statusCode} ${response.requestOptions.uri}");
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
      ),
    );
  }

  // 🟢 GET MATERIALS
  Future<List<MaterialModel>> getMaterials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) throw Exception("No auth token found");

      final response = await _dio.get(
        "/api/product/materials",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final data = response.data;

      if (data["success"] == true && data["data"] is List) {
        return (data["data"] as List)
            .map((json) => MaterialModel.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      debugPrint("⚠️ [GET MATERIALS ERROR] => ${e.response?.data ?? e.message}");
      return [];
    }
  }

  // 🟢 CREATE MATERIAL
  Future<MaterialModel?> createMaterial({
    required String name,
    required String unit,
    List<String> sizes = const [],
    List<String> foamDensities = const [],
    List<String> foamThicknesses = const [],
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) throw Exception("No auth token found");

      final response = await _dio.post(
        "/api/product/creatematerial",
        data: {
          "name": name,
          "unit": unit,
          "sizes": sizes,
          "foamDensities": foamDensities,
          "foamThicknesses": foamThicknesses,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final data = response.data;

      if (data["success"] == true && data["data"] != null) {
        return MaterialModel.fromJson(data["data"]);
      } else {
        return null;
      }
    } on DioException catch (e) {
      debugPrint("⚠️ [CREATE MATERIAL ERROR] => ${e.response?.data ?? e.message}");
      return null;
    }
  }

  // 🟢 ADD TYPES TO MATERIAL
  Future<MaterialModel?> addMaterialTypes({
    required String materialId,
    required List<String> types,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) throw Exception("No auth token found");

      final response = await _dio.post(
        "/api/product/$materialId/add-types",
        data: {"types": types},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final data = response.data;

      if (data["success"] == true && data["data"] != null) {
        return MaterialModel.fromJson(data["data"]);
      } else {
        return null;
      }
    } on DioException catch (e) {
      debugPrint("⚠️ [ADD TYPES ERROR] => ${e.response?.data ?? e.message}");
      return null;
    }
  }


  // 🟢 CALCULATE MATERIAL COST
Future<MaterialCostModel?> calculateMaterialCost({
  required String materialId,
  required double requiredWidth,
  required double requiredLength,
  required String requiredUnit,
  String? materialType,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) throw Exception("No auth token found");

    final response = await _dio.post(
      "/api/product/material/$materialId/calculate-cost",
      data: {
        "requiredWidth": requiredWidth,
        "requiredLength": requiredLength,
        "requiredUnit": requiredUnit,
        "materialType": materialType,
      },
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    final data = response.data;
    if (data["success"] == true && data["data"] != null) {
      return MaterialCostModel.fromJson(data["data"]);
    } else {
      return null;
    }
  } on DioException catch (e) {
    debugPrint("⚠️ [CALCULATE MATERIAL COST ERROR] => ${e.response?.data ?? e.message}");
    return null;
  }
}


}
