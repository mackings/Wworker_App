import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Quotation/Model/MaterialCostModel.dart';
import 'package:wworker/App/Quotation/Model/Materialmodel.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';
import 'package:wworker/GeneralWidgets/UI/etag_cache.dart';

class MaterialService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  MaterialService() {
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

    _dio.interceptors.add(RetryTwiceInterceptor(_dio));
    _dio.interceptors.add(ApiFeedbackInterceptor());
  }

  // 🟢 GET ALL MATERIALS
  Future<Map<String, dynamic>> getAllMaterials({
    String? category,
    String? subCategory,
    String? search,
    bool? priced,
    bool? isActive,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (subCategory != null) queryParams['subCategory'] = subCategory;
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (priced != null) queryParams['priced'] = priced;
      if (isActive != null) queryParams['isActive'] = isActive;

      final data = await dioGetWithEtagCache(
        dio: _dio,
        path: "/api/product/materials",
        queryParameters: queryParams,
        headers: {"Authorization": "Bearer $token"},
      );

      return (data is Map<String, dynamic>)
          ? data
          : (data is Map
                ? Map<String, dynamic>.from(data)
                : <String, dynamic>{});
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [GET MATERIALS ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ??
            e.message ??
            'Failed to fetch materials',
      };
    }
  }

  // 🟢 GET GROUPED MATERIALS (category -> subCategory -> variants)
  Future<Map<String, dynamic>> getGroupedMaterials({
    String? category,
    String? subCategory,
    String? search,
    bool? priced,
    bool? isActive,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (subCategory != null) queryParams['subCategory'] = subCategory;
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (priced != null) queryParams['priced'] = priced;
      if (isActive != null) queryParams['isActive'] = isActive;

      final data = await dioGetWithEtagCache(
        dio: _dio,
        path: "/api/product/materials/grouped",
        queryParameters: queryParams,
        headers: {"Authorization": "Bearer $token"},
      );

      return (data is Map<String, dynamic>)
          ? data
          : (data is Map
                ? Map<String, dynamic>.from(data)
                : <String, dynamic>{});
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [GET GROUPED MATERIALS ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ??
            e.message ??
            'Failed to fetch grouped materials',
      };
    }
  }

  // 🟢 GET MATERIALS (for backward compatibility)
  Future<List<MaterialModel>> getMaterials() async {
    try {
      final result = await getAllMaterials();

      if (result['success'] == true && result['data'] is List) {
        return (result['data'] as List)
            .map((json) => MaterialModel.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("⚠️ [GET MATERIALS ERROR] => $e");
      return [];
    }
  }

  // 🟢 CREATE MATERIAL (Generic - works for all categories)
  Future<Map<String, dynamic>> createMaterial(
    Map<String, dynamic> materialData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      // Per Materials API doc: useCatalog defaults to true.
      materialData['useCatalog'] = materialData['useCatalog'] ?? true;
      final imagePath = materialData.remove('imagePath');
      final formPayload = <String, dynamic>{};

      materialData.forEach((key, value) {
        if (value == null) return;
        if (value is List || value is Map) {
          formPayload[key] = jsonEncode(value);
        } else {
          formPayload[key] = value.toString();
        }
      });

      if (imagePath is String && imagePath.isNotEmpty) {
        formPayload['image'] = await MultipartFile.fromFile(imagePath);
      }

      final response = await _dio.post(
        "/api/product/creatematerial",
        data: FormData.fromMap(formPayload),
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [CREATE MATERIAL ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ??
            e.message ??
            'Failed to create material',
      };
    }
  }

  // 🟢 ADD TYPES TO MATERIAL
  Future<Map<String, dynamic>> addMaterialTypes(
    String materialId,
    Map<String, dynamic> typesData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final response = await _dio.post(
        "/api/product/material/$materialId/add-types",
        data: typesData,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [ADD TYPES ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ?? e.message ?? 'Failed to add types',
      };
    }
  }

  // 🟢 CALCULATE MATERIAL COST
  Future<MaterialCostModel?> calculateMaterialCost({
    required String materialId,
    required double requiredWidth,
    required double requiredLength,
    required String requiredUnit,
    String? materialType,
    String? sizeVariant,
    double? foamThickness,
    String? foamDensity,
    int quantity = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) throw Exception("No auth token found");

      final sheetRequestData = {
        "requiredWidth": requiredWidth,
        "requiredLength": requiredLength,
        "requiredUnit": requiredUnit,
        if (materialType != null) "materialType": materialType,
        if (sizeVariant != null) "sizeVariant": sizeVariant,
        if (foamThickness != null) "foamThickness": foamThickness,
        if (foamDensity != null) "foamDensity": foamDensity,
        "quantity": quantity,
      };

      debugPrint("🔢 [CALCULATING COST] => $sheetRequestData");

      try {
        final response = await _dio.post(
          "/api/product/material/$materialId/calculate-cost",
          data: sheetRequestData,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        final data = response.data;
        if (data["success"] == true && data["data"] != null) {
          return MaterialCostModel.fromJson(data["data"]);
        }
        return null;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final respData = e.response?.data;
        final message = respData is Map
            ? respData["message"]?.toString()
            : null;

        final shouldFallback =
            status == 400 &&
            (message ?? '').toLowerCase().contains(
              "use quantity-based calculation",
            );

        if (!shouldFallback) {
          debugPrint(
            "⚠️ [CALCULATE MATERIAL COST ERROR] => ${e.response?.data ?? e.message}",
          );
          return null;
        }

        final unitRequestData = {"quantity": quantity};
        debugPrint(
          "🔁 [COST FALLBACK] Retrying unit-based => $unitRequestData",
        );

        final retry = await _dio.post(
          "/api/product/material/$materialId/calculate-cost",
          data: unitRequestData,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        final data = retry.data;
        if (data["success"] == true && data["data"] != null) {
          return MaterialCostModel.fromJson(data["data"]);
        }
        return null;
      }
    } catch (e) {
      debugPrint("⚠️ [CALCULATE MATERIAL COST ERROR] => $e");
      return null;
    }
  }

  // 🟢 UPDATE MATERIAL
  Future<Map<String, dynamic>> updateMaterial(
    String materialId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final response = await _dio.put(
        "/api/product/material/$materialId",
        data: updates,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [UPDATE MATERIAL ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ??
            e.message ??
            'Failed to update material',
      };
    }
  }

  // 🟢 DELETE MATERIAL
  Future<Map<String, dynamic>> deleteMaterial(String materialId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final response = await _dio.delete(
        "/api/product/material/$materialId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [DELETE MATERIAL ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ??
            e.message ??
            'Failed to delete material',
      };
    }
  }

  // 🟢 SUPPORTED MATERIALS (catalog rows)
  Future<Map<String, dynamic>> getSupportedMaterials({
    String? category,
    String? subCategory,
    String? search,
    bool? priced,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final queryParams = <String, dynamic>{"page": page, "limit": limit};
      if (category != null) queryParams["category"] = category;
      if (subCategory != null) queryParams["subCategory"] = subCategory;
      if (search != null && search.trim().isNotEmpty) {
        queryParams["search"] = search.trim();
      }
      if (priced != null) queryParams["priced"] = priced;

      final data = await dioGetWithEtagCache(
        dio: _dio,
        path: "/api/product/materials/supported",
        queryParameters: queryParams,
        headers: {"Authorization": "Bearer $token"},
      );

      return (data is Map<String, dynamic>)
          ? data
          : (data is Map
                ? Map<String, dynamic>.from(data)
                : <String, dynamic>{});
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ??
            e.message ??
            'Failed to fetch supported materials',
      };
    }
  }

  // 🟢 SUPPORTED MATERIALS SUMMARY
  Future<Map<String, dynamic>> getSupportedMaterialsSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final data = await dioGetWithEtagCache(
        dio: _dio,
        path: "/api/product/materials/supported/summary",
        headers: {"Authorization": "Bearer $token"},
      );

      return (data is Map<String, dynamic>)
          ? data
          : (data is Map
                ? Map<String, dynamic>.from(data)
                : <String, dynamic>{});
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ??
            e.message ??
            'Failed to fetch supported summary',
      };
    }
  }
}
