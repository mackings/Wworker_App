class MaterialCostModel {
  final MaterialInfo material;
  final ProjectInfo project;
  final StandardInfo standard;
  final CalculationInfo calculation;
  final PricingInfo pricing;
  final WasteInfo waste;

  MaterialCostModel({
    required this.material,
    required this.project,
    required this.standard,
    required this.calculation,
    required this.pricing,
    required this.waste,
  });

  factory MaterialCostModel.fromJson(Map<String, dynamic> json) {
    return MaterialCostModel(
      material: MaterialInfo.fromJson(json['material'] ?? {}),
      project: ProjectInfo.fromJson(json['project'] ?? {}),
      standard: StandardInfo.fromJson(json['standard'] ?? {}),
      calculation: CalculationInfo.fromJson(json['calculation'] ?? {}),
      pricing: PricingInfo.fromJson(json['pricing'] ?? {}),
      waste: WasteInfo.fromJson(json['waste'] ?? {}),
    );
  }

  // Backward compatibility with old field names
  DimensionsInfo get dimensions => DimensionsInfo(
    projectAreaSqm: _toDouble(project.projectAreaSqm),
    standardAreaSqm: _toDouble(standard.standardAreaSqm),
  );

  QuantityInfo get quantity =>
      QuantityInfo(minimumUnits: calculation.minimumUnits);
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

class MaterialInfo {
  final String id;
  final String name;
  final String? category;
  final String? type;
  final String? variant;

  MaterialInfo({
    required this.id,
    required this.name,
    this.category,
    this.type,
    this.variant,
  });

  factory MaterialInfo.fromJson(Map<String, dynamic> json) {
    return MaterialInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'],
      type: json['type'],
      variant: json['variant'],
    );
  }
}

class ProjectInfo {
  final double requiredWidth;
  final double requiredLength;
  final String requiredUnit;
  final String projectAreaSqm;

  ProjectInfo({
    required this.requiredWidth,
    required this.requiredLength,
    required this.requiredUnit,
    required this.projectAreaSqm,
  });

  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      requiredWidth: _toDouble(json['requiredWidth']),
      requiredLength: _toDouble(json['requiredLength']),
      requiredUnit: json['requiredUnit'] ?? '',
      projectAreaSqm: json['projectAreaSqm']?.toString() ?? '0',
    );
  }
}

class StandardInfo {
  final double standardWidth;
  final double standardLength;
  final String standardUnit;
  final String standardAreaSqm;

  StandardInfo({
    required this.standardWidth,
    required this.standardLength,
    required this.standardUnit,
    required this.standardAreaSqm,
  });

  factory StandardInfo.fromJson(Map<String, dynamic> json) {
    return StandardInfo(
      standardWidth: _toDouble(json['standardWidth']),
      standardLength: _toDouble(json['standardLength']),
      standardUnit: json['standardUnit'] ?? '',
      standardAreaSqm: json['standardAreaSqm']?.toString() ?? '0',
    );
  }
}

class CalculationInfo {
  final String mode;
  final int minimumUnits;
  final double quantity;
  final double wasteThreshold;
  final String rawRemainder;
  final String wasteThresholdArea;
  final bool extraUnitAdded;

  CalculationInfo({
    required this.mode,
    required this.minimumUnits,
    required this.quantity,
    required this.wasteThreshold,
    required this.rawRemainder,
    required this.wasteThresholdArea,
    required this.extraUnitAdded,
  });

  factory CalculationInfo.fromJson(Map<String, dynamic> json) {
    return CalculationInfo(
      mode: json['mode']?.toString() ?? 'sheet_based',
      minimumUnits: _toInt(json['minimumUnits']),
      quantity: _toDouble(json['quantity'], fallback: 1),
      wasteThreshold: _toDouble(json['wasteThreshold'], fallback: 0.75),
      rawRemainder: json['rawRemainder']?.toString() ?? '0',
      wasteThresholdArea: json['wasteThresholdArea']?.toString() ?? '0',
      extraUnitAdded: json['extraUnitAdded'] ?? false,
    );
  }
}

class PricingInfo {
  final double pricePerUnit;
  final double pricePerSqm;
  final double pricePerFullUnit;
  final double totalMaterialCost;

  PricingInfo({
    required this.pricePerUnit,
    required this.pricePerSqm,
    required this.pricePerFullUnit,
    required this.totalMaterialCost,
  });

  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    return PricingInfo(
      pricePerUnit: _toDouble(json['pricePerUnit']),
      pricePerSqm: _toDouble(json['pricePerSqm']),
      pricePerFullUnit: _toDouble(json['pricePerFullUnit']),
      totalMaterialCost: _toDouble(json['totalMaterialCost']),
    );
  }

  // Backward compatibility
  double get totalBoardPrice => pricePerFullUnit;
  double get projectCost => totalMaterialCost;
}

class WasteInfo {
  final double totalAreaUsed;
  final double wasteArea;
  final double wastePercentage;

  WasteInfo({
    required this.totalAreaUsed,
    required this.wasteArea,
    required this.wastePercentage,
  });

  factory WasteInfo.fromJson(Map<String, dynamic> json) {
    return WasteInfo(
      totalAreaUsed: _toDouble(json['totalAreaUsed']),
      wasteArea: _toDouble(json['wasteArea']),
      wastePercentage: _toDouble(json['wastePercentage']),
    );
  }
}

// Helper classes for backward compatibility
class DimensionsInfo {
  final double projectAreaSqm;
  final double standardAreaSqm;

  DimensionsInfo({required this.projectAreaSqm, required this.standardAreaSqm});
}

class QuantityInfo {
  final int minimumUnits;

  QuantityInfo({required this.minimumUnits});
}
