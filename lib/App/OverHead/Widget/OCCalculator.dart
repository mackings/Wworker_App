// overhead_cost_calculator.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PricingSettingsManager {
  static const String _markupKey = 'pricing_markup_percentage';
  static const String _pricingMethodKey = 'pricing_method';
  static const String _workingDaysKey = 'factory_working_days_per_month';

  // Save markup percentage
  static Future<void> saveMarkup(double markupPercentage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_markupKey, markupPercentage);
    debugPrint("💾 Saved markup: $markupPercentage%");
  }

  // Get markup percentage (default: 30%)
  static Future<double> getMarkup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_markupKey) ?? 30.0;
  }

  // Save pricing method (Method 1 or Method 2)
  static Future<void> savePricingMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pricingMethodKey, method);
    debugPrint("💾 Saved pricing method: $method");
  }

  // Get pricing method (default: Method 1)
  static Future<String> getPricingMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pricingMethodKey) ?? 'Method 1';
  }

  // Save working days per month
  static Future<void> saveWorkingDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_workingDaysKey, days);
    debugPrint("💾 Saved working days: $days");
  }

  // Get working days per month (default: 26 days)
  static Future<int> getWorkingDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_workingDaysKey) ?? 26;
  }

  // Get all settings at once
  static Future<Map<String, dynamic>> getAllSettings() async {
    final markup = await getMarkup();
    final method = await getPricingMethod();
    final workingDays = await getWorkingDays();

    return {
      'markup': markup,
      'method': method,
      'workingDays': workingDays,
    };
  }

  // Save all settings at once
  static Future<void> saveAllSettings({
    required double markup,
    required String method,
    required int workingDays,
  }) async {
    await saveMarkup(markup);
    await savePricingMethod(method);
    await saveWorkingDays(workingDays);
    debugPrint("💾 Saved all pricing settings");
  }
}

// ==============================
// OVERHEAD COST CALCULATOR - FIXED VERSION
// ==============================
class OverheadCostCalculator {
  /// Convert any period to days for calculation
  static double _periodToDays(String period) {
    switch (period.toLowerCase()) {
      case 'hour':
      case 'hourly':
        return 1.0 / 24.0; // 1 hour = 0.0417 days
      case 'day':
      case 'daily':
        return 1.0;
      case 'week':
      case 'weekly':
        return 7.0;
      case 'month':
      case 'monthly':
        return 30.0; // Average month
      case 'quarter':
      case 'quarterly':
        return 90.0; // 3 months
      case 'year':
      case 'yearly':
        return 365.0;
      default:
        return 30.0; // Default to monthly
    }
  }

  /// Convert cost from its original period to the target duration
  static double convertCostToDuration(
    double cost,
    String originalPeriod,
    String targetDuration,
  ) {
    // Step 1: Convert original cost to daily rate
    final originalDays = _periodToDays(originalPeriod);
    final dailyRate = cost / originalDays;

    // Step 2: Convert daily rate to target period
    final targetDays = _periodToDays(targetDuration);
    final convertedCost = dailyRate * targetDays;

    debugPrint("🔄 CONVERSION: ₦$cost/$originalPeriod → ₦${convertedCost.toStringAsFixed(2)}/$targetDuration");
    debugPrint("   Step 1: ₦$cost ÷ $originalDays days = ₦${dailyRate.toStringAsFixed(2)}/day");
    debugPrint("   Step 2: ₦${dailyRate.toStringAsFixed(2)}/day × $targetDays days = ₦${convertedCost.toStringAsFixed(2)}/$targetDuration");

    return convertedCost;
  }

  /// Calculate total for a specific duration
  static double calculateTotalForDuration(
    List<dynamic> items,
    String targetDuration,
  ) {
    double total = 0.0;

    debugPrint("📊 CALCULATING TOTAL FOR: $targetDuration");
    for (var item in items) {
      final cost = (item.cost as num).toDouble();
      final period = item.period as String;
      final convertedCost = convertCostToDuration(cost, period, targetDuration);
      total += convertedCost;
      debugPrint("   ✓ ${item.description}: ₦${convertedCost.toStringAsFixed(2)}");
    }
    debugPrint("   = TOTAL: ₦${total.toStringAsFixed(2)}/$targetDuration");

    return total;
  }

  /// Get breakdown by category for a specific duration
  static Map<String, double> getCategoryBreakdown(
    List<dynamic> items,
    String targetDuration,
  ) {
    Map<String, double> breakdown = {};

    for (var item in items) {
      final category = item.category as String;
      final cost = (item.cost as num).toDouble();
      final period = item.period as String;
      final convertedCost = convertCostToDuration(cost, period, targetDuration);

      breakdown[category] = (breakdown[category] ?? 0.0) + convertedCost;
    }

    return breakdown;
  }

  /// Get detailed breakdown with individual items converted to target duration
  static List<Map<String, dynamic>> getDetailedBreakdown(
    List<dynamic> items,
    String targetDuration,
  ) {
    return items.map((item) {
      final cost = (item.cost as num).toDouble();
      final period = item.period as String;
      final convertedCost = convertCostToDuration(cost, period, targetDuration);

      return {
        'category': item.category,
        'description': item.description,
        'originalCost': cost,
        'originalPeriod': period,
        'convertedCost': convertedCost,
        'targetDuration': targetDuration,
      };
    }).toList();
  }
}

// ==============================
// OVERHEAD COST MANAGER
// ==============================
class OverheadCostManager {
  /// Load overhead costs from SharedPreferences
  static Future<List<Map<String, dynamic>>> getOverheadCosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final costsString = prefs.getString('overhead_costs');

      if (costsString == null || costsString.isEmpty) {
        return [];
      }

      final List<dynamic> costsJson = jsonDecode(costsString);
      return costsJson.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint("⚠️ Error loading overhead costs: $e");
      return [];
    }
  }

  /// Get total overhead cost for a specific duration
  static Future<double> getTotalOverheadCost({String duration = 'Monthly'}) async {
    final costs = await getOverheadCosts();
    
    // Convert costs to a format the calculator can use
    final items = costs.map((cost) => _CostItem(
      cost: (cost['cost'] as num).toDouble(),
      period: cost['period'] as String,
      category: cost['category'] as String,
      description: cost['description'] as String,
    )).toList();

    return OverheadCostCalculator.calculateTotalForDuration(items, duration);
  }

  /// Get breakdown by category for a specific duration
  static Future<Map<String, double>> getCategoryBreakdown({String duration = 'Monthly'}) async {
    final costs = await getOverheadCosts();
    
    final items = costs.map((cost) => _CostItem(
      cost: (cost['cost'] as num).toDouble(),
      period: cost['period'] as String,
      category: cost['category'] as String,
      description: cost['description'] as String,
    )).toList();

    return OverheadCostCalculator.getCategoryBreakdown(items, duration);
  }

  /// Get detailed breakdown for a specific duration
  static Future<List<Map<String, dynamic>>> getDetailedBreakdown({String duration = 'Monthly'}) async {
    final costs = await getOverheadCosts();
    
    final items = costs.map((cost) => _CostItem(
      cost: (cost['cost'] as num).toDouble(),
      period: cost['period'] as String,
      category: cost['category'] as String,
      description: cost['description'] as String,
    )).toList();

    return OverheadCostCalculator.getDetailedBreakdown(items, duration);
  }
}

// ==============================
// HELPER CLASS
// ==============================
class _CostItem {
  final double cost;
  final String period;
  final String category;
  final String description;

  _CostItem({
    required this.cost,
    required this.period,
    required this.category,
    required this.description,
  });
}