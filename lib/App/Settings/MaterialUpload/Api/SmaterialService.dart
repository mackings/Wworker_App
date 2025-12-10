import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';




class MaterialService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://ww-backend.vercel.app',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

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
          debugPrint("📄 [RESPONSE DATA] => ${response.data}");
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

  /// Get authorization token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// Create a new material (Enhanced - supports all categories)
  Future<Map<String, dynamic>> createMaterial(
    Map<String, dynamic> request,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [CREATE MATERIAL] => $request");

      final response = await _dio.post(
        '/api/product/creatematerial',
        data: request,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [CREATE MATERIAL SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [CREATE MATERIAL ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to create material',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get all materials (with optional category filter)
  Future<Map<String, dynamic>> getAllMaterials({String? category}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [GET ALL MATERIALS] Category: $category");

      final queryParams = <String, dynamic>{};
      if (category != null) {
        queryParams['category'] = category;
      }

      final response = await _dio.get(
        '/api/product/materials',
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [GET ALL MATERIALS SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [GET ALL MATERIALS ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch materials',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get material categories with counts
  Future<Map<String, dynamic>> getMaterialCategories() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [GET MATERIAL CATEGORIES]");

      final response = await _dio.get(
        '/api/product/material-categories',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [GET MATERIAL CATEGORIES SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [GET MATERIAL CATEGORIES ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch categories',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get a single material by ID
  Future<Map<String, dynamic>> getMaterialById(String materialId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [GET MATERIAL BY ID] => $materialId");

      final response = await _dio.get(
        '/api/product/material/$materialId',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [GET MATERIAL SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [GET MATERIAL ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch material',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Update material
  Future<Map<String, dynamic>> updateMaterial(
    String materialId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [UPDATE MATERIAL] => $materialId");
      debugPrint("📦 [UPDATE DATA] => $updateData");

      final response = await _dio.put(
        '/api/product/material/$materialId',
        data: updateData,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [UPDATE MATERIAL SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [UPDATE MATERIAL ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to update material',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Add types to an existing material
  Future<Map<String, dynamic>> addMaterialTypes(
    String materialId,
    Map<String, dynamic> request,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [ADD MATERIAL TYPES] => Material ID: $materialId");
      debugPrint("📦 [TYPES] => $request");

      final response = await _dio.post(
        '/api/product/$materialId/add-types',
        data: request,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [ADD MATERIAL TYPES SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [ADD MATERIAL TYPES ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to add material types',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Delete material
  Future<Map<String, dynamic>> deleteMaterial(String materialId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [DELETE MATERIAL] => $materialId");

      final response = await _dio.delete(
        '/api/product/material/$materialId',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [DELETE MATERIAL SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [DELETE MATERIAL ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to delete material',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Calculate material cost
  Future<Map<String, dynamic>> calculateMaterialCost(
    String materialId,
    Map<String, dynamic> request,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [CALCULATE MATERIAL COST] => Material ID: $materialId");
      debugPrint("📦 [REQUEST] => $request");

      final response = await _dio.post(
        '/api/product/material/$materialId/calculate',
        data: request,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [CALCULATE MATERIAL COST SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [CALCULATE MATERIAL COST ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to calculate cost',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Bulk create materials (import from Excel)
  Future<Map<String, dynamic>> bulkCreateMaterials(
    List<Map<String, dynamic>> materials,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [BULK CREATE MATERIALS] => Count: ${materials.length}");

      final response = await _dio.post(
        '/api/product/materials/bulk',
        data: {'materials': materials},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [BULK CREATE MATERIALS SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [BULK CREATE MATERIALS ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to bulk create materials',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}