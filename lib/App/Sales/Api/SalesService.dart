import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Sales/Model/SalesModel.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';

class SalesService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://ww-backend.vercel.app'));

  SalesService() {
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

  /// Get sales analytics
  /// [period] can be: daily, weekly, monthly, yearly
  Future<SalesAnalyticsResponse?> getSalesAnalytics({
    String period = 'daily',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      final queryParams = <String, dynamic>{'period': period};

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      debugPrint("📤 [REQUEST] => GET /api/sales/get-sales");
      debugPrint("📦 [PARAMS] => $queryParams");

      final response = await _dio.get(
        '/api/sales/get-sales',
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [SALES ANALYTICS SUCCESS] => ${response.data}");
      return SalesAnalyticsResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [SALES ANALYTICS ERROR] => ${e.response?.data ?? e.message}",
      );
      return null;
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return null;
    }
  }

  /// Get inventory status
  Future<InventoryResponse?> getInventoryStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No auth token found");
      }

      debugPrint("📤 [REQUEST] => GET /api/sales/get-inventory");

      final response = await _dio.get(
        '/api/sales/get-inventory',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [INVENTORY STATUS SUCCESS] => ${response.data}");
      return InventoryResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(
        "⚠️ [INVENTORY STATUS ERROR] => ${e.response?.data ?? e.message}",
      );
      return null;
    } catch (e) {
      debugPrint("⚠️ [UNEXPECTED ERROR] => $e");
      return null;
    }
  }
}
