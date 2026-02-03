import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Auth/Api/AuthService.dart';
import 'package:wworker/App/Auth/View/Onboarding.dart';
import 'package:wworker/App/Auth/View/Signin.dart';
import 'package:wworker/App/Staffing/View/Selector.dart';
import 'package:wworker/GeneralWidgets/UI/DashConfig.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<Widget> _nextScreen;

  @override
  void initState() {
    super.initState();
    _nextScreen = _resolveNextScreen();
  }

  Future<Widget> _resolveNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      return const FirstOnboard();
    }

    final authService = AuthService();
    final me = await authService.getMe();

    if (me["success"] == true) {
      final dynamic data = me["data"];
      Map<String, dynamic> user = {};
      if (data is Map<String, dynamic>) {
        if (data["user"] is Map<String, dynamic>) {
          user = data["user"] as Map<String, dynamic>;
        } else {
          user = data;
        }
      } else if (data is Map) {
        user = Map<String, dynamic>.from(data);
        if (user["user"] is Map) {
          user = Map<String, dynamic>.from(user["user"] as Map);
        }
      }

      List<dynamic> companies = (user["companies"] as List?) ?? <dynamic>[];
      int currentIndex = user["activeCompanyIndex"] is int
          ? user["activeCompanyIndex"] as int
          : 0;

      // Some /me responses do not include company fields; keep using cached values.
      if (companies.isEmpty) {
        final cachedCompaniesRaw = prefs.getString("companies");
        if (cachedCompaniesRaw != null && cachedCompaniesRaw.isNotEmpty) {
          try {
            final decoded = jsonDecode(cachedCompaniesRaw);
            if (decoded is List) {
              companies = decoded;
              currentIndex = prefs.getInt("activeCompanyIndex") ?? 0;
            }
          } catch (_) {}
        }
      }

      if (companies.isNotEmpty) {
        return CompanySelectionScreen(
          companies: companies,
          currentIndex: currentIndex,
        );
      }

      return const DashboardScreen();
    }

    final isTokenIssue = _looksLikeTokenError(me["message"]?.toString());
    if (isTokenIssue) {
      await prefs.remove("token");
      await prefs.setBool("isLoggedIn", false);
      return const Signin(
        sessionMessage:
            "Your session expired or is invalid. Please log in again.",
      );
    }

    final cachedCompaniesRaw = prefs.getString("companies");
    final cachedCurrentIndex = prefs.getInt("activeCompanyIndex") ?? 0;

    if (cachedCompaniesRaw != null && cachedCompaniesRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedCompaniesRaw);
        if (decoded is List && decoded.isNotEmpty) {
          return CompanySelectionScreen(
            companies: decoded,
            currentIndex: cachedCurrentIndex,
          );
        }
      } catch (_) {}
    }

    return const DashboardScreen();
  }

  bool _looksLikeTokenError(String? message) {
    if (message == null) return true;
    final text = message.toLowerCase();
    return text.contains("token") ||
        text.contains("unauthor") ||
        text.contains("expired") ||
        text.contains("jwt") ||
        text.contains("forbidden") ||
        text.contains("401");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _nextScreen,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data ?? const FirstOnboard();
      },
    );
  }
}
