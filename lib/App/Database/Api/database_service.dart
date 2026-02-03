import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Database/Model/database_models.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';

class DatabaseService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  DatabaseService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint(
            "📤 [DATABASE REQUEST] ${options.method} ${options.uri} ${options.data ?? ''}",
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            "✅ [DATABASE RESPONSE] ${response.statusCode} ${response.requestOptions.uri}",
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint(
            "❌ [DATABASE ERROR] ${e.response?.statusCode ?? ''} ${e.requestOptions.uri} ${e.message}",
          );
          return handler.next(e);
        },
      ),
    );
  
    _dio.interceptors.add(RetryTwiceInterceptor(_dio));
    _dio.interceptors.add(ApiFeedbackInterceptor());
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<List<DatabaseQuotation>> getQuotations({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await _dio.get(
      "/api/database/quotations",
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (response.data?["success"] == true) {
      final data = response.data["data"]?["data"] as List<dynamic>? ?? [];
      return data
          .map((item) => DatabaseQuotation.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<bool> updateQuotation(String id, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.put(
      "/api/database/quotations/$id",
      data: body,
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<bool> deleteQuotation(String id) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.delete(
      "/api/database/quotations/$id",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<List<DatabaseBom>> getBoms({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await _dio.get(
      "/api/database/boms",
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (response.data?["success"] == true) {
      final data = response.data["data"]?["data"] as List<dynamic>? ?? [];
      return data.map((item) => DatabaseBom.fromJson(item)).toList();
    }
    return [];
  }

  Future<bool> updateBom(String id, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.put(
      "/api/database/boms/$id",
      data: body,
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<bool> deleteBom(String id) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.delete(
      "/api/database/boms/$id",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<List<DatabaseClient>> getClients() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await _dio.get(
      "/api/database/clients",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (response.data?["success"] == true) {
      final data = response.data["data"] as List<dynamic>? ?? [];
      return data.map((item) => DatabaseClient.fromJson(item)).toList();
    }
    return [];
  }

  Future<bool> updateClient({
    required Map<String, dynamic> match,
    required Map<String, dynamic> update,
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.put(
      "/api/database/clients",
      data: {'match': match, 'update': update},
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<bool> deleteClient({
    required Map<String, dynamic> match,
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.delete(
      "/api/database/clients",
      data: {'match': match},
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<List<DatabaseStaff>> getStaff() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await _dio.get(
      "/api/database/staff",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (response.data?["success"] == true) {
      final data = response.data["data"] as List<dynamic>? ?? [];
      return data.map((item) => DatabaseStaff.fromJson(item)).toList();
    }
    return [];
  }

  Future<bool> updateStaff({
    required String userId,
    required Map<String, dynamic> body,
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.put(
      "/api/database/staff/$userId",
      data: body,
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<List<DatabaseInvoice>> getInvoices({
    int page = 1,
    int limit = 50,
    String? search,
    String? status,
    String? paymentStatus,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await _dio.get(
      "/api/database/invoices",
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (paymentStatus != null && paymentStatus.trim().isNotEmpty)
          'paymentStatus': paymentStatus.trim(),
      },
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (response.data?["success"] == true) {
      final data = response.data["data"]?["data"] as List<dynamic>? ?? [];
      return data.map((item) => DatabaseInvoice.fromJson(item)).toList();
    }
    return [];
  }

  Future<bool> updateInvoice(String id, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.put(
      "/api/database/invoices/$id",
      data: body,
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<bool> deleteInvoice(String id) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.delete(
      "/api/database/invoices/$id",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<List<DatabaseReceipt>> getReceipts({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await _dio.get(
      "/api/database/receipts",
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (response.data?["success"] == true) {
      final data = response.data["data"]?["data"] as List<dynamic>? ?? [];
      return data.map((item) => DatabaseReceipt.fromJson(item)).toList();
    }
    return [];
  }

  Future<bool> updateReceipt(String id, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.put(
      "/api/database/receipts/$id",
      data: body,
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<bool> deleteReceipt(String id) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.delete(
      "/api/database/receipts/$id",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<bool> deleteStaff(String userId) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.delete(
      "/api/database/staff/$userId",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<List<DatabaseProduct>> getProducts({
    int page = 1,
    int limit = 50,
    String? search,
    String? category,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await _dio.get(
      "/api/database/products",
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
      },
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (response.data?["success"] == true) {
      final data = response.data["data"]?["data"] as List<dynamic>? ?? [];
      return data.map((item) => DatabaseProduct.fromJson(item)).toList();
    }
    return [];
  }

  Future<bool> updateProduct({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.put(
      "/api/database/products/$id",
      data: body,
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<bool> deleteProduct(String id) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.delete(
      "/api/database/products/$id",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }

  Future<List<DatabaseMaterial>> getMaterials({
    int page = 1,
    int limit = 50,
    String? search,
    String? category,
    String? status,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await _dio.get(
      "/api/database/materials",
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (response.data?["success"] == true) {
      final data = response.data["data"]?["data"] as List<dynamic>? ?? [];
      return data.map((item) => DatabaseMaterial.fromJson(item)).toList();
    }
    return [];
  }

  Future<bool> updateMaterial({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      debugPrint(
        "📦 [DATABASE MATERIAL UPDATE BODY] /api/database/materials/$id $body",
      );

      final response = await _dio.put(
        "/api/database/materials/$id",
        data: body,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data?["success"] == true;
    } on DioException catch (e) {
      debugPrint(
        "❌ [DATABASE MATERIAL UPDATE ERROR] ${e.response?.statusCode ?? ''} ${e.requestOptions.uri} ${e.response?.data ?? e.message}",
      );
      return false;
    }
  }

  Future<bool> deleteMaterial(String id) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _dio.delete(
      "/api/database/materials/$id",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data?["success"] == true;
  }
}
