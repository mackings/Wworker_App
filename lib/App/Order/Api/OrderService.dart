import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';

class OrderService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  OrderService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("📤 [ORDER REQUEST]");
          debugPrint("➡️ URL: ${options.uri}");
          debugPrint("🧾 METHOD: ${options.method}");
          debugPrint("📋 HEADERS: ${options.headers}");
          if (options.queryParameters.isNotEmpty) {
            debugPrint("🔍 QUERY PARAMS: ${options.queryParameters}");
          }
          if (options.data != null) {
            debugPrint("📦 BODY: ${options.data}");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint("✅ [ORDER RESPONSE]");
          debugPrint("🔢 STATUS CODE: ${response.statusCode}");
          debugPrint("📍 URL: ${response.requestOptions.uri}");
          debugPrint("📄 DATA: ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("❌ [ORDER ERROR]");
          debugPrint("📍 URL: ${e.requestOptions.uri}");
          debugPrint("📛 MESSAGE: ${e.message}");
          if (e.response != null) {
            debugPrint("🔢 STATUS CODE: ${e.response?.statusCode}");
            debugPrint("📄 RESPONSE DATA: ${e.response?.data}");
          }
          if (e.requestOptions.data != null) {
            debugPrint("📦 REQUEST BODY: ${e.requestOptions.data}");
          }
          return handler.next(e);
        },
      ),
    );
  
    _dio.interceptors.add(ApiFeedbackInterceptor());
  }

  // 🟢 CREATE ORDER FROM QUOTATION
  Future<Map<String, dynamic>> createOrderFromQuotation({
    required String quotationId,
    required String startDate,
    required String endDate,
    List<String>? bomIds,
    String? notes,
    double amountPaid = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint(
        "📤 [CREATE ORDER] => POST ${Urls.baseUrl}/api/orders/create",
      );

      final response = await _dio.post(
        "/api/orders/create",
        data: {
          "quotationId": quotationId,
          "startDate": startDate,
          "endDate": endDate,
          if (bomIds != null && bomIds.isNotEmpty) "bomIds": bomIds,
          if (notes != null) "notes": notes,
          "amountPaid": amountPaid,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
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
    String? assignedTo,
    bool showMyAssignments = false,
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
        if (assignedTo != null) 'assignedTo': assignedTo,
        if (showMyAssignments) 'showMyAssignments': showMyAssignments,
      };

      debugPrint("📤 [GET ORDERS] => GET ${Urls.baseUrl}/api/orders/get-orders");

      final response = await _dio.get(
        "/api/orders/get-orders",
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
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

      debugPrint(
        "📤 [GET ORDER] => GET ${Urls.baseUrl}/api/orders/get-orders/$orderId",
      );

      final response = await _dio.get(
        "/api/orders/get-orders/$orderId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
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

      // 👇 Convert 100.0 → 100 if it has no decimal part
      final dynamic formattedAmount = amount % 1 == 0 ? amount.toInt() : amount;

      debugPrint(
        "📤 [ADD PAYMENT] => POST ${Urls.baseUrl}/api/orders/orders/$orderId/payment",
      );

      final response = await _dio.post(
        "/api/orders/orders/$orderId/payment",
        data: {
          "amount": formattedAmount,
          "paymentMethod": paymentMethod,
          if (reference != null) "reference": reference,
          if (notes != null) "notes": notes,
          if (paymentDate != null) "paymentDate": paymentDate,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
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

      debugPrint(
        "📤 [UPDATE STATUS] => PATCH ${Urls.baseUrl}/api/sales/orders/$orderId/status",
      );

      final response = await _dio.patch(
        "/api/sales/orders/$orderId/status",
        data: {"status": status},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [UPDATE STATUS SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [UPDATE STATUS ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        "success": false,
        "message":
            e.response?.data?["message"] ?? "Failed to update order status",
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

      debugPrint(
        "📤 [GET RECEIPT] => GET ${Urls.baseUrl}/api/sales/orders/$orderId/receipt",
      );

      final response = await _dio.get(
        "/api/sales/orders/$orderId/receipt",
        options: Options(headers: {"Authorization": "Bearer $token"}),
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

      debugPrint(
        "📤 [DELETE ORDER] => DELETE ${Urls.baseUrl}/api/sales/orders/$orderId",
      );

      final response = await _dio.delete(
        "/api/sales/orders/$orderId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
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

      debugPrint(
        "📤 [GET STATS] => GET ${Urls.baseUrl}/api/sales/orders/stats",
      );

      final response = await _dio.get(
        "/api/sales/orders/stats",
        options: Options(headers: {"Authorization": "Bearer $token"}),
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

  // 🟢 GET AVAILABLE STAFF FOR ASSIGNMENT
  Future<Map<String, dynamic>> getAvailableStaff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint(
        "📤 [GET AVAILABLE STAFF] => GET ${Urls.baseUrl}/api/staff/available",
      );

      final response = await _dio.get(
        "/api/orders/staff/available",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [GET AVAILABLE STAFF SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [GET AVAILABLE STAFF ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to fetch staff",
        "data": [],
      };
    }
  }

  // 🟢 ASSIGN ORDER TO STAFF
  Future<Map<String, dynamic>> assignOrderToStaff({
    required String orderId,
    required String staffId,
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint(
        "📤 [ASSIGN ORDER] => POST ${Urls.baseUrl}/api/sales/orders/$orderId/assign",
      );

      final response = await _dio.post(
        "/api/orders/$orderId/assign",
        data: {
          "staffId": staffId,
          if (notes != null) "notes": notes,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [ASSIGN ORDER SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [ASSIGN ORDER ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to assign order",
      };
    }
  }

  // 🟢 UNASSIGN ORDER FROM STAFF
  Future<Map<String, dynamic>> unassignOrderFromStaff({
    required String orderId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint(
        "📤 [UNASSIGN ORDER] => POST ${Urls.baseUrl}/api/sales/orders/$orderId/unassign",
      );

      final response = await _dio.post(
        "/api/orders/$orderId/unassign",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [UNASSIGN ORDER SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [UNASSIGN ORDER ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to unassign order",
      };
    }
  }
}
