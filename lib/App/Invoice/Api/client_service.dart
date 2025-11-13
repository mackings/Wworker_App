import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Invoice/Model/Client_model.dart';
import 'package:wworker/App/Invoice/Model/invoiceModel.dart';
import 'package:wworker/Constant/urls.dart';



class ClientService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  ClientService() {
    _dio.interceptors.add(InterceptorsWrapper(
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
    ));
  }

  // 🟢 GET CLIENTS
  Future<List<ClientModel>> getClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint("📤 [REQUEST] => GET ${Urls.baseUrl}/api/sales/get-clients");

      final response = await _dio.get(
        "/api/sales/get-clients",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      final data = response.data;

      if (data["success"] == true && data["data"] is List) {
        final clients = (data["data"] as List)
            .map((json) => ClientModel.fromJson(json))
            .toList();
        return clients;
      } else {
        return [];
      }
    } on DioException catch (e) {
      debugPrint("⚠️ [GET CLIENTS ERROR] => ${e.response?.data ?? e.message}");
      return [];
    }
  }

  // 🟢 CREATE INVOICE FROM QUOTATION
  Future<Map<String, dynamic>> createInvoice({
    required String quotationId,
    String? dueDate,
    String? notes,
    double amountPaid = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint("📤 [REQUEST] => POST ${Urls.baseUrl}/api/invoices/create");

      final response = await _dio.post(
        "/api/invoices/create",
        data: {
          "quotationId": quotationId,
          if (dueDate != null) "dueDate": dueDate,
          if (notes != null) "notes": notes,
          "amountPaid": amountPaid,
        },
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      debugPrint("✅ [CREATE INVOICE SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint("⚠️ [CREATE INVOICE ERROR] => ${e.response?.data ?? e.message}");
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? "Failed to create invoice",
      };
    }
  }


  // 🟢 GET INVOICES
Future<List<InvoiceModel>> getInvoices() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      throw Exception("No auth token found");
    }

    debugPrint("📤 [REQUEST] => GET ${Urls.baseUrl}/api/invoices/invoices");

    final response = await _dio.get(
      "/api/invoices/invoices",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    final data = response.data;

    if (data["success"] == true && data["data"]?["invoices"] is List) {
      final invoices = (data["data"]["invoices"] as List)
          .map((json) => InvoiceModel.fromJson(json))
          .toList();
      return invoices;
    } else {
      return [];
    }
  } on DioException catch (e) {
    debugPrint("⚠️ [GET INVOICES ERROR] => ${e.response?.data ?? e.message}");
    return [];
  }
}


}
