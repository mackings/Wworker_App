import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';




class MaterialService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://ww-backend.vercel.app',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static void _prettyPrintJson(dynamic data) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final prettyString = encoder.convert(data);
      debugPrint(prettyString);
    } catch (e) {
      debugPrint(data.toString());
    }
  }

  MaterialService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("━━━━━━━━━━━━━━ 📤 REQUEST ━━━━━━━━━━━━━━");
          debugPrint("➡️ METHOD: ${options.method}");
          debugPrint("🌍 URL: ${options.uri}");
          debugPrint("🧾 HEADERS: ${options.headers}");
          debugPrint("🔎 QUERY PARAMS: ${options.queryParameters}");
          debugPrint("📦 BODY: ${options.data}");
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint("━━━━━━━━━━━━━━ ✅ RESPONSE ━━━━━━━━━━━━━━");
          debugPrint("✅ STATUS CODE: ${response.statusCode}");
          debugPrint("🌍 URL: ${response.requestOptions.uri}");
          debugPrint("🧾 HEADERS: ${response.headers.map}");
          debugPrint("📄 DATA:");
          _prettyPrintJson(response.data);
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("━━━━━━━━━━━━━━ ❌ ERROR ━━━━━━━━━━━━━━");
          debugPrint("❌ URL: ${e.requestOptions.uri}");
          debugPrint("❌ METHOD: ${e.requestOptions.method}");
          debugPrint("❌ MESSAGE: ${e.message}");
          debugPrint("❌ TYPE: ${e.type}");

          if (e.response != null) {
            debugPrint("❌ STATUS CODE: ${e.response?.statusCode}");
            debugPrint("❌ RESPONSE DATA:");
            _prettyPrintJson(e.response?.data);
          } else {
            debugPrint("❌ NO SERVER RESPONSE RECEIVED");
          }

          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
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

  /// ✅ Get company name from SharedPreferences
  Future<String?> _getCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("companyName");
  }

  /// ✅ Validate company exists
  Future<Map<String, dynamic>?> _validateCompany() async {
    final companyName = await _getCompanyName();
    
    if (companyName == null || companyName.isEmpty) {
      debugPrint("⚠️ No active company found!");
      return {
        'success': false,
        'message': 'No active company found. Please select or create a company.',
      };
    }
    
    debugPrint("🏢 Active Company: $companyName");
    return null; // No error
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

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      // ✅ Get company name and attach to request
      final companyName = await _getCompanyName();
      request['companyName'] = companyName;

      final imagePath = request.remove('imagePath');
      final formPayload = <String, dynamic>{};

      request.forEach((key, value) {
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

      final formData = FormData.fromMap(formPayload);

      debugPrint("📤 [CREATE MATERIAL] => $formPayload");
      debugPrint("🏢 [COMPANY] => $companyName");

      final response = await _dio.post(
        '/api/product/creatematerial',
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
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

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      final companyName = await _getCompanyName();
      debugPrint("📤 [GET ALL MATERIALS] Company: $companyName, Category: $category");

      final queryParams = <String, dynamic>{};
      if (category != null) {
        queryParams['category'] = category;
      }

      final response = await _dio.get(
        '/api/materials',  // Backend filters by company automatically via middleware
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

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      debugPrint("📤 [GET MATERIAL CATEGORIES]");

      final response = await _dio.get(
        '/api/materials/categories',  // Backend filters by company
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

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      debugPrint("📤 [GET MATERIAL BY ID] => $materialId");

      final response = await _dio.get(
        '/api/materials/$materialId',
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

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      // ✅ Attach company name (in case it's needed for validation)
      final companyName = await _getCompanyName();
      updateData['companyName'] = companyName;

      debugPrint("📤 [UPDATE MATERIAL] => $materialId");
      debugPrint("📦 [UPDATE DATA] => $updateData");

      final response = await _dio.put(
        '/api/materials/$materialId',
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

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      debugPrint("📤 [ADD MATERIAL TYPES] => Material ID: $materialId");
      debugPrint("📦 [TYPES] => $request");

      final response = await _dio.post(
        '/api/materials/$materialId/types',
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

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      debugPrint("📤 [DELETE MATERIAL] => $materialId");

      final response = await _dio.delete(
        '/api/materials/$materialId',
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

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      debugPrint("📤 [CALCULATE MATERIAL COST] => Material ID: $materialId");
      debugPrint("📦 [REQUEST] => $request");

      final response = await _dio.post(
        '/api/materials/$materialId/calculate',
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

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      // ✅ Attach company name to all materials
      final companyName = await _getCompanyName();
      final materialsWithCompany = materials.map((material) {
        material['companyName'] = companyName;
        return material;
      }).toList();

      debugPrint("📤 [BULK CREATE MATERIALS] => Count: ${materials.length}");
      debugPrint("🏢 [COMPANY] => $companyName");

      final response = await _dio.post(
        '/api/materials/bulk',
        data: {'materials': materialsWithCompany},
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
