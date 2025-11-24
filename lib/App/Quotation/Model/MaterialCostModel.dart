import 'package:wworker/App/Quotation/Model/Materialmodel.dart';

class MaterialCostModel {
  final MaterialModel material;
  final Dimensions dimensions;
  final Pricing pricing;
  final Quantity quantity;
  final Waste waste;

  MaterialCostModel({
    required this.material,
    required this.dimensions,
    required this.pricing,
    required this.quantity,
    required this.waste,
  });

  factory MaterialCostModel.fromJson(Map<String, dynamic> json) {
    return MaterialCostModel(
      material: MaterialModel.fromJson(json['material']),
      dimensions: Dimensions.fromJson(json['dimensions']),
      pricing: Pricing.fromJson(json['pricing']),
      quantity: Quantity.fromJson(json['quantity']),
      waste: Waste.fromJson(json['waste']),
    );
  }
}

class Dimensions {
  final double requiredWidth;
  final double requiredLength;
  final String requiredUnit;
  final double projectAreaSqm;
  final double standardAreaSqm;

  Dimensions({
    required this.requiredWidth,
    required this.requiredLength,
    required this.requiredUnit,
    required this.projectAreaSqm,
    required this.standardAreaSqm,
  });

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    return Dimensions(
      requiredWidth: _parseDouble(json['requiredWidth']),
      requiredLength: _parseDouble(json['requiredLength']),
      requiredUnit: json['requiredUnit'] ?? '',
      projectAreaSqm: _parseDouble(json['projectAreaSqm']),
      standardAreaSqm: _parseDouble(json['standardAreaSqm']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class Pricing {
  final double pricePerSqm;
  final double totalBoardPrice;
  final double projectCost;

  Pricing({
    required this.pricePerSqm,
    required this.totalBoardPrice,
    required this.projectCost,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      pricePerSqm: _parseDouble(json['pricePerSqm']),
      totalBoardPrice: _parseDouble(json['totalBoardPrice']),
      projectCost: _parseDouble(json['projectCost']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class Quantity {
  final int minimumUnits;
  final double wasteThreshold;

  Quantity({
    required this.minimumUnits,
    required this.wasteThreshold,
  });

  factory Quantity.fromJson(Map<String, dynamic> json) {
    return Quantity(
      minimumUnits: json['minimumUnits'] ?? 0,
      wasteThreshold: _parseDouble(json['wasteThreshold']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class Waste {
  final double totalAreaUsed;
  final double wasteArea;
  final double wastePercentage;

  Waste({
    required this.totalAreaUsed,
    required this.wasteArea,
    required this.wastePercentage,
  });

  factory Waste.fromJson(Map<String, dynamic> json) {
    return Waste(
      totalAreaUsed: _parseDouble(json['totalAreaUsed']),
      wasteArea: _parseDouble(json['wasteArea']),
      wastePercentage: _parseDouble(json['wastePercentage']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}