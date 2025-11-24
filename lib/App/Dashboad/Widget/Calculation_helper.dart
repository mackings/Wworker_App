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
      case 'ft':
        return value * 0.3048;
      case 'in':
        return value * 0.0254;
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

  /// Calculate total board price from price per unit area
  /// Formula: Total Board Price = Total Area × Price per Unit Area
  static double calculateTotalBoardPrice({
    required double totalAreaSqm,
    required double pricePerSqm,
  }) {
    return totalAreaSqm * pricePerSqm;
  }

  /// Calculate project cost directly from price per unit area
  /// Formula: Project Cost = Required Area × Price per Unit Area
  static double calculateProjectCost({
    required double requiredAreaSqm,
    required double pricePerSqm,
  }) {
    return requiredAreaSqm * pricePerSqm;
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
    return '${area.toStringAsFixed(4)} $unit';
  }
}


