
/// Material Area and Cost Calculation Helper
/// Implements the pricing and quantity calculation logic

class MaterialCalculationHelper {
  /// Convert dimensions to meters based on unit
  static double convertToMeters(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'mm':
        return value / 1000;
      case 'cm':
        return value / 100;
      case 'm':
        return value;
      default:
        return value;
    }
  }

  /// Calculate area in square meters
  static double calculateArea({
    required double width,
    required double length,
    required String unit,
  }) {
    final widthM = convertToMeters(width, unit);
    final lengthM = convertToMeters(length, unit);
    return widthM * lengthM;
  }

  /// Calculate cost per square meter
  static double calculateCostPerSqm({
    required double totalPrice,
    required double totalAreaSqm,
  }) {
    if (totalAreaSqm <= 0) return 0;
    return totalPrice / totalAreaSqm;
  }

  /// Calculate minimum units needed with waste threshold
  /// 
  /// Parameters:
  /// - requiredArea: Total area needed for the project
  /// - unitArea: Area of one standard material unit (board/sheet)
  /// - wasteThreshold: Percentage (0.0 to 1.0) - default 0.75 (75%)
  /// 
  /// Returns: Number of full units needed
  static int calculateMinimumUnits({
    required double requiredArea,
    required double unitArea,
    double wasteThreshold = 0.75,
  }) {
    // Validation
    if (requiredArea <= 0) return 0;
    if (unitArea <= 0) return 0;
    if (wasteThreshold < 0 || wasteThreshold > 1) {
      throw ArgumentError('wasteThreshold must be between 0.0 and 1.0');
    }

    // Calculate full units using integer division
    final fullUnits = (requiredArea / unitArea).floor();
    
    // Calculate remainder
    final remainder = requiredArea - (fullUnits * unitArea);
    
    // Check if remainder exceeds threshold
    final thresholdArea = unitArea * wasteThreshold;
    
    if (remainder > thresholdArea) {
      return fullUnits + 1; // Round up
    } else {
      return fullUnits; // Keep as is (assuming remainder can be sourced elsewhere)
    }
  }

  /// Calculate project cost based on required area
  static double calculateProjectCost({
    required double requiredAreaSqm,
    required double standardAreaSqm,
    required double standardPrice,
  }) {
    if (standardAreaSqm <= 0) return 0;
    final costPerSqm = standardPrice / standardAreaSqm;
    return requiredAreaSqm * costPerSqm;
  }

  /// Calculate waste information
  static Map<String, dynamic> calculateWasteInfo({
    required double requiredArea,
    required double unitArea,
    required int unitsUsed,
  }) {
    final totalAreaUsed = unitsUsed * unitArea;
    final wasteArea = totalAreaUsed - requiredArea;
    final wastePercentage = totalAreaUsed > 0 
        ? (wasteArea / totalAreaUsed) * 100 
        : 0.0;

    return {
      'totalAreaUsed': totalAreaUsed,
      'wasteArea': wasteArea,
      'wastePercentage': wastePercentage,
    };
  }

  /// Format currency (Nigerian Naira)
  static String formatCurrency(double amount, {String symbol = '₦'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format area with unit
  static String formatArea(double area, {String unit = 'sq m'}) {
    return '${area.toStringAsFixed(2)} $unit';
  }
}

/// Example usage:
/// 
/// // Calculate area
/// double area = MaterialCalculationHelper.calculateArea(
///   width: 120,
///   length: 240,
///   unit: 'cm',
/// ); // Returns 2.88 sq m
/// 
/// // Calculate minimum boards needed
/// int boards = MaterialCalculationHelper.calculateMinimumUnits(
///   requiredArea: 25, // sq ft needed
///   unitArea: 32,     // 4ft × 8ft board = 32 sq ft
///   wasteThreshold: 0.75,
/// ); // Returns 1 (since 25 > 24 which is 75% of 32)
/// 
/// // Calculate project cost
/// double cost = MaterialCalculationHelper.calculateProjectCost(
///   requiredAreaSqm: 2.88,
///   standardAreaSqm: 3.0, // Standard board size
///   standardPrice: 30000,
/// ); // Returns ₦28,800