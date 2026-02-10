class MaterialModel {
  final String id;
  final String name;
  final String? category;
  final String? subCategory;
  final String? size;
  final String? color;
  final String? unit;
  final double? standardWidth;
  final double? standardLength;
  final String? standardUnit;
  final double? pricePerSqm;
  final double? pricePerUnit;
  final String? pricingUnit;
  final List<MaterialType> types;
  final List<SizeVariant> sizeVariants;
  final List<FoamVariant> foamVariants;
  final List<CommonThickness> commonThicknesses; // NEW
  final double wasteThreshold;
  final bool? isActive;
  final String? notes;
  final String? image;
  final double? thickness;
  final String? thicknessUnit;
  final bool? isCatalogMaterial;
  final bool? isCatalogPriced;
  final double? catalogPrice;
  final List<Size> sizes;
  final List<FoamDensity> foamDensities;
  final List<FoamThickness> foamThicknesses;
  final String? createdAt;
  final String? updatedAt;

  MaterialModel({
    required this.id,
    required this.name,
    this.category,
    this.subCategory,
    this.size,
    this.color,
    this.unit,
    this.standardWidth,
    this.standardLength,
    this.standardUnit,
    this.pricePerSqm,
    this.pricePerUnit,
    this.pricingUnit,
    this.types = const [],
    this.sizeVariants = const [],
    this.foamVariants = const [],
    this.commonThicknesses = const [], // NEW
    this.wasteThreshold = 0.75,
    this.isActive,
    this.notes,
    this.image,
    this.thickness,
    this.thicknessUnit,
    this.isCatalogMaterial,
    this.isCatalogPriced,
    this.catalogPrice,
    this.sizes = const [],
    this.foamDensities = const [],
    this.foamThicknesses = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'],
      subCategory: json['subCategory'],
      size: json['size']?.toString(),
      color: json['color'],
      unit: json['unit'],
      standardWidth: _asDouble(json['standardWidth']),
      standardLength: _asDouble(json['standardLength']),
      standardUnit: json['standardUnit'],
      pricePerSqm: _asDouble(json['pricePerSqm']),
      pricePerUnit: _asDouble(json['pricePerUnit']),
      pricingUnit: json['pricingUnit'],
      types:
          (json['types'] as List?)
              ?.map((t) => MaterialType.fromJson(t))
              .toList() ??
          [],
      sizeVariants:
          (json['sizeVariants'] as List?)
              ?.map((s) => SizeVariant.fromJson(s))
              .toList() ??
          [],
      foamVariants:
          (json['foamVariants'] as List?)
              ?.map((f) => FoamVariant.fromJson(f))
              .toList() ??
          [],
      commonThicknesses:
          (json['commonThicknesses'] as List?)
              ?.map((c) => CommonThickness.fromJson(c))
              .toList() ??
          [], // NEW
      wasteThreshold: _asDouble(json['wasteThreshold']) ?? 0.75,
      isActive: json['isActive'],
      notes: json['notes'],
      image: json['image'],
      thickness: _asDouble(json['thickness']),
      thicknessUnit: json['thicknessUnit'],
      isCatalogMaterial: json['isCatalogMaterial'],
      isCatalogPriced: json['isCatalogPriced'],
      catalogPrice: _asDouble(json['catalogPrice']),
      sizes:
          (json['sizes'] as List?)?.map((s) => Size.fromJson(s)).toList() ?? [],
      foamDensities:
          (json['foamDensities'] as List?)
              ?.map((f) => FoamDensity.fromJson(f))
              .toList() ??
          [],
      foamThicknesses:
          (json['foamThicknesses'] as List?)
              ?.map((f) => FoamThickness.fromJson(f))
              .toList() ??
          [],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      if (category != null) 'category': category,
      if (subCategory != null) 'subCategory': subCategory,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
      if (unit != null) 'unit': unit,
      if (standardWidth != null) 'standardWidth': standardWidth,
      if (standardLength != null) 'standardLength': standardLength,
      if (standardUnit != null) 'standardUnit': standardUnit,
      if (pricePerSqm != null) 'pricePerSqm': pricePerSqm,
      if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
      if (pricingUnit != null) 'pricingUnit': pricingUnit,
      'types': types.map((t) => t.toJson()).toList(),
      'sizeVariants': sizeVariants.map((s) => s.toJson()).toList(),
      'foamVariants': foamVariants.map((f) => f.toJson()).toList(),
      'commonThicknesses': commonThicknesses
          .map((c) => c.toJson())
          .toList(), // NEW
      'wasteThreshold': wasteThreshold,
      if (isActive != null) 'isActive': isActive,
      if (notes != null) 'notes': notes,
      if (image != null) 'image': image,
      if (thickness != null) 'thickness': thickness,
      if (thicknessUnit != null) 'thicknessUnit': thicknessUnit,
      if (isCatalogMaterial != null) 'isCatalogMaterial': isCatalogMaterial,
      if (isCatalogPriced != null) 'isCatalogPriced': isCatalogPriced,
      if (catalogPrice != null) 'catalogPrice': catalogPrice,
      'sizes': sizes.map((s) => s.toJson()).toList(),
      'foamDensities': foamDensities.map((f) => f.toJson()).toList(),
      'foamThicknesses': foamThicknesses.map((f) => f.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

class CommonThickness {
  final double thickness;
  final String unit;

  CommonThickness({required this.thickness, required this.unit});

  factory CommonThickness.fromJson(Map<String, dynamic> json) {
    return CommonThickness(
      thickness: json['thickness']?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'mm',
    );
  }

  Map<String, dynamic> toJson() {
    return {'thickness': thickness, 'unit': unit};
  }
}

class MaterialType {
  final String name;
  final double? pricePerSqm;
  final double? standardWidth;
  final double? standardLength;

  MaterialType({
    required this.name,
    this.pricePerSqm,
    this.standardWidth,
    this.standardLength,
  });

  factory MaterialType.fromJson(Map<String, dynamic> json) {
    return MaterialType(
      name: json['name'] ?? '',
      pricePerSqm: json['pricePerSqm']?.toDouble(),
      standardWidth: json['standardWidth']?.toDouble(),
      standardLength: json['standardLength']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (pricePerSqm != null) 'pricePerSqm': pricePerSqm,
      if (standardWidth != null) 'standardWidth': standardWidth,
      if (standardLength != null) 'standardLength': standardLength,
    };
  }
}

class SizeVariant {
  final String name;
  final double width;
  final double length;
  final String? unit;
  final double? pricePerUnit;

  SizeVariant({
    required this.name,
    required this.width,
    required this.length,
    this.unit,
    this.pricePerUnit,
  });

  factory SizeVariant.fromJson(Map<String, dynamic> json) {
    return SizeVariant(
      name: json['name'] ?? '',
      width: json['width']?.toDouble() ?? 0.0,
      length: json['length']?.toDouble() ?? 0.0,
      unit: json['unit'],
      pricePerUnit: json['pricePerUnit']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'width': width,
      'length': length,
      if (unit != null) 'unit': unit,
      if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
    };
  }
}

class FoamVariant {
  final double thickness;
  final String thicknessUnit;
  final String? density;
  final double width;
  final double length;
  final String dimensionUnit;
  final double? pricePerSqm;

  FoamVariant({
    required this.thickness,
    required this.thicknessUnit,
    this.density,
    required this.width,
    required this.length,
    required this.dimensionUnit,
    this.pricePerSqm,
  });

  factory FoamVariant.fromJson(Map<String, dynamic> json) {
    return FoamVariant(
      thickness: json['thickness']?.toDouble() ?? 0.0,
      thicknessUnit: json['thicknessUnit'] ?? 'inches',
      density: json['density'],
      width: json['width']?.toDouble() ?? 0.0,
      length: json['length']?.toDouble() ?? 0.0,
      dimensionUnit: json['dimensionUnit'] ?? 'inches',
      pricePerSqm: json['pricePerSqm']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thickness': thickness,
      'thicknessUnit': thicknessUnit,
      if (density != null) 'density': density,
      'width': width,
      'length': length,
      'dimensionUnit': dimensionUnit,
      if (pricePerSqm != null) 'pricePerSqm': pricePerSqm,
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
