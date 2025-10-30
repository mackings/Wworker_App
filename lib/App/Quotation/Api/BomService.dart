
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/Constant/urls.dart';



class BOMService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  BOMService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint("📤 [REQUEST] => ${options.method} ${options.uri}");
        debugPrint("📦 [DATA] => ${options.data}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint("✅ [RESPONSE] => ${response.statusCode} ${response.requestOptions.uri}");
        debugPrint("📥 [DATA] => ${response.data}");
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



// 🟢 1️⃣ CREATE BOM (Materials)
// 🟢 1️⃣ CREATE BOM (Materials)
Future<Map<String, dynamic>> createBOM({
  required String name,
  required String description,
  required String productId,  // ✅ Added required productId
  required List<Map<String, dynamic>> materials,
  List<Map<String, dynamic>>? additionalCosts,  // ✅ Optional additionalCosts
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      return {"success": false, "message": "No auth token found"};
    }

    final body = {
      "name": name,
      "description": description,
      "productId": productId,  // ✅ Added productId to request body
      "materials": materials,
      if (additionalCosts != null && additionalCosts.isNotEmpty)
        "additionalCosts": additionalCosts,  // ✅ Include if provided
    };

    print("📤 [REQUEST] => POST ${_dio.options.baseUrl}/api/bom/");
    print("📦 [DATA] => $body");

    final response = await _dio.post(
      "/api/bom/",
      data: body,
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    print("✅ [RESPONSE] => ${response.data}");

    return response.data;
  } on DioException catch (e) {
    print("❌ [ERROR] => ${e.response?.data ?? e.message}");
    return _handleError(e);
  }
}




  // 🟢 2️⃣ ADD ADDITIONAL COSTS TO BOM
  Future<Map<String, dynamic>> addAdditionalCost({
    required String bomId,
    required List<Map<String, dynamic>> additionalCosts,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      // Loop and post each additional cost
      Map<String, dynamic> lastResponse = {};
      for (final cost in additionalCosts) {
        final response = await _dio.post(
          "/api/bom/$bomId/additional-costs",
          data: cost,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );
        lastResponse = response.data;
      }

      return lastResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }





  // 🟢 3️⃣ GET ALL BOMs
Future<Map<String, dynamic>> getAllBOMs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      return {"success": false, "message": "No auth token found"};
    }

    final response = await _dio.get(
      "/api/bom/",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data;
  } on DioException catch (e) {
    return _handleError(e);
  }
}





// 🟢 4️⃣ CREATE QUOTATION
Future<Map<String, dynamic>> createQuotation({
  required String clientName,
  required String clientAddress,
  required String nearestBusStop,
  required String phoneNumber,
  required String email,
  required String description,
  required List<Map<String, dynamic>> items,
  required Map<String, dynamic> service,
  required double discount,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      return {"success": false, "message": "No auth token found"};
    }

    final body = {
      "clientName": clientName,
      "clientAddress": clientAddress,
      "nearestBusStop": nearestBusStop,
      "phoneNumber": phoneNumber,
      "email": email,
      "description": description,
      "items": items,
      "service": service,
      "discount": discount,
    };

    final response = await _dio.post(
      "/api/quotation",
      data: body,
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data;
  } on DioException catch (e) {
    return _handleError(e);
  }
}



  Map<String, dynamic> _handleError(DioException e) {
    debugPrint("⚠️ [HANDLE ERROR] => ${e.response?.data ?? e.message}");
    return {
      "success": false,
      "message": e.response?.data?["message"] ?? e.message,
    };
  }
}
