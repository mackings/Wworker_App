import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';



class ProductService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  ProductService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint(
            "📤 [PRODUCT REQUEST] => ${options.method} ${options.uri}",
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            "✅ [PRODUCT RESPONSE] => ${response.statusCode} ${response.requestOptions.uri}",
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("❌ [PRODUCT ERROR] => ${e.requestOptions.uri}");
          debugPrint("📛 [MESSAGE] => ${e.message}");
          return handler.next(e);
        },
      ),
    );
  
    _dio.interceptors.add(ApiFeedbackInterceptor());
  }



  Future<Map<String, dynamic>> getAllProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "message": "No auth token found"};
      }

      final response = await _dio.get(
        "/api/product/",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [HANDLE PRODUCT ERROR] => ${e.response?.data ?? e.message}",
      );
      return {
        "success": false,
        "message": e.response?.data?["message"] ?? e.message,
      };
    }
  }


}
