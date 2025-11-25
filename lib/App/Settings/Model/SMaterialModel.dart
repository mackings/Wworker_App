// ========== MATERIAL MODELS ==========

class MaterialModel {
  final String id;
  final String name;
  final String unit;
  final double standardWidth;
  final double standardLength;
  final String standardUnit;
  final double pricePerSqm;
  final List<MaterialSize> sizes;
  final List<FoamDensity> foamDensities;
  final List<FoamThickness> foamThicknesses;
  final List<MaterialType> types;
  final double wasteThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaterialModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.standardWidth,
    required this.standardLength,
    required this.standardUnit,
    required this.pricePerSqm,
    required this.sizes,
    required this.foamDensities,
    required this.foamThicknesses,
    required this.types,
    required this.wasteThreshold,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      standardWidth: (json['standardWidth'] ?? 0).toDouble(),
      standardLength: (json['standardLength'] ?? 0).toDouble(),
      standardUnit: json['standardUnit'] ?? '',
      pricePerSqm: (json['pricePerSqm'] ?? 0).toDouble(),
      sizes: (json['sizes'] as List<dynamic>?)
              ?.map((e) => MaterialSize.fromJson(e))
              .toList() ??
          [],
      foamDensities: (json['foamDensities'] as List<dynamic>?)
              ?.map((e) => FoamDensity.fromJson(e))
              .toList() ??
          [],
      foamThicknesses: (json['foamThicknesses'] as List<dynamic>?)
              ?.map((e) => FoamThickness.fromJson(e))
              .toList() ??
          [],
      types: (json['types'] as List<dynamic>?)
              ?.map((e) => MaterialType.fromJson(e))
              .toList() ??
          [],
      wasteThreshold: (json['wasteThreshold'] ?? 0.75).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'unit': unit,
      'standardWidth': standardWidth,
      'standardLength': standardLength,
      'standardUnit': standardUnit,
      'pricePerSqm': pricePerSqm,
      'sizes': sizes.map((e) => e.toJson()).toList(),
      'foamDensities': foamDensities.map((e) => e.toJson()).toList(),
      'foamThicknesses': foamThicknesses.map((e) => e.toJson()).toList(),
      'types': types.map((e) => e.toJson()).toList(),
      'wasteThreshold': wasteThreshold,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class MaterialSize {
  final double width;
  final double length;

  MaterialSize({
    required this.width,
    required this.length,
  });

  factory MaterialSize.fromJson(Map<String, dynamic> json) {
    return MaterialSize(
      width: (json['width'] ?? 0).toDouble(),
      length: (json['length'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'length': length,
    };
  }
}

class FoamDensity {
  final double density;
  final String unit;

  FoamDensity({
    required this.density,
    required this.unit,
  });

  factory FoamDensity.fromJson(Map<String, dynamic> json) {
    return FoamDensity(
      density: (json['density'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'kg/m³',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'density': density,
      'unit': unit,
    };
  }
}

class FoamThickness {
  final double thickness;
  final String unit;

  FoamThickness({
    required this.thickness,
    required this.unit,
  });

  factory FoamThickness.fromJson(Map<String, dynamic> json) {
    return FoamThickness(
      thickness: (json['thickness'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'mm',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thickness': thickness,
      'unit': unit,
    };
  }
}

class MaterialType {
  final String name;
  final double? pricePerSqm;

  MaterialType({
    required this.name,
    this.pricePerSqm,
  });

  factory MaterialType.fromJson(Map<String, dynamic> json) {
    return MaterialType(
      name: json['name'] ?? '',
      pricePerSqm: json['pricePerSqm'] != null 
          ? (json['pricePerSqm'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (pricePerSqm != null) 'pricePerSqm': pricePerSqm,
    };
  }
}

// Request DTOs
class CreateMaterialRequest {
  final String name;
  final String unit;
  final double standardWidth;
  final double standardLength;
  final String standardUnit;
  final double pricePerSqm;
  final List<MaterialSize>? sizes;
  final List<FoamDensity>? foamDensities;
  final List<FoamThickness>? foamThicknesses;
  final double? wasteThreshold;

  CreateMaterialRequest({
    required this.name,
    required this.unit,
    required this.standardWidth,
    required this.standardLength,
    required this.standardUnit,
    required this.pricePerSqm,
    this.sizes,
    this.foamDensities,
    this.foamThicknesses,
    this.wasteThreshold,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
      'standardWidth': standardWidth,
      'standardLength': standardLength,
      'standardUnit': standardUnit,
      'pricePerSqm': pricePerSqm,
      if (sizes != null) 'sizes': sizes!.map((e) => e.toJson()).toList(),
      if (foamDensities != null) 
        'foamDensities': foamDensities!.map((e) => e.toJson()).toList(),
      if (foamThicknesses != null)
        'foamThicknesses': foamThicknesses!.map((e) => e.toJson()).toList(),
      if (wasteThreshold != null) 'wasteThreshold': wasteThreshold,
    };
  }
}

class AddMaterialTypesRequest {
  final List<dynamic> types; // Can be List<String> or List<MaterialType>

  AddMaterialTypesRequest({required this.types});

  Map<String, dynamic> toJson() {
    return {
      'types': types.map((type) {
        if (type is String) {
          return type;
        } else if (type is MaterialType) {
          return type.toJson();
        }
        return type;
      }).toList(),
    };
  }
}