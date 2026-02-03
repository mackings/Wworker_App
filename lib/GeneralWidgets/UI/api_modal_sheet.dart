import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';

class ApiFeedbackInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['success'] == true;
      final message = data['message']?.toString().trim();
      if (success && message != null && message.isNotEmpty) {
        ApiModalSheet.showSuccess(message);
      } else if (!success && message != null && message.isNotEmpty) {
        ApiModalSheet.showError(message);
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final responseData = err.response?.data;
    String message = err.message ?? 'Something went wrong';
    if (responseData is Map<String, dynamic>) {
      message = responseData['message']?.toString() ?? message;
    }
    ApiModalSheet.showError(message);
    handler.next(err);
  }
}

class ApiModalSheet {
  static bool _isShowing = false;
  static DateTime? _lastShownAt;
  static String? _lastMessage;

  static Future<void> showSuccess(String message) async {
    await _show(
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF2E7D32),
      title: 'Success',
    );
  }

  static Future<void> showError(String message) async {
    await _show(
      message: message,
      icon: Icons.error_rounded,
      iconColor: const Color(0xFFC62828),
      title: 'Error',
    );
  }

  static Future<void> _show({
    required String message,
    required IconData icon,
    required Color iconColor,
    required String title,
  }) async {
    final context = Nav.navigatorKey.currentContext;
    if (context == null) return;

    final now = DateTime.now();
    if (_isShowing) return;
    if (_lastMessage == message &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!).inMilliseconds < 900) {
      return;
    }

    _isShowing = true;
    _lastMessage = message;
    _lastShownAt = now;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Container(
            decoration: BoxDecoration(
              color: ColorsApp.bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
                bottom: Radius.circular(20),
              ),
              border: Border.all(color: ColorsApp.btnColor.withOpacity(0.25)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: iconColor, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: ColorsApp.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                          color: ColorsApp.btnColor,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        message,
                        style: TextStyle(
                          color: ColorsApp.textColor.withOpacity(0.85),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    _isShowing = false;
  }
}
