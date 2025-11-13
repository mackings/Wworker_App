import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/Constant/urls.dart';



class OrderService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  OrderService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint("📤 [ORDER REQUEST] => ${options.method} ${options.uri}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint("✅ [ORDER RESPONSE] => ${response.statusCode} ${response.requestOptions.uri}");
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        debugPrint("❌ [ORDER ERROR] => ${e.requestOptions.uri}");
        debugPrint("📛 [MESSAGE] => ${e.message}");
        if (e.response != null) {
          debugPrint("📄 [ERROR RESPONSE] => ${e.response?.data}");
        }
        return handler.next(e);
      },
    ));
  }

  // 🟢 CREATE ORDER FROM QUOTATION
  Future<Map<String, dynamic>> createOrderFromQuotation({
    required String quotationId,
    required String startDate,
    required String endDate,
    String? notes,
    double amountPaid = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint("📤 [CREATE ORDER] => POST ${Urls.baseUrl}/api/sales/orders/create");

      final response = await _dio.post(
        "/api/sales/orders/create",
        data: {
          "quotationId": quotationId,
          "startDate": startDate,
          "endDate": endDate,
          if (notes != null) "notes": notes,
          "amountPaid": amountPaid,
        },
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      debugPrint("✅ [CREATE ORDER SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [CREATE ORDER ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to create order",
      };
    }
  }

  // 🟢 GET ALL ORDERS
  Future<Map<String, dynamic>> getAllOrders({
    int page = 1,
    int limit = 10,
    String? status,
    String? paymentStatus,
    String? search,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (search != null) 'search': search,
      };

      debugPrint("📤 [GET ORDERS] => GET ${Urls.baseUrl}/api/sales/orders");

      final response = await _dio.get(
        "/api/sales/orders",
        queryParameters: queryParams,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      debugPrint("✅ [GET ORDERS SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [GET ORDERS ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to fetch orders",
        "data": {"orders": [], "pagination": {}},
      };
    }
  }

  // 🟢 GET SINGLE ORDER
  Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint("📤 [GET ORDER] => GET ${Urls.baseUrl}/api/sales/orders/$orderId");

      final response = await _dio.get(
        "/api/sales/orders/$orderId",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      debugPrint("✅ [GET ORDER SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [GET ORDER ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to fetch order",
      };
    }
  }

  // 🟢 ADD PAYMENT TO ORDER
  Future<Map<String, dynamic>> addPayment({
    required String orderId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
    String? paymentDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint("📤 [ADD PAYMENT] => POST ${Urls.baseUrl}/api/sales/orders/$orderId/payment");

      final response = await _dio.post(
        "/api/sales/orders/$orderId/payment",
        data: {
          "amount": amount,
          "paymentMethod": paymentMethod,
          if (reference != null) "reference": reference,
          if (notes != null) "notes": notes,
          if (paymentDate != null) "paymentDate": paymentDate,
        },
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      debugPrint("✅ [ADD PAYMENT SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [ADD PAYMENT ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to add payment",
      };
    }
  }

  // 🟢 UPDATE ORDER STATUS
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint("📤 [UPDATE STATUS] => PATCH ${Urls.baseUrl}/api/sales/orders/$orderId/status");

      final response = await _dio.patch(
        "/api/sales/orders/$orderId/status",
        data: {"status": status},
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      debugPrint("✅ [UPDATE STATUS SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [UPDATE STATUS ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to update order status",
      };
    }
  }

  // 🟢 GET ORDER RECEIPT
  Future<Map<String, dynamic>> getOrderReceipt(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint("📤 [GET RECEIPT] => GET ${Urls.baseUrl}/api/sales/orders/$orderId/receipt");

      final response = await _dio.get(
        "/api/sales/orders/$orderId/receipt",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      debugPrint("✅ [GET RECEIPT SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [GET RECEIPT ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to fetch receipt",
      };
    }
  }

  // 🟢 DELETE ORDER
  Future<Map<String, dynamic>> deleteOrder(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint("📤 [DELETE ORDER] => DELETE ${Urls.baseUrl}/api/sales/orders/$orderId");

      final response = await _dio.delete(
        "/api/sales/orders/$orderId",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      debugPrint("✅ [DELETE ORDER SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [DELETE ORDER ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to delete order",
      };
    }
  }

  // 🟢 GET ORDER STATISTICS
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint("📤 [GET STATS] => GET ${Urls.baseUrl}/api/sales/orders/stats");

      final response = await _dio.get(
        "/api/sales/orders/stats",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      debugPrint("✅ [GET STATS SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [GET STATS ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to fetch statistics",
      };
    }
  }
}