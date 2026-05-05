import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Quotation/Api/materialService.dart';
import 'package:wworker/App/Quotation/Model/MaterialCostModel.dart';
import 'package:wworker/App/Quotation/Model/Materialmodel.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';

class AddMaterialCard extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final bool showHeader;
  final void Function(Map<String, dynamic>)? onAddItem;

  const AddMaterialCard({
    super.key,
    this.title = "Add Materials",
    this.icon,
    this.color,
    this.showHeader = true,
    this.onAddItem,
  });

  @override
  State<AddMaterialCard> createState() => _AddMaterialCardState();
}

class _AddMaterialCardState extends State<AddMaterialCard> {
  final MaterialService _materialService = MaterialService();
  final NumberFormat _thousands = NumberFormat.decimalPattern();

  final List<String> linearUnits = ["mm", "cm", "m", "ft", "inches"];
  final TextEditingController thicknessController = TextEditingController();

  // API Data
  List<MaterialModel> _materials = [];
  List<Map<String, dynamic>> _groupedCategories = [];
  final Map<String, Map<String, dynamic>> _dimensionRulesByCategory = {};
  int _selectedCategoryIndex = 0;
  int _selectedSubCategoryIndex = 0;
  String? _selectedVariantId;
  bool _isLoadingMaterials = true;
  MaterialModel? _selectedMaterial;
  String? _selectedMaterialType;
  String? _dimensionUnit; // Unit for requiredWidth/requiredLength sent to API
  Map<String, dynamic>? _activeDimensionRule;

  // Foam-specific selections
  FoamVariant? _selectedFoamVariant;

  // Project/Required dimensions
  String? width, length, thickness, unit;

  // Available thicknesses from API
  List<String> _availableThicknesses = [];

  // API calculation result
  MaterialCostModel? _costCalculation;
  bool _isCalculating = false;

  // Text controllers for manual input
  final TextEditingController materialTypeController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController manualUnitPriceController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  @override
  void dispose() {
    materialTypeController.dispose();
    widthController.dispose();
    lengthController.dispose();
    thicknessController.dispose();
    quantityController.dispose();
    manualUnitPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoadingMaterials = true);
    final results = await Future.wait([
      _materialService.getAllMaterials(limit: 500),
      _materialService.getGroupedMaterials(limit: 500),
    ]);

