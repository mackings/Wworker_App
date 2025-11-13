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

    // 👀 Automatically watch MaterialProvider changes
    ref.listen<Map<String, dynamic>>(materialProvider, (previous, next) async {
      if (previous == null) return;

      final bool materialsChanged =
          jsonEncode(previous["materials"]) != jsonEncode(next["materials"]);
      final bool costsChanged =
          jsonEncode(previous["additionalCosts"]) !=
          jsonEncode(next["additionalCosts"]);

      if (materialsChanged || costsChanged) {
        state = {
          ...state,
          "materials": next["materials"],
          "additionalCosts": next["additionalCosts"],
        };
        // ❌ REMOVED: await _saveQuotation();
        // This was causing duplicates because _saveQuotation calls _addOrUpdateQuotationInList
      }
    });
  }

  // ==================================================
  // 🗄️ Persistence Helpers
  // ==================================================
  static const _storageKeyPrefix = "user_quotation_";

  String _getKey(String userId) => "$_storageKeyPrefix$userId";
  String _getListKey(String userId) => "${_storageKeyPrefix}list_$userId";

  Future<void> _loadQuotation() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "default_user";
    final data = prefs.getString(_getKey(userId));

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
    final userId = prefs.getString("userId") ?? "default_user";

    final dataToSave = {
      "product": state["product"],
      "materials": state["materials"],
      "additionalCosts": state["additionalCosts"],
    };

    // ✅ Only save the current active quotation, don't add to list
    await prefs.setString(_getKey(userId), jsonEncode(dataToSave));
  }

  // ==================================================
  // 🧩 Mutators
  // ==================================================

  Future<void> setProduct(Map<String, dynamic> productData) async {
    state = {...state, "product": productData};
    await _saveQuotation();
  }

  Future<void> setMaterials(List<Map<String, dynamic>> materials) async {
    state = {...state, "materials": materials};
    await _saveQuotation();
  }

  Future<void> setAdditionalCosts(
    List<Map<String, dynamic>> additionalCosts,
  ) async {
    state = {...state, "additionalCosts": additionalCosts};
    await _saveQuotation();
  }

  Future<void> deleteCurrentQuotation() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "default_user";
    await prefs.remove(_getKey(userId));
    state = {
      "product": null,
      "materials": [],
      "additionalCosts": [],
      "isLoaded": true,
    };
  }

  Future<void> clearAll() async => await deleteCurrentQuotation();

  // ==================================================
  // 🧾 Append New Quotation (ONLY method that adds to list)
  // ==================================================
  Future<void> addNewQuotation(Map<String, dynamic> quotation) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "default_user";
    final key = _getListKey(userId);

    final data = prefs.getString(key);
    List<Map<String, dynamic>> quotations = [];

    if (data != null) {
      quotations = List<Map<String, dynamic>>.from(jsonDecode(data));
    }

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    quotations.add({
      ...quotation,
      "id": newId,
      "createdAt": DateTime.now().toIso8601String(),
    });

    await prefs.setString(key, jsonEncode(quotations));

    // Optional: make it the active quotation
    state = {
      "product": quotation["product"],
      "materials": quotation["materials"],
      "additionalCosts": quotation["additionalCosts"],
      "isLoaded": true,
      "quotationCount": quotations.length,
    };
  }

  // ==================================================
  // 🧾 Multi-Quotation Support
  // ==================================================

  // ❌ REMOVED: _addOrUpdateQuotationInList() - this was causing duplicates

  Future<List<Map<String, dynamic>>> getAllQuotations() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "default_user";
    final key = _getListKey(userId);

    final data = prefs.getString(key);
    if (data == null) return [];

    final quotations = List<Map<String, dynamic>>.from(jsonDecode(data));

    quotations.sort((a, b) {
      final aDate = DateTime.tryParse(a["createdAt"] ?? "") ?? DateTime(0);
      final bDate = DateTime.tryParse(b["createdAt"] ?? "") ?? DateTime(0);
      return bDate.compareTo(aDate);
    });

    return quotations;
  }

  Future<void> deleteQuotationById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "default_user";
    final key = _getListKey(userId);

    final data = prefs.getString(key);
    if (data == null) return;

    List<Map<String, dynamic>> quotations = List<Map<String, dynamic>>.from(
      jsonDecode(data),
    );
    quotations.removeWhere((q) => q["id"] == id);

    await prefs.setString(key, jsonEncode(quotations));
  }
}
