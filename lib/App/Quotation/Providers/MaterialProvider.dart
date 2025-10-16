import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';



/// Provider (persistent and not auto-disposed)
final materialProvider =
    StateNotifierProvider<MaterialNotifier, List<Map<String, dynamic>>>(
  (ref) => MaterialNotifier(),
);

class MaterialNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  MaterialNotifier() : super([]) {
    _loadMaterials();
  }

  static const _storageKeyPrefix = "user_materials_";

  String _getKey(String userId) => "$_storageKeyPrefix$userId";

  /// Retrieve the current user's ID stored in SharedPreferences
  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId") ?? "default_user";
  }

  /// Load materials for the current user
  Future<void> _loadMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "default_user";
    final data = prefs.getString(_getKey(userId));
    if (data != null) {
      state = List<Map<String, dynamic>>.from(jsonDecode(data));
    }
  }

  /// Save materials for the current user
  Future<void> _saveMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "default_user";
    await prefs.setString(_getKey(userId), jsonEncode(state));
  }

  /// Add a new material item
  Future<void> addItem(Map<String, dynamic> newItem) async {
    state = [...state, newItem];
    await _saveMaterials();
  }

  /// Delete a material at a given index
  Future<void> deleteItem(int index) async {
    if (index >= 0 && index < state.length) {
      state = List.from(state)..removeAt(index);
      await _saveMaterials();
    }
  }

  /// Clear all materials for current user
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "default_user";
    state = [];
    await prefs.remove(_getKey(userId));
  }
}
