class MaterialModel {
  final String id;
  final String name;
  final String unit;
  final List<String> sizes;
  final List<String> foamDensities;
  final List<String> foamThicknesses;
  final List<MaterialType> types;
  final String createdAt;
  final String updatedAt;

  MaterialModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.sizes,
    required this.foamDensities,
    required this.foamThicknesses,
    required this.types,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      sizes: List<String>.from(json['sizes'] ?? []),
      foamDensities: List<String>.from(json['foamDensities'] ?? []),
      foamThicknesses: List<String>.from(json['foamThicknesses'] ?? []),
      types: (json['types'] as List?)
              ?.map((t) => MaterialType.fromJson(t))
              .toList() ??
          [],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'unit': unit,
      'sizes': sizes,
      'foamDensities': foamDensities,
      'foamThicknesses': foamThicknesses,
      'types': types.map((t) => t.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class MaterialType {
  final String name;

  MaterialType({required this.name});

  factory MaterialType.fromJson(Map<String, dynamic> json) {
    return MaterialType(name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}