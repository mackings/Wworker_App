import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Database/Model/database_models.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';

class PlatformOwnerService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Urls.baseUrl,
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

  static void _logResponseData(Response response) {
    final path = response.requestOptions.path;
    if (path == '/api/database/materials') {
      final payload = response.data;
      final data = payload is Map<String, dynamic> ? payload['data'] : null;
      final rows = data is Map<String, dynamic> ? data['data'] : null;
      final pagination =
          data is Map<String, dynamic> ? data['pagination'] : null;
      final count = rows is List ? rows.length : 0;
      debugPrint(
        "📄 DATA: {success: ${payload is Map<String, dynamic> ? payload['success'] : null}, message: ${payload is Map<String, dynamic> ? payload['message'] : null}, count: $count, pagination: $pagination}",
      );
      return;
    }
    debugPrint("📄 DATA:");
    _prettyPrintJson(response.data);
  }

  PlatformOwnerService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("━━━━━━━━━━━━━━ 📤 PLATFORM OWNER REQUEST ━━━━━━━━━━━━━━");
          debugPrint("➡️ METHOD: ${options.method}");
          debugPrint("🌍 URL: ${options.uri}");
          debugPrint("🧾 HEADERS: ${options.headers}");
          debugPrint("🔎 QUERY PARAMS: ${options.queryParameters}");
          debugPrint("📦 BODY: ${options.data}");
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint("━━━━━━━━━━━━━━ ✅ PLATFORM OWNER RESPONSE ━━━━━━━━━━━━━━");
          debugPrint("✅ STATUS CODE: ${response.statusCode}");
          debugPrint("🌍 URL: ${response.requestOptions.uri}");
          _logResponseData(response);
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("━━━━━━━━━━━━━━ ❌ PLATFORM OWNER ERROR ━━━━━━━━━━━━━━");
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

          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
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

  /// Get Dashboard Statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [GET DASHBOARD STATS]");

      final response = await _dio.get(
        '/api/platform/dashboard/stats',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [DASHBOARD STATS SUCCESS]");
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [DASHBOARD STATS ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch dashboard stats',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get All Companies
  Future<Map<String, dynamic>> getAllCompanies({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (isActive != null) {
        queryParams['isActive'] = isActive;
      }

      debugPrint("📤 [GET ALL COMPANIES] Page: $page, Limit: $limit");

      final response = await _dio.get(
        '/api/platform/companies',
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [GET ALL COMPANIES SUCCESS]");
      return {
        'success': true,
        'data': response.data['data'],
        'pagination': response.data['pagination'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [GET ALL COMPANIES ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch companies',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get Company Usage Details
  Future<Map<String, dynamic>> getCompanyUsage(String companyId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [GET COMPANY USAGE] Company ID: $companyId");

      final response = await _dio.get(
        '/api/platform/companies/$companyId/usage',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [GET COMPANY USAGE SUCCESS]");
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [GET COMPANY USAGE ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch company usage',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get Pending Products
  Future<Map<String, dynamic>> getPendingProducts({
    int page = 1,
    int limit = 20,
    String? companyName,
    String? category,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (companyName != null && companyName.isNotEmpty) {
        queryParams['companyName'] = companyName;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      debugPrint("📤 [GET PENDING PRODUCTS] Page: $page, Limit: $limit");

      final response = await _dio.get(
        '/api/platform/products/pending',
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [GET PENDING PRODUCTS SUCCESS]");
      return {
        'success': true,
        'data': response.data['data'],
        'pagination': response.data['pagination'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [GET PENDING PRODUCTS ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch pending products',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Approve Product
  Future<Map<String, dynamic>> approveProduct(
    String productId, {
    String? notes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      final requestData = <String, dynamic>{};
      if (notes != null && notes.isNotEmpty) {
        requestData['notes'] = notes;
      }

      debugPrint("📤 [APPROVE PRODUCT] Product ID: $productId");

      final response = await _dio.patch(
        '/api/platform/products/$productId/approve',
        data: requestData,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [APPROVE PRODUCT SUCCESS]");
      return {
        'success': true,
        'message': response.data['message'] ?? 'Product approved successfully',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [APPROVE PRODUCT ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to approve product',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Reject Product
  Future<Map<String, dynamic>> rejectProduct(
    String productId, {
    required String reason,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      if (reason.isEmpty) {
        return {
          'success': false,
          'message': 'Rejection reason is required',
        };
      }

      debugPrint("📤 [REJECT PRODUCT] Product ID: $productId");

      final response = await _dio.patch(
        '/api/platform/products/$productId/reject',
        data: {'reason': reason},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [REJECT PRODUCT SUCCESS]");
      return {
        'success': true,
        'message': response.data['message'] ?? 'Product rejected',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [REJECT PRODUCT ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to reject product',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Create Global Product
  Future<Map<String, dynamic>> createGlobalProduct({
    required String name,
    required String category,
    String? subCategory,
    String? description,
    String? imagePath,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [CREATE GLOBAL PRODUCT] Name: $name, Category: $category");

      FormData formData = FormData.fromMap({
        'name': name,
        'category': category,
        'isGlobal': true,
        if (subCategory != null && subCategory.isNotEmpty)
          'subCategory': subCategory,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (imagePath != null && imagePath.isNotEmpty)
          'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(
        '/api/platform/products/global',
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      debugPrint("✅ [CREATE GLOBAL PRODUCT SUCCESS]");
      return {
        'success': true,
        'message': response.data['message'] ?? 'Global product created successfully',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [CREATE GLOBAL PRODUCT ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to create global product',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Check if user is platform owner
  Future<bool> isPlatformOwner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool("isPlatformOwner") ?? false;
    } catch (e) {
      debugPrint("⚠️ [CHECK PLATFORM OWNER ERROR] => $e");
      return false;
    }
  }

  /// Save platform owner status
  Future<void> savePlatformOwnerStatus(bool status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isPlatformOwner", status);
      debugPrint("✅ [PLATFORM OWNER STATUS SAVED] => $status");
    } catch (e) {
      debugPrint("⚠️ [SAVE PLATFORM OWNER STATUS ERROR] => $e");
    }
  }

  /// Get Platform Overview (Analytics)
  Future<Map<String, dynamic>> getPlatformOverview() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [GET PLATFORM OVERVIEW]");

      final response = await _dio.get(
        '/api/platform/stats/overview',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [PLATFORM OVERVIEW SUCCESS]");
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [PLATFORM OVERVIEW ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch platform overview',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get All Products
  Future<Map<String, dynamic>> getAllProducts({
    int page = 1,
    int limit = 20,
    String? status,
    String? companyName,
    String? category,
    bool? isGlobal,
    String? search,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (companyName != null && companyName.isNotEmpty) {
        queryParams['companyName'] = companyName;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      if (isGlobal != null) {
        queryParams['isGlobal'] = isGlobal;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      debugPrint("📤 [GET ALL PRODUCTS] Page: $page, Limit: $limit");

      final response = await _dio.get(
        '/api/platform/products/all',
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [GET ALL PRODUCTS SUCCESS]");
      return {
        'success': true,
        'data': response.data['data'],
        'stats': response.data['stats'],
        'pagination': response.data['pagination'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [GET ALL PRODUCTS ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch products',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get Product Details
  Future<Map<String, dynamic>> getProductDetails(String productId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [GET PRODUCT DETAILS] Product ID: $productId");

      final response = await _dio.get(
        '/api/platform/products/$productId',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [GET PRODUCT DETAILS SUCCESS]");
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [GET PRODUCT DETAILS ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch product details',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get Company Profile
  Future<Map<String, dynamic>> getCompanyProfile(String companyId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      debugPrint("📤 [GET COMPANY PROFILE] Company ID: $companyId");

      final response = await _dio.get(
        '/api/platform/companies/$companyId/profile',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [GET COMPANY PROFILE SUCCESS]");
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [GET COMPANY PROFILE ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch company profile',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// ========== MATERIAL MANAGEMENT ENDPOINTS ==========

  /// Get Pending Materials
  Future<Map<String, dynamic>> getPendingMaterials({
    int page = 1,
    int limit = 20,
    String? companyName,
    String? category,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final queryParams = {
        'page': page,
        'limit': limit,
        if (companyName != null) 'companyName': companyName,
        if (category != null) 'category': category,
      };

      debugPrint("📤 [GET PENDING MATERIALS] Query: $queryParams");

      final response = await _dio.get(
        '/api/platform/materials/pending',
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [PENDING MATERIALS SUCCESS]");
      return {
        'success': true,
        'data': response.data['data'],
        'pagination': response.data['pagination'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [PENDING MATERIALS ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch pending materials',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Approve Material
  Future<Map<String, dynamic>> approveMaterial(
    String materialId, {
    String? notes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      debugPrint("📤 [APPROVE MATERIAL] ID: $materialId");

      final response = await _dio.patch(
        '/api/platform/materials/$materialId/approve',
        data: {
          if (notes != null) 'notes': notes,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [APPROVE MATERIAL SUCCESS]");
      return {
        'success': true,
        'message': response.data['message'] ?? 'Material approved successfully',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [APPROVE MATERIAL ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to approve material',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Reject Material
  Future<Map<String, dynamic>> rejectMaterial(
    String materialId, {
    required String reason,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      debugPrint("📤 [REJECT MATERIAL] ID: $materialId");

      final response = await _dio.patch(
        '/api/platform/materials/$materialId/reject',
        data: {
          'reason': reason,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [REJECT MATERIAL SUCCESS]");
      return {
        'success': true,
        'message': response.data['message'] ?? 'Material rejected successfully',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [REJECT MATERIAL ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to reject material',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Create Global Material
  Future<Map<String, dynamic>> createGlobalMaterial({
    required String name,
    required String category,
    String? imagePath,
    double? standardWidth,
    double? standardLength,
    String? standardUnit,
    double? pricePerSqm,
    double? pricePerUnit,
    String? pricingUnit,
    List<Map<String, dynamic>>? types,
    List<Map<String, dynamic>>? commonThicknesses,
    List<Map<String, dynamic>>? foamVariants,
    List<Map<String, dynamic>>? sizeVariants,
    double? wasteThreshold,
    String? notes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      debugPrint("📤 [CREATE GLOBAL MATERIAL] Name: $name");

      final formPayload = <String, dynamic>{
        'name': name,
        'category': category,
        'isGlobal': true,
      };

      if (standardWidth != null) formPayload['standardWidth'] = standardWidth;
      if (standardLength != null) formPayload['standardLength'] = standardLength;
      if (standardUnit != null) formPayload['standardUnit'] = standardUnit;
      if (pricePerSqm != null) formPayload['pricePerSqm'] = pricePerSqm;
      if (pricePerUnit != null) formPayload['pricePerUnit'] = pricePerUnit;
      if (pricingUnit != null) formPayload['pricingUnit'] = pricingUnit;
      if (wasteThreshold != null) formPayload['wasteThreshold'] = wasteThreshold;
      if (notes != null) formPayload['notes'] = notes;

      if (types != null) formPayload['types'] = jsonEncode(types);
      if (commonThicknesses != null) {
        formPayload['commonThicknesses'] = jsonEncode(commonThicknesses);
      }
      if (foamVariants != null) formPayload['foamVariants'] = jsonEncode(foamVariants);
      if (sizeVariants != null) formPayload['sizeVariants'] = jsonEncode(sizeVariants);

      if (imagePath != null && imagePath.isNotEmpty) {
        formPayload['image'] = await MultipartFile.fromFile(imagePath);
      }

      final response = await _dio.post(
        '/api/product/creatematerial',
        data: FormData.fromMap(formPayload),
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      debugPrint("✅ [CREATE GLOBAL MATERIAL SUCCESS]");
      return {
        'success': true,
        'message': response.data['message'] ?? 'Global material created successfully',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint("⚠️ [CREATE GLOBAL MATERIAL ERROR] => ${e.response?.data ?? e.message}");
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to create global material',
      };
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get materials for material update workflows.
  Future<Map<String, dynamic>> getDatabaseMaterials({
    int page = 1,
    int limit = 50,
    String? companyName,
    String? category,
    String? status,
    String? search,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (companyName != null && companyName.trim().isNotEmpty)
          'companyName': companyName.trim(),
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
        if (status != null && status.trim().isNotEmpty)
          'status': status.trim(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      debugPrint("📤 [GET DATABASE MATERIALS] Query: $queryParams");

      final response = await _dio.get(
        '/api/database/materials',
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final payload = response.data['data'] ?? {};
      final rows = (payload['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DatabaseMaterial.fromJson)
          .toList();

      return {
        'success': true,
        'message': response.data['message'] ?? 'Materials fetched successfully',
        'data': rows,
        'pagination': payload['pagination'] ?? {},
      };
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [GET DATABASE MATERIALS ERROR] => ${e.response?.data ?? e.message}",
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

  /// Update a material price for any company through the database endpoint.
  Future<Map<String, dynamic>> updateCompanyMaterialPrice({
    required String materialId,
    double? pricePerSqm,
    double? pricePerUnit,
    String? pricingUnit,
    bool showDialogs = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final body = <String, dynamic>{
        if (pricePerSqm != null) 'pricePerSqm': pricePerSqm,
        if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
        if (pricingUnit != null && pricingUnit.trim().isNotEmpty)
          'pricingUnit': pricingUnit.trim(),
      };

      if (body.isEmpty) {
        return {
          'success': false,
          'message': 'No material price changes provided',
        };
      }

      debugPrint(
        "📤 [UPDATE COMPANY MATERIAL PRICE] ID: $materialId BODY: $body",
      );

      final response = await _dio.put(
        '/api/database/materials/$materialId',
        data: body,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          extra: {
            'showSuccessDialog': showDialogs,
            'showErrorDialog': showDialogs,
          },
        ),
      );

      return {
        'success': response.data['success'] == true,
        'message': response.data['message'] ?? 'Material updated successfully',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [UPDATE COMPANY MATERIAL PRICE ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? 'Failed to update material price',
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
