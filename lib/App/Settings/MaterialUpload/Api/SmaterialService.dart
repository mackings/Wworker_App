import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';
import 'package:wworker/GeneralWidgets/UI/etag_cache.dart';

class MaterialService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Urls.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

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

    _dio.interceptors.add(RetryTwiceInterceptor(_dio));
    _dio.interceptors.add(ApiFeedbackInterceptor());
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
        'message':
            'No active company found. Please select or create a company.',
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
        return {'success': false, 'message': 'No auth token found'};
      }

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      // ✅ Get company name and attach to request
      final companyName = await _getCompanyName();
      request['companyName'] = companyName;
      // Per Materials API doc: useCatalog defaults to true.
      request['useCatalog'] = request['useCatalog'] ?? true;

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
      await invalidateMaterialsEtagCache();
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
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Get all materials (with optional category filter)
  Future<Map<String, dynamic>> getAllMaterials({
    String? category,
    String? subCategory,
    String? search,
    bool? isActive,
    bool? priced,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      final companyName = await _getCompanyName();
      debugPrint(
        "📤 [GET ALL MATERIALS] Company: $companyName, Category: $category, Subcategory: $subCategory",
      );

      final queryParams = <String, dynamic>{};
      if (category != null) {
        queryParams['category'] = category;
      }
      if (subCategory != null) {
        queryParams['subCategory'] = subCategory;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive;
      }
      if (priced != null) {
        queryParams['priced'] = priced;
      }

      final data = await dioGetWithEtagCache(
        dio: _dio,
        path: '/api/product/materials',
        queryParameters: queryParams,
        headers: {"Authorization": "Bearer $token"},
      );

      debugPrint("✅ [GET ALL MATERIALS SUCCESS] => $data");
      return (data is Map<String, dynamic>)
          ? data
          : (data is Map
                ? Map<String, dynamic>.from(data)
                : <String, dynamic>{});
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
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Get grouped materials (category -> subCategory -> variants)
  Future<Map<String, dynamic>> getGroupedMaterials({
    String? category,
    String? subCategory,
    String? search,
    bool? isActive,
    bool? priced,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (subCategory != null) queryParams['subCategory'] = subCategory;
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (isActive != null) queryParams['isActive'] = isActive;
      if (priced != null) queryParams['priced'] = priced;

      final data = await dioGetWithEtagCache(
        dio: _dio,
        path: '/api/product/materials/grouped',
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
            e.response?.data['message'] ?? 'Failed to fetch grouped materials',
      };
    } catch (_) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Get actual saved materials from MongoDB, grouped by category/subcategory.
  Future<Map<String, dynamic>> getDatabaseGroupedMaterials({
    String? category,
    String? subCategory,
    String? search,
    bool? isActive,
    bool? priced,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      final queryParams = <String, dynamic>{};
      if (category != null && category.trim().isNotEmpty) {
        queryParams['category'] = category.trim();
      }
      if (subCategory != null && subCategory.trim().isNotEmpty) {
        queryParams['subCategory'] = subCategory.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (isActive != null) queryParams['isActive'] = isActive;
      if (priced != null) queryParams['priced'] = priced;

      final data = await dioGetWithEtagCache(
        dio: _dio,
        path: '/api/database/materials/grouped',
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
            e.response?.data['message'] ??
            'Failed to fetch grouped database materials',
      };
    } catch (_) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Get material categories with counts from supported catalog summary
  Future<Map<String, dynamic>> getMaterialCategories() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      debugPrint("📤 [GET MATERIAL CATEGORIES]");

      final data = await dioGetWithEtagCache(
        dio: _dio,
        path: '/api/product/materials/supported/summary',
        headers: {"Authorization": "Bearer $token"},
      );

      debugPrint("✅ [GET MATERIAL CATEGORIES SUCCESS] => $data");
      return (data is Map<String, dynamic>)
          ? data
          : (data is Map
                ? Map<String, dynamic>.from(data)
                : <String, dynamic>{});
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
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Get a single material by ID
  Future<Map<String, dynamic>> getMaterialById(String materialId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      debugPrint("📤 [GET MATERIAL BY ID] => $materialId");

      final response = await _dio.get(
        '/api/database/materials',
        queryParameters: {'id': materialId, 'limit': 1},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [GET MATERIAL SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [GET MATERIAL ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch material',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
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
        return {'success': false, 'message': 'No auth token found'};
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
        '/api/database/materials/$materialId',
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
      return {'success': false, 'message': 'An unexpected error occurred'};
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
        return {'success': false, 'message': 'No auth token found'};
      }

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

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
        'message':
            e.response?.data['message'] ?? 'Failed to add material types',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Delete material
  Future<Map<String, dynamic>> deleteMaterial(String materialId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      debugPrint("📤 [DELETE MATERIAL] => $materialId");

      final response = await _dio.delete(
        '/api/database/materials/$materialId',
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
      return {'success': false, 'message': 'An unexpected error occurred'};
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
        return {'success': false, 'message': 'No auth token found'};
      }

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      debugPrint("📤 [CALCULATE MATERIAL COST] => Material ID: $materialId");
      debugPrint("📦 [REQUEST] => $request");

      try {
        final response = await _dio.post(
          '/api/product/material/$materialId/calculate-cost',
          data: request,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        debugPrint("✅ [CALCULATE MATERIAL COST SUCCESS] => ${response.data}");
        return response.data;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        final message = data is Map ? data['message']?.toString() : null;

        final shouldFallback =
            status == 400 &&
            (message ?? '').toLowerCase().contains(
              'use quantity-based calculation',
            );

        if (!shouldFallback) {
          rethrow;
        }

        final qtyRaw = request['quantity'];
        final qty = qtyRaw is num
            ? qtyRaw.toDouble()
            : double.tryParse(qtyRaw?.toString() ?? '') ?? 1;
        final retryBody = {'quantity': qty};

        debugPrint("🔁 [COST FALLBACK] Retrying unit-based => $retryBody");

        final retry = await _dio.post(
          '/api/product/material/$materialId/calculate-cost',
          data: retryBody,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        debugPrint("✅ [CALCULATE MATERIAL COST SUCCESS] => ${retry.data}");
        return retry.data;
      }
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
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Bulk create materials (import from Excel)
  Future<Map<String, dynamic>> bulkCreateMaterials(
    List<Map<String, dynamic>> materials,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
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
        'message':
            e.response?.data['message'] ?? 'Failed to bulk create materials',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Get exact supported catalog materials for app pickers/search
  Future<Map<String, dynamic>> getSupportedMaterials({
    String? category,
    String? subCategory,
    String? search,
    bool? priced,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (category != null) queryParams['category'] = category;
      if (subCategory != null) queryParams['subCategory'] = subCategory;
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (priced != null) queryParams['priced'] = priced;

      final data = await dioGetWithEtagCache(
        dio: _dio,
        path: '/api/product/materials/supported',
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
            e.response?.data['message'] ??
            'Failed to fetch supported materials',
      };
    } catch (_) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Get supported catalog category/subcategory summary
  Future<Map<String, dynamic>> getSupportedMaterialsSummary() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final data = await dioGetWithEtagCache(
        dio: _dio,
        path: '/api/product/materials/supported/summary',
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
            e.response?.data['message'] ??
            'Failed to fetch supported material summary',
      };
    } catch (_) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
