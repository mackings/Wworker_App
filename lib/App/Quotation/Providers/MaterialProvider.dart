import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final materialProvider =
    StateNotifierProvider<MaterialNotifier, Map<String, dynamic>>(
      (ref) => MaterialNotifier(),
    );

class MaterialNotifier extends StateNotifier<Map<String, dynamic>> {
  MaterialNotifier()
    : super({"materials": [], "additionalCosts": [], "isLoaded": false}) {
    _loadMaterials();
  }

  static const _storageKeyPrefix = "user_bom_";

  String _getKey(String userId) => "$_storageKeyPrefix$userId";

  Future<void> _loadMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "default_user";
    final data = prefs.getString(_getKey(userId));

    if (data != null) {
      final decoded = Map<String, dynamic>.from(jsonDecode(data));
      state = {
        "materials": decoded["materials"] ?? [],
        "additionalCosts": decoded["additionalCosts"] ?? [],
        "isLoaded": true,
      };
    } else {
      state = {"materials": [], "additionalCosts": [], "isLoaded": true};
    }
  }

  Future<void> _saveMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "default_user";

    final dataToSave = {
      "materials": state["materials"],
      "additionalCosts": state["additionalCosts"],
    };

    await prefs.setString(_getKey(userId), jsonEncode(dataToSave));
  }

  Future<void> addMaterial(Map<String, dynamic> newItem) async {
    final updated = List<Map<String, dynamic>>.from(state["materials"]);
    updated.add(newItem);
    state = {...state, "materials": updated};
    await _saveMaterials();
  }

  Future<void> addAdditionalCost(Map<String, dynamic> newCost) async {
    final updated = List<Map<String, dynamic>>.from(state["additionalCosts"]);
    updated.add(newCost);
    state = {...state, "additionalCosts": updated};
    await _saveMaterials();
  }

  Future<void> deleteMaterial(int index) async {
    final updated = List<Map<String, dynamic>>.from(state["materials"]);
    if (index >= 0 && index < updated.length) {
      updated.removeAt(index);
      state = {...state, "materials": updated};
      await _saveMaterials();
    }
  }

  Future<void> updateMaterial(int index, Map<String, dynamic> item) async {
    final updated = List<Map<String, dynamic>>.from(state["materials"]);
    if (index >= 0 && index < updated.length) {
      updated[index] = item;
      state = {...state, "materials": updated};
      await _saveMaterials();
    }
  }

  Future<void> deleteAdditionalCost(int index) async {
    final updated = List<Map<String, dynamic>>.from(state["additionalCosts"]);
    if (index >= 0 && index < updated.length) {
      updated.removeAt(index);
      state = {...state, "additionalCosts": updated};
      await _saveMaterials();
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "default_user";
    state = {"materials": [], "additionalCosts": [], "isLoaded": true};
    await prefs.remove(_getKey(userId));
  }
}