    final allMaterialsResult = results[0];
    final materials =
        allMaterialsResult['success'] == true &&
            allMaterialsResult['data'] is List
        ? (allMaterialsResult['data'] as List)
              .whereType<Map>()
              .map((e) => MaterialModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <MaterialModel>[];

    final rulesRaw = allMaterialsResult['dimensionRulesByCategory'];
    final rulesList = rulesRaw is List
        ? rulesRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    final groupedResult = results[1];
    final groupedData =
        groupedResult['success'] == true && groupedResult['data'] is List
        ? (groupedResult['data'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    setState(() {
      _materials = materials;
      _groupedCategories = groupedData;
      _dimensionRulesByCategory.clear();
      for (final rule in rulesList) {
        final category = (rule['category'] ?? '').toString().trim();
        if (category.isNotEmpty) {
          _dimensionRulesByCategory[category.toLowerCase()] = rule;
        }
      }
      _isLoadingMaterials = false;

      // Prefer auto-selecting the first grouped variant if available.
      if (_selectedMaterial == null) {
        final first = _firstGroupedVariant();
        if (first != null) {
          _selectGroupedVariant(
            category: first.$1,
            subCategory: first.$2,
            variant: first.$3,
            categoryIndex: first.$4,
            subCategoryIndex: first.$5,
          );
        } else if (_materials.isNotEmpty) {
          _selectedMaterial = _materials.first;
          _setDefaultUnitsForMaterial(_materials.first);
          _loadThicknessesForMaterial(_materials.first);
        }
      }
    });
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  double? _parseSingleSizeValue(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final matches = RegExp(r'(\d+(?:\.\d+)?|\d+\s*/\s*\d+)')
        .allMatches(value)
        .map((m) => m.group(0) ?? '')
        .where((v) => v.trim().isNotEmpty)
        .toList();

    if (matches.length != 1) return null;

    final token = matches.first.replaceAll(' ', '');
    final fraction = RegExp(r'^(\d+)/(\d+)$').firstMatch(token);
    if (fraction != null) {
      final numerator = double.tryParse(fraction.group(1) ?? '');
      final denominator = double.tryParse(fraction.group(2) ?? '');
      if (numerator != null && denominator != null && denominator != 0) {
        return numerator / denominator;
      }
    }

    return double.tryParse(token);
  }

  String? _normalizeLinearUnit(String? raw) {
    final v = raw?.toLowerCase().trim();
    if (v == null || v.isEmpty) return null;
    if (v == 'in' || v == 'inch' || v == 'inches' || v.contains('"')) {
      return 'inches';
    }
    if (v == 'feet' || v == 'foot') return 'ft';
    if (v == 'meter' || v == 'meters') return 'm';
    if (v == 'centimeter' || v == 'centimeters') return 'cm';
    if (v == 'millimeter' || v == 'millimeters') return 'mm';
    if (linearUnits.contains(v)) return v;
    return null;
  }

  String _cleanGroupLabel(String raw) {
    // Some catalog-derived strings may contain stray quotes; strip them for UI.
    return raw.replaceAll('"', '').replaceAll(r'\"', '').trim();
  }

  String _cleanVariantSizeLabel(String raw) {
    return raw.replaceAll('"', '').replaceAll(r'\"', '').trim();
  }

  List<double>? _parseSizeTriplet(String raw) {
    // Examples: 1"x10"x144", 1 x 10 x 144, 0.5" x 48" x 96"
    final s = raw.trim();
    if (s.isEmpty) return null;
    final matches = RegExp(r'(\d+(?:\.\d+)?|\d+\s*/\s*\d+)')
        .allMatches(s)
        .map((m) => m.group(0) ?? '')
        .where((v) => v.trim().isNotEmpty)
        .toList();
    if (matches.length < 2) return null;

    double? parseOne(String token) {
      final t = token.replaceAll(' ', '');
      final frac = RegExp(r'^(\\d+)/(\\d+)$').firstMatch(t);
      if (frac != null) {
        final num = double.tryParse(frac.group(1) ?? '');
        final den = double.tryParse(frac.group(2) ?? '');
        if (num != null && den != null && den != 0) return num / den;
      }
      return double.tryParse(t);
    }

    final nums = matches.map(parseOne).whereType<double>().toList();
    if (nums.length < 2) return null;
    // Prefer 3 numbers if present: thickness x width x length
    if (nums.length >= 3) return nums.take(3).toList();
    return nums.take(2).toList();
  }

  bool _isDimensionSizeLabel(String raw) {
    final triplet = _parseSizeTriplet(raw);
    return triplet != null && triplet.length >= 3;
  }

  void _setAutoMaterialName({
    String? category,
    String? subCategory,
    String? size,
  }) {
    final sub = _cleanGroupLabel((subCategory ?? '').trim());
    final cat = _cleanGroupLabel((category ?? '').trim());
    final sz = _cleanVariantSizeLabel((size ?? '').trim());
    final base = sub.isNotEmpty
        ? sub
        : (cat.isNotEmpty ? cat : _selectedMaterial?.name ?? '');
    final value = sz.isNotEmpty ? '$base $sz' : base;
    if (value.trim().isNotEmpty) {
      materialTypeController.text = value.trim();
    }
  }

  void _prefillProjectSizeAndUnit(MaterialModel material) {
    final su = _normalizeLinearUnit(material.standardUnit);

    if (su != null &&
        ((unit == null || !linearUnits.contains(unit)) ||
            _dimensionUnit == null)) {
      _dimensionUnit = su;
      unit = su;
    }

    // Project width/length are intentionally not prefilled from stock dimensions.
  }

  (String, String, Map<String, dynamic>, int, int)? _firstGroupedVariant() {
    if (_groupedCategories.isEmpty) return null;
    for (var ci = 0; ci < _groupedCategories.length; ci++) {
      final category = _cleanGroupLabel(
        (_groupedCategories[ci]['category'] ?? '').toString(),
      );
      final subCats = _groupedCategories[ci]['subCategories'];
      if (subCats is! List) continue;
      for (var si = 0; si < subCats.length; si++) {
        final sub = subCats[si];
        if (sub is! Map) continue;
        final rawSub = _cleanGroupLabel((sub['subCategory'] ?? '').toString());
        final subCategory = rawSub.isEmpty ? category : rawSub;
        final variants = sub['variants'];
        if (variants is! List || variants.isEmpty) continue;
        final firstVariant = variants.first;
        if (firstVariant is! Map) continue;
        return (
          category,
          subCategory,
          Map<String, dynamic>.from(firstVariant),
          ci,
          si,
        );
      }
    }
    return null;
  }

  MaterialModel _resolveMaterialFromVariant({
    required String category,
    required String subCategory,
    required Map<String, dynamic> variant,
  }) {
    final id = (variant['id'] ?? variant['_id'] ?? '').toString();
    if (id.isNotEmpty) {
      try {
        return _materials.firstWhere((m) => m.id == id);
      } catch (_) {
        // Fall through to minimal model construction.
      }
    }

    final pricePerUnit =
        _asDouble(variant['pricePerUnit']) ??
        _asDouble(variant['catalogPrice']);
    final pricePerSqm = _asDouble(variant['pricePerSqm']);

    final dimensionRule = variant['dimensionRule'] is Map
        ? Map<String, dynamic>.from(variant['dimensionRule'] as Map)
        : <String, dynamic>{};
    final stockDimensions = dimensionRule['stockDimensions'] is Map
        ? Map<String, dynamic>.from(dimensionRule['stockDimensions'] as Map)
        : <String, dynamic>{};

    final sizeLabel = (variant['size'] ?? '').toString();

    return MaterialModel(
      id: id,
      name: (variant['name'] ?? '').toString(),
      category: category,
      subCategory: subCategory,
      size: sizeLabel,
      unit: (variant['unit'] ?? '').toString(),
      color: (variant['color'] ?? '').toString(),
      pricingUnit: (variant['pricingUnit'] ?? '').toString(),
      catalogKey: variant['catalogKey']?.toString(),
      dimensionRule: dimensionRule.isEmpty ? null : dimensionRule,
      pricePerUnit: pricePerUnit,
      pricePerSqm: pricePerSqm,
      catalogPrice: _asDouble(variant['catalogPrice']),
      isCatalogMaterial: variant['isCatalogMaterial'] == true,
      isCatalogPriced: variant['isCatalogPriced'] == true,
      isPriced: variant['isPriced'] == true,
      thickness:
          _asDouble(variant['thickness']) ??
          _asDouble(stockDimensions['thickness']) ??
          _parseSingleSizeValue(sizeLabel),
      thicknessUnit: (variant['thicknessUnit'] ?? stockDimensions['unit'])
          ?.toString(),
      standardWidth:
          _asDouble(variant['standardWidth']) ??
          _asDouble(stockDimensions['width']),
      standardLength:
          _asDouble(variant['standardLength']) ??
          _asDouble(stockDimensions['length']),
      standardUnit:
          variant['standardUnit']?.toString() ??
          stockDimensions['unit']?.toString(),
    );
  }

  Map<String, dynamic>? _categoryRuleFor(String? category) {
    final key = category?.trim().toLowerCase();
    if (key == null || key.isEmpty) return null;
    return _dimensionRulesByCategory[key];
  }

  bool _isTruthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == 'yes' || text == '1';
  }

  Map<String, dynamic>? _effectiveDimensionRule() {
    return _activeDimensionRule ??
        _selectedMaterial?.dimensionRule ??
        _categoryRuleFor(_selectedMaterial?.category);
  }

  bool _requiresProjectSize(MaterialModel? material) {
    if (material == null) return true;

    final rule = _effectiveDimensionRule();
    final projectInput = rule?['projectInput'] is Map
        ? Map<String, dynamic>.from(rule!['projectInput'] as Map)
        : <String, dynamic>{};
    final stockDimensions = rule?['stockDimensions'] is Map
        ? Map<String, dynamic>.from(rule!['stockDimensions'] as Map)
        : <String, dynamic>{};

    final showWidth = projectInput.containsKey('showWidth')
        ? _isTruthy(projectInput['showWidth'])
        : null;
    final showLength = projectInput.containsKey('showLength')
        ? _isTruthy(projectInput['showLength'])
        : null;
    final requireWidth = projectInput.containsKey('requireWidth')
        ? _isTruthy(projectInput['requireWidth'])
        : null;
    final requireLength = projectInput.containsKey('requireLength')
        ? _isTruthy(projectInput['requireLength'])
        : null;

    if (showWidth == false && showLength == false) return false;
    if (showWidth == true ||
        showLength == true ||
        requireWidth == true ||
        requireLength == true) {
      return true;
    }

    final schema = rule?['schema']?.toString().toLowerCase();
    if (schema == 'unit_based' || schema == 'quantity_based') return false;
    if (schema == 'area_based' || schema == 'sheet_based') return true;

    if (_isTruthy(projectInput['requiresDimensions']) ||
        _isTruthy(projectInput['requiresProjectSize']) ||
        _isTruthy(rule?['requiresDimensions']) ||
        _isTruthy(rule?['requiresProjectSize'])) {
      return true;
    }

    if (_isTruthy(projectInput['quantityOnly']) ||
        _isTruthy(projectInput['useQuantityOnly']) ||
        _isTruthy(rule?['quantityOnly']) ||
        _isTruthy(rule?['useQuantityOnly'])) {
      return false;
    }

    final mode = [
      projectInput['mode'],
      projectInput['calculationMode'],
      rule?['mode'],
      rule?['calculationMode'],
    ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');

    if (mode.contains('quantity')) return false;
    if (mode.contains('sheet') || mode.contains('dimension')) return true;

    final category = (material.category ?? '').trim().toUpperCase();
    if (category == 'BOARD' || category == 'WOOD') {
      return true;
    }

    final hasSqmPricing = (material.pricePerSqm ?? 0) > 0;
    final hasDimensionCharacteristics =
        (material.standardWidth ?? 0) > 0 ||
        (material.standardLength ?? 0) > 0 ||
        _asDouble(stockDimensions['width']) != null ||
        _asDouble(stockDimensions['length']) != null ||
        material.sizeVariants.isNotEmpty ||
        material.foamVariants.isNotEmpty ||
        material.commonThicknesses.isNotEmpty ||
        material.foamThicknesses.isNotEmpty ||
        material.thickness != null ||
        _isTruthy(projectInput['defaultToProjectSize']) ||
        _isTruthy(rule?['defaultToProjectSize']);

    if (hasSqmPricing) return true;
    if (hasDimensionCharacteristics) return true;

    return false;
  }

  bool _requiresThickness(MaterialModel? material) {
    if (material == null) return false;
    if (material.foamVariants.isNotEmpty ||
        material.foamThicknesses.isNotEmpty ||
        material.commonThicknesses.isNotEmpty ||
        material.thickness != null) {
      return true;
    }

    final rule = _effectiveDimensionRule();
    final stockDimensions = rule?['stockDimensions'] is Map
        ? Map<String, dynamic>.from(rule!['stockDimensions'] as Map)
        : <String, dynamic>{};
    final projectInput = rule?['projectInput'] is Map
        ? Map<String, dynamic>.from(rule!['projectInput'] as Map)
        : <String, dynamic>{};

    return _asDouble(stockDimensions['thickness']) != null ||
        _isTruthy(projectInput['requiresThickness']) ||
        _isTruthy(rule?['requiresThickness']);
  }

  bool _usesQuantityBasedInput(MaterialModel? material) {
    return !_requiresProjectSize(material);
  }

  bool _isFixedVariantThickness(MaterialModel? material) {
    if (material == null) return false;
    final category = (material.category ?? '').trim().toUpperCase();
    final isBoardOrWood = category == 'BOARD' || category == 'WOOD';
    final hasResolvedThickness =
        material.thickness != null || (thickness ?? '').trim().isNotEmpty;
    return isBoardOrWood && hasResolvedThickness;
  }

  String _quantityInputLabel(MaterialModel? material) {
    final raw = (material?.pricingUnit ?? material?.unit ?? 'unit')
        .trim()
        .toLowerCase();
    if (raw.isEmpty) return 'Quantity needed';
    if (raw == 'piece') return 'Pieces needed';
    if (raw == 'sheet') return 'Sheets needed';
    if (raw == 'roll') return 'Rolls needed';
    if (raw == 'pack') return 'Packs needed';
    return '${raw[0].toUpperCase()}${raw.substring(1)} needed';
  }

  String _unitPriceLabel(MaterialModel? material) {
    final raw = (material?.pricingUnit ?? material?.unit ?? 'unit')
        .trim()
        .toLowerCase();
    if (raw.isEmpty) return 'Price per unit';
    return 'Price per $raw';
  }

  String _formattedUnitPrice(MaterialModel? material) {
    final value = material?.pricePerUnit ?? material?.catalogPrice;
    if (value == null || value <= 0) return 'Unpriced';
    return 'N${_thousands.format(value.round())}';
  }

  bool _isUnpricedQuantityMaterial(MaterialModel? material) {
    if (!_usesQuantityBasedInput(material)) return false;
    final value = material?.pricePerUnit ?? material?.catalogPrice;
    return value == null || value <= 0;
  }

  double? _parseAmountInput(String text) {
    final clean = text.replaceAll(',', '').trim();
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  double? _effectiveUnitPriceForQuantityMaterial() {
    final manual = _parseAmountInput(manualUnitPriceController.text);
    if (manual != null && manual > 0) return manual;
    final material = _selectedMaterial;
    final fallback = material?.pricePerUnit ?? material?.catalogPrice;
    if (fallback != null && fallback > 0) return fallback;
    return null;
  }

  bool _effectiveNeedsPricing() {
    if (_costCalculation?.calculation.needsPricing == true) {
      return _parseAmountInput(manualUnitPriceController.text) == null;
    }
    if (_usesQuantityBasedInput(_selectedMaterial)) {
      return _effectiveUnitPriceForQuantityMaterial() == null;
    }
    return false;
  }

  double _effectiveProjectCost() {
    final calculatedTotal = _costCalculation?.pricing.totalMaterialCost;
    if (calculatedTotal != null && calculatedTotal > 0) {
      return calculatedTotal;
    }

    if (_costCalculation?.calculation.needsPricing == true) {
      final manualUnitPrice = _parseAmountInput(manualUnitPriceController.text);
      if (manualUnitPrice != null && manualUnitPrice > 0) {
        final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
        return manualUnitPrice * (quantity < 1 ? 1 : quantity);
      }
    }

    if (_usesQuantityBasedInput(_selectedMaterial)) {
      final unitPrice = _effectiveUnitPriceForQuantityMaterial() ?? 0;
      final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
      return unitPrice * (quantity < 1 ? 1 : quantity);
    }
    return _costCalculation?.pricing.projectCost ?? 0;
  }

  String? _resolvedThicknessValue() {
    final controllerValue = thicknessController.text.trim();
    if (controllerValue.isNotEmpty) return controllerValue;

    final selectedValue = thickness?.trim();
    if (selectedValue != null && selectedValue.isNotEmpty) {
      return selectedValue;
    }

    final materialThickness = _selectedMaterial?.thickness;
    if (materialThickness != null) {
      return materialThickness.toString();
    }

    final foamThickness = _selectedFoamVariant?.thickness;
    if (foamThickness != null) {
      return foamThickness.toString();
    }

    return null;
  }

  bool _shouldHideThicknessField() {
    if (!_requiresThickness(_selectedMaterial)) return false;

    final resolvedThickness = _resolvedThicknessValue();
    if (resolvedThickness == null || resolvedThickness.isEmpty) return false;

    final selectedVariantLooksLikeThickness =
        _selectedVariantId != null &&
        _groupedCategories.isNotEmpty &&
        _parseSingleSizeValue(_selectedMaterial?.size ?? '') != null;

    return selectedVariantLooksLikeThickness ||
        _availableThicknesses.isNotEmpty ||
        _selectedMaterial?.thickness != null ||
        _selectedFoamVariant != null;
  }

  void _prefillFromDimensionRule(Map<String, dynamic>? dimensionRule) {
    if (dimensionRule == null) return;
    final stockDimensions = dimensionRule['stockDimensions'] is Map
        ? Map<String, dynamic>.from(dimensionRule['stockDimensions'] as Map)
        : <String, dynamic>{};
    final projectInput = dimensionRule['projectInput'] is Map
        ? Map<String, dynamic>.from(dimensionRule['projectInput'] as Map)
        : <String, dynamic>{};

    final stockThickness = _asDouble(stockDimensions['thickness']);

    // Stock width/length describe the purchasable material, not the project size.
    if (stockThickness != null &&
        stockThickness > 0 &&
        thicknessController.text.trim().isEmpty) {
      thicknessController.text = stockThickness.toString();
      thickness = stockThickness.toString();
    }

    final normalized = _normalizeLinearUnit(
      stockDimensions['unit']?.toString() ??
          projectInput['defaultUnit']?.toString(),
    );
    if (normalized != null) {
      _dimensionUnit = normalized;
      unit = normalized;
    }
  }

  void _resetProjectSizeInputs() {
    widthController.clear();
    lengthController.clear();
    thicknessController.clear();
    quantityController.text = '1';
    manualUnitPriceController.clear();
    width = null;
    length = null;
    thickness = null;
    _costCalculation = null;
  }

  void _selectFirstVariantForCurrentSelection() {
    if (_selectedCategoryIndex < 0 ||
        _selectedCategoryIndex >= _groupedCategories.length) {
      return;
    }

    final categoryObj = _groupedCategories[_selectedCategoryIndex];
    final categoryName = _cleanGroupLabel(
      (categoryObj['category'] ?? '').toString(),
    );
    final subCatsRaw = categoryObj['subCategories'];
    final subCats = subCatsRaw is List
        ? subCatsRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];
    if (subCats.isEmpty) return;

    if (_selectedSubCategoryIndex >= subCats.length) {
      _selectedSubCategoryIndex = 0;
    }

    final subObj = subCats[_selectedSubCategoryIndex];
    final rawSubName = _cleanGroupLabel(
      (subObj['subCategory'] ?? '').toString(),
    );
    final subName = rawSubName.isEmpty ? categoryName : rawSubName;
    final variantsRaw = subObj['variants'];
    final variants = variantsRaw is List
        ? variantsRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    if (variants.isEmpty) return;
    _selectGroupedVariant(
      category: categoryName,
      subCategory: subName,
      variant: variants.first,
      categoryIndex: _selectedCategoryIndex,
      subCategoryIndex: _selectedSubCategoryIndex,
    );
  }

  void _selectGroupedVariant({
    required String category,
    required String subCategory,
    required Map<String, dynamic> variant,
    required int categoryIndex,
    required int subCategoryIndex,
  }) {
    _resetProjectSizeInputs();

    final resolved = _resolveMaterialFromVariant(
      category: category,
      subCategory: subCategory,
      variant: variant,
    );

    _selectedCategoryIndex = categoryIndex;
    _selectedSubCategoryIndex = subCategoryIndex;
    _selectedVariantId = (variant['id'] ?? variant['_id'] ?? '').toString();

    _onMaterialSelected(resolved);

    // Pre-fill the "material name/type" field to keep the flow smooth.
    final typeName = _cleanGroupLabel(subCategory).isNotEmpty
        ? _cleanGroupLabel(subCategory)
        : _cleanGroupLabel(category);
    if (typeName.isNotEmpty) {
      final sizeRaw = (variant['size'] ?? '').toString().trim();
      final size = _cleanVariantSizeLabel(sizeRaw);
      materialTypeController.text = size.isNotEmpty
          ? '$typeName $size'
          : typeName;
    } else {
      _setAutoMaterialName(
        category: category,
        subCategory: subCategory,
        size: (variant['size'] ?? '').toString(),
      );
    }

    final variantDimensionRule = variant['dimensionRule'] is Map
        ? Map<String, dynamic>.from(variant['dimensionRule'] as Map)
        : null;
    _activeDimensionRule = variantDimensionRule ?? _categoryRuleFor(category);
    if (variantDimensionRule != null) {
      _prefillFromDimensionRule(variantDimensionRule);
    } else {
      _prefillFromDimensionRule(_categoryRuleFor(category));
    }
  }

  Widget _buildGroupedSelector() {
    if (_groupedCategories.isEmpty) return const SizedBox.shrink();
    if (_selectedCategoryIndex >= _groupedCategories.length) {
      _selectedCategoryIndex = 0;
      _selectedSubCategoryIndex = 0;
    }

    final categoryObj = _groupedCategories[_selectedCategoryIndex];
    final categoryName = _cleanGroupLabel(
      (categoryObj['category'] ?? '').toString(),
    );
    final subCatsRaw = categoryObj['subCategories'];
    final subCats = subCatsRaw is List
        ? subCatsRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    if (_selectedSubCategoryIndex >= subCats.length) {
      _selectedSubCategoryIndex = 0;
    }

    final subObj = subCats.isNotEmpty
        ? subCats[_selectedSubCategoryIndex]
        : null;
    final rawSubName = _cleanGroupLabel(
      (subObj?['subCategory'] ?? '').toString(),
    );
    final subName = rawSubName.isEmpty ? categoryName : rawSubName;
    final variantsRaw = subObj?['variants'];
    final variants = variantsRaw is List
        ? variantsRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];
    final shouldHideVariantSizes =
        variants.isNotEmpty &&
        variants.every((v) {
          final sizeRaw = (v['size'] ?? '').toString().trim();
          return _isDimensionSizeLabel(sizeRaw);
        });

    if (shouldHideVariantSizes && variants.isNotEmpty) {
      final firstVariant = variants.first;
      final firstId = (firstVariant['id'] ?? firstVariant['_id'] ?? '')
          .toString();
      if (firstId.isNotEmpty && firstId != _selectedVariantId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectGroupedVariant(
              category: categoryName,
              subCategory: subName,
              variant: firstVariant,
              categoryIndex: _selectedCategoryIndex,
              subCategoryIndex: _selectedSubCategoryIndex,
            );
          });
        });
      }
    }

    final bool allSubLabelsSameAsCategory =
        subCats.isNotEmpty &&
        subCats.every((sc) {
          final s = _cleanGroupLabel((sc['subCategory'] ?? '').toString());
          return s.isEmpty || s == categoryName;
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _groupedCategories.asMap().entries.map((entry) {
              final idx = entry.key;
              final name = _cleanGroupLabel(
                (entry.value['category'] ?? '').toString(),
              );
              final selected = idx == _selectedCategoryIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(name),
                  selected: selected,
                  selectedColor: const Color(0xFFFFF3E8),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF8B4513)
                        : const Color(0xFFE8DED6),
                  ),
                  labelStyle: GoogleFonts.openSans(
                    color: selected
                        ? const Color(0xFF8B4513)
                        : const Color(0xFF756A61),
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryIndex = idx;
                      _selectedSubCategoryIndex = 0;
                      _selectedVariantId = null;
                      _resetProjectSizeInputs();
                    });
                    _selectFirstVariantForCurrentSelection();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        if (subCats.isNotEmpty && !allSubLabelsSameAsCategory)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subCats.asMap().entries.map((entry) {
                final idx = entry.key;
                final raw = _cleanGroupLabel(
                  (entry.value['subCategory'] ?? '').toString(),
                );
                final name = raw.isEmpty ? categoryName : raw;
                final selected = idx == _selectedSubCategoryIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(name),
                    selected: selected,
                    selectedColor: const Color(0xFFFFF3E8),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF8B4513)
                          : const Color(0xFFE8DED6),
                    ),
                    labelStyle: GoogleFonts.openSans(
                      color: selected
                          ? const Color(0xFF8B4513)
                          : const Color(0xFF756A61),
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedSubCategoryIndex = idx;
                        _selectedVariantId = null;
                        _resetProjectSizeInputs();
                      });
                      _selectFirstVariantForCurrentSelection();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 10),
        if (variants.isEmpty)
          Text(
            "No variants found for $categoryName / $subName",
            style: GoogleFonts.openSans(color: const Color(0xFF7B7B7B)),
          )
        else if (shouldHideVariantSizes)
          const SizedBox.shrink()
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: variants.map((v) {
              final id = (v['id'] ?? v['_id'] ?? '').toString();
              final sizeRaw = (v['size'] ?? '').toString().trim();
              final size = _cleanVariantSizeLabel(sizeRaw);
              final selected = id.isNotEmpty && id == _selectedVariantId;

              // Selection card should not repeat unit/price; those are shown elsewhere.
              final label = size.isNotEmpty
                  ? size
                  : (v['name'] ?? '').toString();

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectGroupedVariant(
                      category: categoryName,
                      subCategory: subName,
                      variant: v,
                      categoryIndex: _selectedCategoryIndex,
                      subCategoryIndex: _selectedSubCategoryIndex,
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF8B4513)
                          : const Color(0xFFE8DED6),
                    ),
                    color: selected ? const Color(0xFFFFF3E8) : Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.openSans(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF302E2E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Set default units based on material type
  /// Set default units based on material type
  void _setDefaultUnitsForMaterial(MaterialModel material) {
    // For project dimensions we need linear units (mm/cm/m/ft/inches).
    final resolvedDimensionUnit =
        _normalizeLinearUnit(material.standardUnit) ??
        _normalizeLinearUnit(material.thicknessUnit) ??
        _normalizeLinearUnit(
          _categoryRuleFor(
            material.category,
          )?['projectInput']?['defaultUnit']?.toString(),
        ) ??
        _dimensionUnit ??
        'inches';
    _dimensionUnit = resolvedDimensionUnit;
    unit = resolvedDimensionUnit;

    // ✅ Update state AFTER build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          unit = unit;
        });
      }
    });
  }

  /// Load available thicknesses from material data
  /// Load available thicknesses from material data
  void _loadThicknessesForMaterial(MaterialModel material) {
    List<String> thicknesses = [];

    // 1. Foam-specific thicknesses
    if (material.foamThicknesses.isNotEmpty) {
      thicknesses.addAll(
        material.foamThicknesses.map((ft) => ft.thickness.toString()).toList(),
      );
    }

    if (material.foamVariants.isNotEmpty) {
      thicknesses.addAll(
        material.foamVariants.map((fv) => fv.thickness.toString()).toList(),
      );
    }

    // 2. Common thicknesses
    if (material.commonThicknesses.isNotEmpty) {
      thicknesses.addAll(
        material.commonThicknesses
            .map((ct) => ct.thickness.toString())
            .toList(),
      );
    }

    // Remove duplicates and sort
    thicknesses = thicknesses.toSet().toList();
    if (thicknesses.isNotEmpty) {
      thicknesses.sort((a, b) => double.parse(a).compareTo(double.parse(b)));
    }

    // ✅ Update state AFTER build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _availableThicknesses = thicknesses;

          // Auto-set the thickness if it's null or invalid
          if (thicknesses.isNotEmpty) {
            if (thickness == null || !thicknesses.contains(thickness)) {
              thickness = thicknesses.first;
            }
          } else {
            thickness = null;
          }
        });
      }
    });
  }

  void _onMaterialSelected(MaterialModel material) {
    setState(() {
      _selectedMaterial = material;
      _selectedMaterialType = null;
      _selectedFoamVariant = null;
      _activeDimensionRule =
          material.dimensionRule ?? _categoryRuleFor(material.category);
      materialTypeController.clear();

      // Auto-set units based on material type
      _setDefaultUnitsForMaterial(material);

      // Load thicknesses for this material
      _loadThicknessesForMaterial(material);

      // Thickness from API (if present); otherwise allow user input later.
      thicknessController.text = material.thickness?.toString() ?? '';
      if (material.thickness != null) {
        thickness = material.thickness!.toString();
      }

      _setAutoMaterialName(
        category: material.category,
        subCategory: material.subCategory,
        size: material.size,
      );
    });

    // Prefill project size + unit from API standard dims/unit (without overwriting user input).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefillProjectSizeAndUnit(material);
      if (!_requiresProjectSize(material)) {
        _calculateCosts();
      }
    });
  }

  void _onFoamVariantSelected(FoamVariant? variant) {
    setState(() {
      _selectedFoamVariant = variant;
      if (variant != null) {
        // Set the material type to show which foam is selected
        materialTypeController.text =
            '${variant.thickness}${variant.thicknessUnit} ${variant.density ?? ""}';
        // Auto-set thickness from foam variant
        thickness = variant.thickness.toString();
      }
    });
    _calculateCosts();
  }

  /// Calculate costs via API (auto-triggered)
  Future<void> _calculateCosts() async {
    final material = _selectedMaterial;
    if (material == null) {
      return;
    }

    final requiresProjectSize = _requiresProjectSize(material);
    final requiresThickness = _requiresThickness(material);
    final quantity = int.tryParse(quantityController.text.trim()) ?? 1;

    final t = _resolvedThicknessValue() ?? '';
    if (requiresThickness && t.isEmpty) return;

    double? w;
    double? l;

    if (requiresProjectSize) {
      if (widthController.text.isEmpty ||
          lengthController.text.isEmpty ||
          _dimensionUnit == null) {
        return;
      }

      w = double.tryParse(widthController.text);
      l = double.tryParse(lengthController.text);
      if (w == null || l == null) return;
    }

    setState(() => _isCalculating = true);

    try {
      final result = await _materialService.calculateMaterialCost(
        materialId: material.id,
        requiredWidth: w,
        requiredLength: l,
        requiredUnit: requiresProjectSize ? _dimensionUnit : null,
        materialType: _selectedMaterialType,
        foamThickness: _selectedFoamVariant?.thickness,
        foamDensity: _selectedFoamVariant?.density,
        quantity: quantity < 1 ? 1 : quantity,
      );

      if (mounted) {
        setState(() {
          _costCalculation = result;
          _isCalculating = false;
        });

        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to calculate costs. Please try again."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCalculating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleAddItem() {
    final material = _selectedMaterial;
    final requiresProjectSize = _requiresProjectSize(material);
    final requiresThickness = _requiresThickness(material);
    final usesQuantityBasedInput = _usesQuantityBasedInput(material);
    final manualUnitPrice = _parseAmountInput(manualUnitPriceController.text);
    final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
    final thicknessValue = _resolvedThicknessValue();
    final needsManualPrice = _costCalculation?.calculation.needsPricing == true;

    // Validate all required fields
    if (material == null ||
        materialTypeController.text.trim().isEmpty ||
        (requiresProjectSize && widthController.text.isEmpty) ||
        (requiresProjectSize && lengthController.text.isEmpty) ||
        (requiresProjectSize && unit == null) ||
        (_usesQuantityBasedInput(material) && quantity < 1) ||
        (requiresThickness &&
            (thicknessValue == null || thicknessValue.isEmpty)) ||
        _costCalculation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill in all fields and calculate costs before adding.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (needsManualPrice && (manualUnitPrice == null || manualUnitPrice <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Enter a manual price before adding this unpriced material.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final normalizedQuantity = quantity < 1 ? 1 : quantity;
    final lineTotal = needsManualPrice
        ? (manualUnitPrice! * normalizedQuantity)
        : _costCalculation!.pricing.totalMaterialCost;
    final unitPrice = normalizedQuantity > 0
        ? lineTotal / normalizedQuantity
        : lineTotal;
    final calculationPayload = {
      "mode": _costCalculation!.calculation.mode,
      "minimumUnits": _costCalculation!.calculation.minimumUnits,
      "billableUnits": _costCalculation!.calculation.billableUnits,
      "quantity": _costCalculation!.calculation.quantity,
      "needsPricing": needsManualPrice,
      "pricePerSqm": _costCalculation!.pricing.pricePerSqm,
      "pricePerUnit": needsManualPrice
          ? manualUnitPrice
          : _costCalculation!.pricing.pricePerUnit,
      "pricePerFullUnit": _costCalculation!.pricing.pricePerFullUnit,
      "totalMaterialCost": lineTotal,
    };

    // Create item with API calculation results
    final item = {
      "materialId": material.id,
      "name": material.name,
      "category": material.category,
      "subCategory": material.subCategory,
      "Product": material.name,
      "Materialname": materialTypeController.text.trim(),
      "Width": requiresProjectSize ? widthController.text : "",
      "Length": requiresProjectSize ? lengthController.text : "",
      "Thickness": requiresThickness ? thicknessValue : "",
      "Unit": requiresProjectSize ? unit : "",
      "materialUnit": material.unit,
      "Sqm": usesQuantityBasedInput
          ? ""
          : _costCalculation!.dimensions.projectAreaSqm.toStringAsFixed(2),
      "Price": lineTotal.toStringAsFixed(2),
      "unitPrice": unitPrice.toStringAsFixed(2),
      "LineTotal": lineTotal.toStringAsFixed(2),
      "needsPricing": false,
      "quantity": normalizedQuantity.toString(),
      "billableUnits": _costCalculation!.calculation.billableUnits,
      "calculation": calculationPayload,
    };

    widget.onAddItem?.call(item);

    // Reset form (but keep material selection, units, and thickness)
    setState(() {
      _selectedMaterialType = null;
      _selectedFoamVariant = null;
      widthController.clear();
      lengthController.clear();
      quantityController.text = '1';
      manualUnitPriceController.clear();
      _costCalculation = null;
      if (_selectedMaterial != null) {
        _setAutoMaterialName(
          category: _selectedMaterial!.category,
          subCategory: _selectedMaterial!.subCategory,
          size: _selectedMaterial!.size,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Material added successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFoam = _selectedMaterial?.category?.toUpperCase() == 'FOAM';
    final hasFoamVariants = _selectedMaterial?.foamVariants.isNotEmpty ?? false;
    final requiresProjectSize = _requiresProjectSize(_selectedMaterial);
    final requiresThickness = _requiresThickness(_selectedMaterial);
    final usesQuantityBasedInput = _usesQuantityBasedInput(_selectedMaterial);
    final isFixedVariantThickness = _isFixedVariantThickness(_selectedMaterial);
    final isUnpricedQuantityMaterial = _isUnpricedQuantityMaterial(
      _selectedMaterial,
    );
    final shouldHideThicknessField = _shouldHideThicknessField();
    final resolvedThicknessValue = _resolvedThicknessValue();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            _buildMaterialCardHeader(),
            const SizedBox(height: 14),
          ],
          // Header row
          if (_isLoadingMaterials)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isLoadingMaterials)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const SizedBox.shrink(),
              ],
            )
          else
            const SizedBox.shrink(),

          if (_isLoadingMaterials) const SizedBox(height: 16),

          // Material selection
          if (_isLoadingMaterials)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_materials.isEmpty && _groupedCategories.isEmpty)
            Center(
              child: Text(
                "No materials available",
                style: GoogleFonts.openSans(color: const Color(0xFF7B7B7B)),
              ),
            )
          else if (_groupedCategories.isNotEmpty)
            _buildGroupedSelector()
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _materials.map((material) {
                  final selected = _selectedMaterial?.id == material.id;
                  return GestureDetector(
                    onTap: () => _onMaterialSelected(material),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFA16438)
                              : const Color(0xFFCCA183),
                        ),
                        color: selected
                            ? const Color(0xFFFFF3E0)
                            : Colors.transparent,
                      ),
                      child: Text(
                        material.name,
                        style: GoogleFonts.openSans(
                          color: selected
                              ? const Color(0xFFA16438)
                              : const Color(0xFFCCA183),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 16),

          // Foam Variants Selection (if foam material)
          if (isFoam && hasFoamVariants) _buildFoamVariantSelection(),

          // Material name is auto-generated from the selected material and hidden from UI.
          const SizedBox(height: 10),

          // Display standard material info (read-only from API)
          if (_selectedMaterial != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedMaterial!.standardWidth != null &&
                      _selectedMaterial!.standardLength != null)
                    _buildInfoRow(
                      "Standard Size:",
                      "${_selectedMaterial!.standardWidth} × ${_selectedMaterial!.standardLength} ${_selectedMaterial!.standardUnit ?? ''}",
                    ),
                  if (_selectedMaterial!.pricePerSqm != null &&
                      _selectedMaterial!.pricePerSqm! > 0) ...[
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      "Price per sq m:",
                      "₦${_selectedMaterial!.pricePerSqm!.toStringAsFixed(2)}",
                    ),
                  ],
                  if (_selectedMaterial!.pricePerUnit != null &&
                      _selectedMaterial!.pricePerUnit! > 0) ...[
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      "Price per unit:",
                      "₦${_thousands.format(_selectedMaterial!.pricePerUnit!.round())}",
                    ),
                  ],
                  if (_selectedFoamVariant != null) ...[
                    const Divider(height: 16),
                    _buildInfoRow(
                      "Selected Foam:",
                      "${_selectedFoamVariant!.thickness}${_selectedFoamVariant!.thicknessUnit} ${_selectedFoamVariant!.density ?? ''}",
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      "Foam Size:",
                      "${_selectedFoamVariant!.width} × ${_selectedFoamVariant!.length} ${_selectedFoamVariant!.dimensionUnit}",
                    ),
                    if (_selectedFoamVariant!.pricePerSqm != null) ...[
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        "Foam Price:",
                        "₦${_selectedFoamVariant!.pricePerSqm!.toStringAsFixed(2)}/m²",
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (requiresProjectSize ||
              requiresThickness ||
              usesQuantityBasedInput) ...[
            if (requiresProjectSize) ...[
              _buildSectionHeader("Project Size (what you need)"),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildManualInputField(
                    "Length (longer)",
                    lengthController,
                    () => _calculateCosts(),
                  ),
                  const SizedBox(width: 12),
                  _buildManualInputField(
                    "Width (shorter)",
                    widthController,
                    () => _calculateCosts(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (usesQuantityBasedInput) ...[
              _buildSectionHeader("Required Quantity"),
              const SizedBox(height: 12),
              _buildStandaloneInputField(
                _quantityInputLabel(_selectedMaterial),
                quantityController,
                () => _calculateCosts(),
              ),
              const SizedBox(height: 12),
              if (isUnpricedQuantityMaterial || _effectiveNeedsPricing())
                _buildCurrencyInputField(
                  _unitPriceLabel(_selectedMaterial),
                  manualUnitPriceController,
                )
              else
                _buildReadOnlyField(
                  _unitPriceLabel(_selectedMaterial),
                  _formattedUnitPrice(_selectedMaterial),
                ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                if (requiresThickness && !shouldHideThicknessField)
                  Expanded(
                    child: isFixedVariantThickness
                        ? _buildReadOnlyField(
                            "Thickness",
                            '${resolvedThicknessValue ?? ''} ${_selectedMaterial?.thicknessUnit ?? ''}'
                                .trim(),
                          )
                        : _availableThicknesses.isNotEmpty
                        ? _buildDropdown(
                            "Thickness",
                            _availableThicknesses,
                            thickness,
                            (v) {
                              setState(() {
                                thickness = v;
                                thicknessController.text = v ?? '';
                              });
                              _calculateCosts();
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Thickness",
                                style: GoogleFonts.openSans(
                                  fontSize: 14,
                                  color: const Color(0xFF7B7B7B),
                                ),
                              ),
                              const SizedBox(height: 6),

                              TextField(
                                controller: thicknessController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(12),
                                  hintText: "Enter thickness",
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFBDBDBD),
                                    fontSize: 13,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                ),
                                onChanged: (_) => _calculateCosts(),
                              ),
                            ],
                          ),
                  ),
                if (requiresThickness &&
                    requiresProjectSize &&
                    !shouldHideThicknessField)
                  const SizedBox(width: 12),
                if (requiresProjectSize)
                  Expanded(
                    child: _buildDropdown("Unit", linearUnits, unit, (v) {
                      setState(() {
                        unit = v;
                        _dimensionUnit = v;
                      });
                      _calculateCosts();
                    }),
                  ),
              ],
            ),
            if (requiresThickness && !shouldHideThicknessField)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isFixedVariantThickness
                      ? "Thickness comes from the selected variant for this material."
                      : "Note: Thickness is required before costs can be calculated.",
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "This material uses quantity-based pricing and does not need project dimensions.",
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: const Color(0xFF7B7B7B),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Calculating indicator
          if (_isCalculating)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8DED6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Calculating costs...",
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: const Color(0xFF7B7B7B),
                    ),
                  ),
                ],
              ),
            ),

          // Calculated Results
          if (_costCalculation != null) _buildCalculationResults(),

          const SizedBox(height: 20),
          CustomButton(text: "Add Item", onPressed: _handleAddItem),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: const Color(0xFF302E2E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialCardHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D241E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.layers_outlined, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedMaterial?.name ?? "Choose catalog material",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualInputField(
    String label,
    TextEditingController controller,
    VoidCallback onChanged,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: const Color(0xFF7B7B7B),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              hintText: "Enter value",
              hintStyle: const TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
            onChanged: (value) {
              // Auto-calculate when user types
              if (value.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  onChanged();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStandaloneInputField(
    String label,
    TextEditingController controller,
    VoidCallback onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(12),
            hintText: "Enter value",
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 500), () {
                onChanged();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildCurrencyInputField(
    String label,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: const Color(0xFF7B7B7B),
          ),
        ),

        const SizedBox(height: 6),

        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(12),
            hintText: 'Enter manual price',
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
          onChanged: (value) {
            final clean = value.replaceAll(',', '').trim();
            if (clean.isEmpty) {
              if (mounted) setState(() {});
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) _calculateCosts();
              });
              return;
            }
            final parsed = double.tryParse(clean);
            if (parsed == null) return;
            final formatted = _thousands.format(parsed.round());
            if (formatted != value) {
              controller.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
            if (mounted) setState(() {});
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _calculateCosts();
            });
          },
        ),
      ],
    );
  }

  Widget _buildFoamVariantSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Foam Variant",
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<FoamVariant>(
          value: _selectedFoamVariant,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
          hint: const Text("Select thickness and density"),
          items: _selectedMaterial!.foamVariants.map((variant) {
            final label =
                '${variant.thickness}${variant.thicknessUnit} ${variant.density ?? ""} '
                '(${variant.width}×${variant.length} ${variant.dimensionUnit})';
            return DropdownMenuItem(
              value: variant,
              child: Text(label, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: _onFoamVariantSelected,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCalculationResults() {
    final usesQuantityBasedInput = _usesQuantityBasedInput(_selectedMaterial);
    final needsPricing = _effectiveNeedsPricing();
    final effectiveProjectCost = _effectiveProjectCost();
    final effectiveUnitPrice = _effectiveUnitPriceForQuantityMaterial() ?? 0;
    final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8DED6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.functions_rounded,
                  color: Color(0xFF8B4513),
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                "Calculated Costs",
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF211D1A),
                ),
              ),
            ],
          ),

          if (needsPricing) ...[
            const SizedBox(height: 6),
            Text(
              "This material is unpriced. Enter a manual price before adding it.",
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (usesQuantityBasedInput) ...[
            _buildResultRow("Quantity:", "${quantity < 1 ? 1 : quantity}"),
            _buildResultRow(
              _unitPriceLabel(_selectedMaterial),
              "₦${effectiveUnitPrice.toStringAsFixed(2)}",
            ),
            const Divider(color: Color(0xFFCCA183)),
            _buildResultRow(
              "Project Cost:",
              "₦${effectiveProjectCost.toStringAsFixed(2)}",
            ),
          ] else ...[
            _buildResultRow(
              "Project Area:",
              "${_costCalculation!.dimensions.projectAreaSqm.toStringAsFixed(2)} sq m",
            ),
            _buildResultRow(
              "Standard Area:",
              "${_costCalculation!.dimensions.standardAreaSqm.toStringAsFixed(2)} sq m",
            ),
            const Divider(color: Color(0xFFCCA183)),
            _buildResultRow(
              "Price per sq m:",
              "₦${_costCalculation!.pricing.pricePerSqm.toStringAsFixed(2)}",
            ),
            _buildResultRow(
              "Full Board Price:",
              "₦${_costCalculation!.pricing.totalBoardPrice.toStringAsFixed(2)}",
            ),
            const Divider(color: Color(0xFFCCA183)),
            _buildResultRow(
              "Project Cost:",
              "₦${effectiveProjectCost.toStringAsFixed(2)}",
            ),
            _buildResultRow(
              "Billable Units:",
              "${_costCalculation!.calculation.billableUnits} unit(s)",
            ),
            const Divider(color: Color(0xFFCCA183)),
            _buildResultRow(
              "Total Area Used:",
              "${_costCalculation!.waste.totalAreaUsed.toStringAsFixed(2)} sq m",
            ),
            _buildResultRow(
              "Waste:",
              "${_costCalculation!.waste.wasteArea.toStringAsFixed(2)} sq m "
                  "(${_costCalculation!.waste.wastePercentage.toStringAsFixed(1)}%)",
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.openSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFA16438),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.openSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF302E2E),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: const Color(0xFF302E2E),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFA16438),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    final normalizedValue = items.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey<String>("${label}_${items.join('|')}"),
          value: normalizedValue,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(v, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: items.first == "No thickness available" ? null : onChanged,
        ),
      ],
    );
  }
}
