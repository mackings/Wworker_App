import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Settings/Model/SMaterialModel.dart';

class MaterialService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://ww-backend.vercel.app'));

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

  /// Create a new material
  Future<Map<String, dynamic>> createMaterial(
    CreateMaterialRequest request,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [CREATE MATERIAL] => ${request.toJson()}");

      final response = await _dio.post(
        '/api/product/creatematerial',
        data: request.toJson(),
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

  /// Add types to an existing material
  Future<Map<String, dynamic>> addMaterialTypes(
    String materialId,
    AddMaterialTypesRequest request,
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
      debugPrint("📦 [TYPES] => ${request.toJson()}");

      final response = await _dio.post(
        '/api/product/$materialId/add-types',
        data: request.toJson(),
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

  /// Get all materials
  Future<Map<String, dynamic>> getAllMaterials() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [GET ALL MATERIALS]");

      final response = await _dio.get(
        '/api/product/materials',
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
}