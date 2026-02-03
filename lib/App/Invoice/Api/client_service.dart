import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Invoice/Model/Client_model.dart';
import 'package:wworker/App/Invoice/Model/invoiceModel.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';




class ClientService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  ClientService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("📤 [REQUEST] => ${options.method} ${options.uri}");
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
  
    _dio.interceptors.add(ApiFeedbackInterceptor());
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




  // 🟢 GET CLIENTS
  Future<List<ClientModel>> getClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) {
        throw Exception(companyError['message']);
      }

      final companyName = await _getCompanyName();
      debugPrint("🏢 [COMPANY] => $companyName");

      debugPrint("📤 [REQUEST] => GET ${Urls.baseUrl}/api/sales/get-clients");

      final response = await _dio.get(
        "/api/sales/get-clients",
        options: Options(headers: {"Authorization": "Bearer $token"}),
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





  // 🟢 CREATE INVOICE FROM QUOTATION WITH PDF ATTACHMENT
  Future<Map<String, dynamic>> createInvoice({
    required String quotationId,
    String? dueDate,
    String? notes,
    double amountPaid = 0,
    File? pdfFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) return companyError;

      // ✅ Get company name
      final companyName = await _getCompanyName();
      debugPrint("🏢 [COMPANY] => $companyName");

      debugPrint("📤 [REQUEST] => POST ${Urls.baseUrl}/api/invoices/create");

      // Create FormData for multipart request with company name
      FormData formData = FormData.fromMap({
        "quotationId": quotationId,
        "companyName": companyName, // ✅ Add company name
        if (dueDate != null) "dueDate": dueDate,
        if (notes != null) "notes": notes,
        "amountPaid": amountPaid,
        if (pdfFile != null)
          "invoicePdf": await MultipartFile.fromFile(
            pdfFile.path,
            filename: "invoice_${DateTime.now().millisecondsSinceEpoch}.pdf",
          ),
      });

      final response = await _dio.post(
        "/api/invoices/create",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      debugPrint("✅ [CREATE INVOICE SUCCESS] => ${response.data}");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [CREATE INVOICE ERROR] => ${e.response?.data ?? e.message}",
      );
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

      // ✅ Validate company
      final companyError = await _validateCompany();
      if (companyError != null) {
        throw Exception(companyError['message']);
      }

      final companyName = await _getCompanyName();
      debugPrint("🏢 [COMPANY] => $companyName");

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