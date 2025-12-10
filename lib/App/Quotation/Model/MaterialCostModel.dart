


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
        projectAreaSqm: double.parse(project.projectAreaSqm),
        standardAreaSqm: double.parse(standard.standardAreaSqm),
      );

  QuantityInfo get quantity => QuantityInfo(
        minimumUnits: calculation.minimumUnits,
      );
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
      requiredWidth: json['requiredWidth']?.toDouble() ?? 0.0,
      requiredLength: json['requiredLength']?.toDouble() ?? 0.0,
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
      standardWidth: json['standardWidth']?.toDouble() ?? 0.0,
      standardLength: json['standardLength']?.toDouble() ?? 0.0,
      standardUnit: json['standardUnit'] ?? '',
      standardAreaSqm: json['standardAreaSqm']?.toString() ?? '0',
    );
  }
}

class CalculationInfo {
  final int minimumUnits;
  final double wasteThreshold;
  final String rawRemainder;
  final String wasteThresholdArea;
  final bool extraUnitAdded;

  CalculationInfo({
    required this.minimumUnits,
    required this.wasteThreshold,
    required this.rawRemainder,
    required this.wasteThresholdArea,
    required this.extraUnitAdded,
  });

  factory CalculationInfo.fromJson(Map<String, dynamic> json) {
    return CalculationInfo(
      minimumUnits: json['minimumUnits'] ?? 0,
      wasteThreshold: json['wasteThreshold']?.toDouble() ?? 0.75,
      rawRemainder: json['rawRemainder']?.toString() ?? '0',
      wasteThresholdArea: json['wasteThresholdArea']?.toString() ?? '0',
      extraUnitAdded: json['extraUnitAdded'] ?? false,
    );
  }
}

class PricingInfo {
  final double pricePerSqm;
  final double pricePerFullUnit;
  final double totalMaterialCost;

  PricingInfo({
    required this.pricePerSqm,
    required this.pricePerFullUnit,
    required this.totalMaterialCost,
  });

  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    return PricingInfo(
      pricePerSqm: double.parse(json['pricePerSqm']?.toString() ?? '0'),
      pricePerFullUnit: double.parse(json['pricePerFullUnit']?.toString() ?? '0'),
      totalMaterialCost: double.parse(json['totalMaterialCost']?.toString() ?? '0'),
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
      totalAreaUsed: double.parse(json['totalAreaUsed']?.toString() ?? '0'),
      wasteArea: double.parse(json['wasteArea']?.toString() ?? '0'),
      wastePercentage: double.parse(json['wastePercentage']?.toString() ?? '0'),
    );
  }
}

// Helper classes for backward compatibility
class DimensionsInfo {
  final double projectAreaSqm;
  final double standardAreaSqm;

  DimensionsInfo({
    required this.projectAreaSqm,
    required this.standardAreaSqm,
  });
}

class QuantityInfo {
  final int minimumUnits;

  QuantityInfo({required this.minimumUnits});
}