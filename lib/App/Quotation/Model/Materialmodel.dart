class MaterialModel {
  final String id;
  final String name;
  final String unit;
  final double standardWidth;
  final double standardLength;
  final String standardUnit;
  final double pricePerSqm;
  final List<Size> sizes;
  final List<FoamDensity> foamDensities;
  final List<FoamThickness> foamThicknesses;
  final List<MaterialType> types;
  final double wasteThreshold;
  final String createdAt;
  final String updatedAt;

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
      standardWidth: json['standardWidth']?.toDouble() ?? 0.0,
      standardLength: json['standardLength']?.toDouble() ?? 0.0,
      standardUnit: json['standardUnit'] ?? '',
      pricePerSqm: json['pricePerSqm']?.toDouble() ?? 0.0,
      sizes: (json['sizes'] as List?)
          ?.map((s) => Size.fromJson(s))
          .toList() ??
          [],
      foamDensities: (json['foamDensities'] as List?)
          ?.map((f) => FoamDensity.fromJson(f))
          .toList() ??
          [],
      foamThicknesses: (json['foamThicknesses'] as List?)
          ?.map((f) => FoamThickness.fromJson(f))
          .toList() ??
          [],
      types: (json['types'] as List?)
          ?.map((t) => MaterialType.fromJson(t))
          .toList() ??
          [],
      wasteThreshold: json['wasteThreshold']?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
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
      'sizes': sizes.map((s) => s.toJson()).toList(),
      'foamDensities': foamDensities.map((f) => f.toJson()).toList(),
      'foamThicknesses': foamThicknesses.map((f) => f.toJson()).toList(),
      'types': types.map((t) => t.toJson()).toList(),
      'wasteThreshold': wasteThreshold,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class Size {
  final double width;
  final double length;

  Size({required this.width, required this.length});

  factory Size.fromJson(Map<String, dynamic> json) {
    return Size(
      width: json['width']?.toDouble() ?? 0.0,
      length: json['length']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'width': width, 'length': length};
  }
}

class FoamDensity {
  final double density;
  final String unit;

  FoamDensity({required this.density, required this.unit});

  factory FoamDensity.fromJson(Map<String, dynamic> json) {
    return FoamDensity(
      density: json['density']?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'density': density, 'unit': unit};
  }
}

class FoamThickness {
  final double thickness;
  final String unit;

  FoamThickness({required this.thickness, required this.unit});

  factory FoamThickness.fromJson(Map<String, dynamic> json) {
    return FoamThickness(
      thickness: json['thickness']?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'thickness': thickness, 'unit': unit};
  }
}

class MaterialType {
  final String name;
  final double pricePerSqm;

  MaterialType({required this.name, required this.pricePerSqm});

  factory MaterialType.fromJson(Map<String, dynamic> json) {
    return MaterialType(
      name: json['name'] ?? '',
      pricePerSqm: json['pricePerSqm']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'pricePerSqm': pricePerSqm};
  }
}
