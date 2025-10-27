import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';

final quotationSummaryProvider =
    StateNotifierProvider<QuotationSummaryNotifier, Map<String, dynamic>>(
  (ref) => QuotationSummaryNotifier(ref),
);

class QuotationSummaryNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;

  QuotationSummaryNotifier(this.ref)
      : super({
          "product": null,
          "materials": [],
          "additionalCosts": [],
          "isLoaded": false,
        }) {
    _loadQuotation();
  }

  static const _storageKey = "user_quotation_summary";

  Future<void> _loadQuotation() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data != null) {
      final decoded = jsonDecode(data);
      state = {
        "product": decoded["product"],
        "materials": decoded["materials"] ?? [],
        "additionalCosts": decoded["additionalCosts"] ?? [],
        "isLoaded": true,
      };
    } else {
      state = {
        "product": null,
        "materials": [],
        "additionalCosts": [],
        "isLoaded": true,
      };
    }
  }

  Future<void> _saveQuotation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state));
  }

  void setProduct(Map<String, dynamic> productData) async {
    state = {...state, "product": productData};
    await _saveQuotation();
  }

  void loadFromMaterialProvider() async {
    final materialState = ref.read(materialProvider);
    state = {
      ...state,
      "materials": materialState["materials"],
      "additionalCosts": materialState["additionalCosts"],
    };
    await _saveQuotation();
  }

  void clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    state = {
      "product": null,
      "materials": [],
      "additionalCosts": [],
      "isLoaded": true,
    };
  }
}
