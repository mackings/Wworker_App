import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Settings/Model/company_settings_model.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';

class CompanySettingsService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  CompanySettingsService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Log settings requests for visibility
          debugPrint(
            "📤 [SETTINGS REQUEST] ${options.method} ${options.uri} ${options.data ?? ''}",
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            "✅ [SETTINGS RESPONSE] ${response.statusCode} ${response.requestOptions.uri}",
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint(
            "❌ [SETTINGS ERROR] ${e.response?.statusCode ?? ''} ${e.requestOptions.uri} ${e.message}",
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

  Future<CompanySettings?> getSettings() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await _dio.get(
        "/api/settings",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.data?["success"] == true) {
        return CompanySettings.fromJson(response.data["data"]);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> updates) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await _dio.put(
        "/api/settings",
        data: updates,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data?["success"] == true;
    } on DioException {
      return false;
    }
  }
}
