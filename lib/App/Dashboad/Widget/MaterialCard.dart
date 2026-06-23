import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _MaterialSearchSuggestion {
  final int categoryIndex;
  final int subCategoryIndex;
  final String category;
  final String subCategory;
  final String label;
  final String meta;
  final Map<String, dynamic> variant;

  const _MaterialSearchSuggestion({
    required this.categoryIndex,
    required this.subCategoryIndex,
    required this.category,
    required this.subCategory,
    required this.label,
    required this.meta,
    required this.variant,
  });
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
  String? _selectedUnitKey;
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
  final TextEditingController materialSearchController =
      TextEditingController();
  String _materialSearchQuery = '';
  String _manualSqmPriceBasis = 'sqm';

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
    materialSearchController.dispose();
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

    final dimensionRulesByCategory = <String, Map<String, dynamic>>{};
    for (final rule in rulesList) {
      final category = (rule['category'] ?? '').toString().trim();
      if (category.isNotEmpty) {
        dimensionRulesByCategory[category.toLowerCase()] = rule;
      }
    }

    if (!mounted) return;
    setState(() {
      _materials = materials;
      _groupedCategories = groupedData;
      _dimensionRulesByCategory
        ..clear()
        ..addAll(dimensionRulesByCategory);
      _isLoadingMaterials = false;
    });
    _selectDefaultMaterialIfNeeded();
  }

  void _selectDefaultMaterialIfNeeded() {
    if (_selectedMaterial != null) return;

    final first = _firstGroupedVariant();
    if (first != null) {
      _selectGroupedVariant(
        category: first.$1,
        subCategory: first.$2,
        variant: first.$3,
        categoryIndex: first.$4,
        subCategoryIndex: first.$5,
      );
      return;
    }

    if (_materials.isNotEmpty) {
      _onMaterialSelected(_materials.first);
    }
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

  String _cleanGeneratedVariantName({
    required String category,
    required String subCategory,
    required String raw,
  }) {
    var value = _cleanVariantSizeLabel(raw).replaceAll('_', ' ').trim();
    if (value.isEmpty) return '';

    final categoryText = _cleanGroupLabel(category).replaceAll('_', ' ').trim();
    final subText = _cleanGroupLabel(subCategory).replaceAll('_', ' ').trim();
    final prefix = [
      categoryText,
      subText,
    ].where((part) => part.isNotEmpty).join(' ').toLowerCase();

    if (prefix.isNotEmpty && value.toLowerCase().startsWith(prefix)) {
      value = value.substring(prefix.length).trim();
    }

    final lower = value.toLowerCase();
    if (lower.startsWith('sqm ')) {
      value = value.substring(4).trim();
    } else if (lower == 'sqm') {
      value = '';
    }

    return value;
  }

  String _variantSelectorLabel({
    required String category,
    required String subCategory,
    required Map<String, dynamic> variant,
  }) {
    final size = _cleanVariantSizeLabel((variant['size'] ?? '').toString());
    if (size.isNotEmpty) return size;

    final generatedName = _cleanGeneratedVariantName(
      category: category,
      subCategory: subCategory,
      raw: (variant['name'] ?? '').toString(),
    );
    if (generatedName.isNotEmpty) return generatedName;

    final thickness = variant['thickness']?.toString().trim() ?? '';
    if (thickness.isNotEmpty) return thickness;

    return 'Default';
  }

  String _variantUnitLabel(Map<String, dynamic> variant) {
    final values = [
      variant['unit'],
      variant['pricingUnit'],
      variant['standardUnit'],
    ];
    for (final value in values) {
      final label = _cleanGroupLabel(value?.toString() ?? '');
      if (label.isNotEmpty) return label;
    }
    return 'Unit';
  }

  String _variantUnitKey(Map<String, dynamic> variant) {
    return _variantUnitLabel(variant).toLowerCase();
  }

  String _sizeColorSelectorLabel(Map<String, dynamic> variant) {
    final size = _cleanVariantSizeLabel((variant['size'] ?? '').toString());
    final thickness = variant['thickness']?.toString().trim() ?? '';
    final color = _cleanGroupLabel((variant['color'] ?? '').toString());
    final dimension = size.isNotEmpty
        ? size
        : (thickness.isNotEmpty ? thickness : '');

    if (dimension.isNotEmpty && color.isNotEmpty) {
      return '${dimension}_$color';
    }
    if (dimension.isNotEmpty) return dimension;
    if (color.isNotEmpty) return color;
    return 'Default';
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
      billingMode: variant['billingMode']?.toString(),
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

  String _selectedMaterialUnit(MaterialModel? material) {
    final unit = material?.unit?.trim();
    if (unit != null && unit.isNotEmpty) return unit.toLowerCase();
    return material?.pricingUnit?.trim().toLowerCase() ?? '';
  }

  bool _isSqmMaterial(MaterialModel? material) {
    final unit = _selectedMaterialUnit(material).replaceAll(' ', '');
    return unit == 'sqm' || unit == 'm2' || unit == 'm²';
  }

  bool _quantityRequiresWholeNumber(MaterialModel? material) {
    const integerUnits = {'piece', 'bag', 'pair', 'pack', 'set', 'roll'};
    return integerUnits.contains(_selectedMaterialUnit(material));
  }

  bool _requiresProjectSize(MaterialModel? material) {
    return material != null && _isSqmMaterial(material);
  }

  bool _requiresThickness(MaterialModel? material) {
    if (material == null || !_isSqmMaterial(material)) return false;
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
    final raw = _selectedMaterialUnit(material);
    if (raw.isEmpty) return 'Quantity needed';
    if (raw == 'piece') return 'Pieces needed';
    if (raw == 'bag') return 'Bags needed';
    if (raw == 'pair') return 'Pairs needed';
    if (raw == 'sheet') return 'Sheets needed';
    if (raw == 'roll') return 'Rolls needed';
    if (raw == 'yard') return 'Yards needed';
    if (raw == 'pack') return 'Packs needed';
    if (raw == 'set') return 'Sets needed';
    if (raw == 'liter') return 'Liters needed';
    if (raw == 'gallon') return 'Gallons needed';
    if (raw == 'kilogram') return 'Kilograms needed';
    if (raw == 'pound weight' || raw == 'pound') {
      return 'Pound weight needed';
    }
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

  String _formatCurrency(double value) {
    final hasDecimals = (value - value.roundToDouble()).abs() >= 0.005;
    final formatted = hasDecimals
        ? NumberFormat('#,##0.##').format(value)
        : _thousands.format(value.round());
    return '₦$formatted';
  }

  bool _isUnpricedQuantityMaterial(MaterialModel? material) {
    if (!_usesQuantityBasedInput(material)) return false;
    final value = material?.pricePerUnit ?? material?.catalogPrice;
    return value == null || value <= 0;
  }

  bool _manualPriceUsesAreaRate() {
    if (_usesQuantityBasedInput(_selectedMaterial)) return false;
    if (_requiresProjectSize(_selectedMaterial)) {
      return _manualSqmPriceBasis == 'sqm';
    }
    final material = _selectedMaterial;
    final raw = [
      material?.pricingUnit,
      material?.unit,
      material?.standardUnit,
    ].whereType<String>().join(' ').toLowerCase();
    final category = material?.category?.trim().toLowerCase() ?? '';
    return raw.contains('sqm') ||
        raw.contains('sq m') ||
        raw.contains('m2') ||
        raw.contains('m²') ||
        raw.contains('square') ||
        category == 'board' ||
        category == 'wood' ||
        category == 'fabric' ||
        category == 'marble' ||
        _requiresProjectSize(material);
  }

  String _manualPriceInputLabel() {
    if (_usesQuantityBasedInput(_selectedMaterial)) {
      return _unitPriceLabel(_selectedMaterial);
    }
    if (_requiresProjectSize(_selectedMaterial) &&
        _manualSqmPriceBasis == 'full_unit') {
      return 'Manual full sheet price';
    }
    if (_manualPriceUsesAreaRate()) {
      return 'Manual price per sq m';
    }
    return 'Manual full unit price';
  }

  String? _manualPriceBasisForRequest() {
    if (!_requiresProjectSize(_selectedMaterial)) return null;
    return _manualSqmPriceBasis;
  }

  double? _parseAmountInput(String text) {
    final clean = text.replaceAll(',', '').trim();
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  double _parseQuantityInput() {
    final parsed = double.tryParse(quantityController.text.trim());
    if (parsed == null || parsed <= 0) return 0;
    return parsed;
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
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

  int _manualPriceMultiplier() {
    final quantity = _parseQuantityInput();
    if (_usesQuantityBasedInput(_selectedMaterial)) {
      return quantity.ceil();
    }

    final billableUnits = _costCalculation?.calculation.billableUnits ?? 0;
    if (billableUnits > 0) return billableUnits.ceil();

    final minimumUnits = _costCalculation?.calculation.minimumUnits ?? 0;
    if (minimumUnits > 0) return minimumUnits;

    return quantity.ceil();
  }

  double _manualLineTotal(double manualUnitPrice) {
    if (_usesQuantityBasedInput(_selectedMaterial)) {
      return manualUnitPrice * _parseQuantityInput();
    }

    if (_requiresProjectSize(_selectedMaterial)) {
      final projectArea = _costCalculation?.dimensions.projectAreaSqm ?? 0;
      if (projectArea <= 0) return 0;

      if (_manualSqmPriceBasis == 'sqm') {
        return manualUnitPrice * projectArea;
      }

      final standardArea = _costCalculation?.dimensions.standardAreaSqm ?? 0;
      if (standardArea <= 0) return 0;
      return (manualUnitPrice / standardArea) * projectArea;
    }

    return manualUnitPrice * _manualPriceMultiplier();
  }

  double _effectiveProjectCost() {
    final manualUnitPrice = _parseAmountInput(manualUnitPriceController.text);
    if (manualUnitPrice != null && manualUnitPrice > 0) {
      return _manualLineTotal(manualUnitPrice);
    }

    final calculatedTotal = _costCalculation?.pricing.totalMaterialCost;
    if (calculatedTotal != null && calculatedTotal > 0) {
      return calculatedTotal;
    }

    if (_costCalculation?.calculation.needsPricing == true) {
      return 0;
    }

    if (_usesQuantityBasedInput(_selectedMaterial)) {
      final unitPrice = _effectiveUnitPriceForQuantityMaterial() ?? 0;
      return unitPrice * _parseQuantityInput();
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
    _selectedUnitKey = _variantUnitKey(variant);
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

  List<Map<String, dynamic>> _filteredGroupedCategories() {
    final query = _materialSearchQuery.trim().toLowerCase();

    bool matches(String value) => value.toLowerCase().contains(query);

    return _groupedCategories
        .asMap()
        .entries
        .map((categoryEntry) {
          final categoryObj = categoryEntry.value;
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

          final filteredSubCats = <Map<String, dynamic>>[];
          for (final subEntry in subCats.asMap().entries) {
            final subObj = subEntry.value;
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

            final filteredVariants =
                query.isEmpty || matches(categoryName) || matches(subName)
                ? variants
                : variants.where((variant) {
                    final label = _variantSelectorLabel(
                      category: categoryName,
                      subCategory: subName,
                      variant: variant,
                    );
                    final name = (variant['name'] ?? '').toString();
                    final size = (variant['size'] ?? '').toString();
                    return matches(label) || matches(name) || matches(size);
                  }).toList();

            if (query.isEmpty ||
                matches(categoryName) ||
                matches(subName) ||
                filteredVariants.isNotEmpty) {
              filteredSubCats.add({
                'index': subEntry.key,
                'subCategory': subObj,
                'variants': filteredVariants,
              });
            }
          }

          if (query.isNotEmpty &&
              !matches(categoryName) &&
              filteredSubCats.isEmpty) {
            return <String, dynamic>{};
          }

          return {
            'index': categoryEntry.key,
            'category': categoryObj,
            'subCategories': filteredSubCats,
          };
        })
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  bool _matchesMaterialSearch(String haystack, String query) {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.trim().isNotEmpty)
        .toList();
    if (terms.isEmpty) return true;

    final normalized = haystack.toLowerCase().replaceAll('_', ' ');
    return terms.every((term) => normalized.contains(term));
  }

  List<_MaterialSearchSuggestion> _materialSearchSuggestions() {
    final query = _materialSearchQuery.trim();
    if (query.isEmpty) return const [];

    final suggestions = <_MaterialSearchSuggestion>[];
    for (final categoryEntry in _groupedCategories.asMap().entries) {
      final categoryObj = categoryEntry.value;
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

      for (final subEntry in subCats.asMap().entries) {
        final subObj = subEntry.value;
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

        for (final variant in variants) {
          final label = _variantSelectorLabel(
            category: categoryName,
            subCategory: subName,
            variant: variant,
          );
          final searchable = [
            categoryName,
            subName,
            label,
            variant['name'],
            variant['size'],
            variant['unit'],
            variant['pricingUnit'],
            variant['standardUnit'],
            variant['thicknessUnit'],
            variant['thickness'],
            variant['billingMode'],
          ].whereType<Object>().map((value) => value.toString()).join(' ');

          if (!_matchesMaterialSearch(searchable, query)) continue;

          final unit =
              [variant['pricingUnit'], variant['unit'], variant['standardUnit']]
                  .whereType<Object>()
                  .map((value) => value.toString().trim())
                  .firstWhere((value) => value.isNotEmpty, orElse: () => '');
          final metaParts = [
            categoryName,
            if (subName != categoryName) subName,
            if (unit.isNotEmpty) unit,
          ];

          suggestions.add(
            _MaterialSearchSuggestion(
              categoryIndex: categoryEntry.key,
              subCategoryIndex: subEntry.key,
              category: categoryName,
              subCategory: subName,
              label: label,
              meta: metaParts.join(' • '),
              variant: variant,
            ),
          );
        }
      }
    }

    return suggestions.take(16).toList();
  }

  List<Map<String, dynamic>> _dedupedVariantsForDisplay({
    required List<Map<String, dynamic>> variants,
  }) {
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];

    for (final variant in variants) {
      final label = _sizeColorSelectorLabel(variant);
      final key = label.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      deduped.add(variant);
    }

    return deduped;
  }

  Widget _buildMaterialSearchField() {
    return TextField(
      controller: materialSearchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        suffixIcon: _materialSearchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Clear search',
                onPressed: () {
                  materialSearchController.clear();
                  setState(() => _materialSearchQuery = '');
                },
              ),
        hintText: 'Search materials',
        hintStyle: GoogleFonts.openSans(
          color: const Color(0xFF9E9E9E),
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF8B4513), width: 1.4),
        ),
      ),
      onChanged: (value) => setState(() => _materialSearchQuery = value),
    );
  }

  Widget _buildMaterialSearchSuggestions() {
    final suggestions = _materialSearchSuggestions();
    if (_materialSearchQuery.trim().isEmpty) return const SizedBox.shrink();

    if (suggestions.isEmpty) {
      return Text(
        "No materials match your search",
        style: GoogleFonts.openSans(color: const Color(0xFF7B7B7B)),
      );
    }

    return Column(
      children: suggestions.map((suggestion) {
        final selected =
            suggestion.categoryIndex == _selectedCategoryIndex &&
            suggestion.subCategoryIndex == _selectedSubCategoryIndex &&
            ((suggestion.variant['id'] ?? suggestion.variant['_id'] ?? '')
                    .toString() ==
                _selectedVariantId);

        return InkWell(
          onTap: () {
            setState(() {
              _selectGroupedVariant(
                category: suggestion.category,
                subCategory: suggestion.subCategory,
                variant: suggestion.variant,
                categoryIndex: suggestion.categoryIndex,
                subCategoryIndex: suggestion.subCategoryIndex,
              );
              materialSearchController.clear();
              _materialSearchQuery = '';
            });
            FocusScope.of(context).unfocus();
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFFF3E8) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? const Color(0xFF8B4513)
                    : const Color(0xFFE8DED6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.layers_outlined,
                  color: selected
                      ? const Color(0xFF8B4513)
                      : const Color(0xFF756A61),
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF302E2E),
                        ),
                      ),
                      if (suggestion.meta.isNotEmpty)
                        Text(
                          suggestion.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            fontSize: 11,
                            color: const Color(0xFF756A61),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupedSelector() {
    if (_groupedCategories.isEmpty) return const SizedBox.shrink();
    if (_selectedCategoryIndex >= _groupedCategories.length) {
      _selectedCategoryIndex = 0;
      _selectedSubCategoryIndex = 0;
    }

    final filteredCategories = _filteredGroupedCategories();
    final selectedCategoryEntry = filteredCategories.firstWhere(
      (entry) => entry['index'] == _selectedCategoryIndex,
      orElse: () => filteredCategories.isNotEmpty
          ? filteredCategories.first
          : <String, dynamic>{},
    );

    if (selectedCategoryEntry.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMaterialSearchField(),
          const SizedBox(height: 8),
          _buildMaterialSearchSuggestions(),
        ],
      );
    }

    final categoryObj = Map<String, dynamic>.from(
      selectedCategoryEntry['category'] as Map,
    );
    final selectedCategorySourceIndex = selectedCategoryEntry['index'] as int;
    final categoryName = _cleanGroupLabel(
      (categoryObj['category'] ?? '').toString(),
    );
    final subCatEntries =
        (selectedCategoryEntry['subCategories'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];

    final selectedSubEntry = subCatEntries.firstWhere(
      (entry) => entry['index'] == _selectedSubCategoryIndex,
      orElse: () =>
          subCatEntries.isNotEmpty ? subCatEntries.first : <String, dynamic>{},
    );

    final subObj = selectedSubEntry.isNotEmpty
        ? Map<String, dynamic>.from(selectedSubEntry['subCategory'] as Map)
        : null;
    final selectedSubSourceIndex = selectedSubEntry.isNotEmpty
        ? selectedSubEntry['index'] as int
        : 0;
    final rawSubName = _cleanGroupLabel(
      (subObj?['subCategory'] ?? '').toString(),
    );
    final subName = rawSubName.isEmpty ? categoryName : rawSubName;
    final variants =
        (selectedSubEntry['variants'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];
    final units = <String, Map<String, dynamic>>{};
    for (final variant in variants) {
      units.putIfAbsent(_variantUnitKey(variant), () => variant);
    }
    final selectedUnitKey =
        _selectedUnitKey != null && units.containsKey(_selectedUnitKey)
        ? _selectedUnitKey!
        : (units.isNotEmpty ? units.keys.first : '');
    final unitVariants = variants
        .where((variant) => _variantUnitKey(variant) == selectedUnitKey)
        .toList();
    final displayVariants = _dedupedVariantsForDisplay(variants: unitVariants);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMaterialSearchField(),
        const SizedBox(height: 8),
        if (_materialSearchQuery.trim().isNotEmpty) ...[
          _buildMaterialSearchSuggestions(),
        ] else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filteredCategories.map((entry) {
                final idx = entry['index'] as int;
                final category = Map<String, dynamic>.from(
                  entry['category'] as Map,
                );
                final name = _cleanGroupLabel(
                  (category['category'] ?? '').toString(),
                );
                final selected = idx == selectedCategorySourceIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(name),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategoryIndex = idx;
                        _selectedSubCategoryIndex = 0;
                        _selectedUnitKey = null;
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
          const SizedBox(height: 8),
          if (subCatEntries.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: subCatEntries.map((entry) {
                  final idx = entry['index'] as int;
                  final sub = Map<String, dynamic>.from(
                    entry['subCategory'] as Map,
                  );
                  final raw = _cleanGroupLabel(
                    (sub['subCategory'] ?? '').toString(),
                  );
                  final name = raw.isEmpty ? categoryName : raw;
                  final selected = idx == selectedSubSourceIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(name),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedSubCategoryIndex = idx;
                          _selectedUnitKey = null;
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
          const SizedBox(height: 8),
          if (displayVariants.isEmpty)
            Text(
              "No variants found for $categoryName / $subName",
              style: GoogleFonts.openSans(color: const Color(0xFF7B7B7B)),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: units.entries.map((entry) {
                final unitKey = entry.key;
                final variant = entry.value;
                final selected = unitKey == selectedUnitKey;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedUnitKey = unitKey;
                      _selectGroupedVariant(
                        category: categoryName,
                        subCategory: subName,
                        variant: variant,
                        categoryIndex: selectedCategorySourceIndex,
                        subCategoryIndex: selectedSubSourceIndex,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
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
                    child: Text(
                      _variantUnitLabel(variant),
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF302E2E),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayVariants.map((v) {
                final id = (v['id'] ?? v['_id'] ?? '').toString();
                final selected = id.isNotEmpty && id == _selectedVariantId;

                final label = _sizeColorSelectorLabel(v);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectGroupedVariant(
                        category: categoryName,
                        subCategory: subName,
                        variant: v,
                        categoryIndex: selectedCategorySourceIndex,
                        subCategoryIndex: selectedSubSourceIndex,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
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
                            fontSize: 12,
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
        ],
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
    final quantity = _parseQuantityInput();

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
        manualPrice: _parseAmountInput(manualUnitPriceController.text),
        manualPriceBasis: _manualPriceBasisForRequest(),
        quantity: quantity,
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

  void _showAddValidationMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.redAccent,
      ),
    );
  }

  void _handleAddItem() {
    final material = _selectedMaterial;
    final requiresProjectSize = _requiresProjectSize(material);
    final requiresThickness = _requiresThickness(material);
    final usesQuantityBasedInput = _usesQuantityBasedInput(material);
    final manualUnitPrice = _parseAmountInput(manualUnitPriceController.text);
    final quantity = _parseQuantityInput();
    final thicknessValue = _resolvedThicknessValue();
    final needsManualPrice = _costCalculation?.calculation.needsPricing == true;
    final usesManualPrice = manualUnitPrice != null && manualUnitPrice > 0;

    if (material == null) {
      _showAddValidationMessage("Select a material before adding.");
      return;
    }

    if (materialTypeController.text.trim().isEmpty) {
      _showAddValidationMessage("Select a material variant before adding.");
      return;
    }

    if (requiresProjectSize && lengthController.text.trim().isEmpty) {
      _showAddValidationMessage("Enter the project length for this material.");
      return;
    }

    if (requiresProjectSize && widthController.text.trim().isEmpty) {
      _showAddValidationMessage("Enter the project width for this material.");
      return;
    }

    if (requiresProjectSize && unit == null) {
      _showAddValidationMessage("Select the project size unit.");
      return;
    }

    if (usesQuantityBasedInput && quantity <= 0) {
      _showAddValidationMessage("Enter a quantity greater than zero.");
      return;
    }

    if (usesQuantityBasedInput &&
        _quantityRequiresWholeNumber(material) &&
        quantity != quantity.roundToDouble()) {
      final unitName = material.unit?.trim().isNotEmpty == true
          ? material.unit!.trim()
          : 'Quantity';
      _showAddValidationMessage("$unitName must be entered as a whole number.");
      return;
    }

    if (requiresThickness &&
        (thicknessValue == null || thicknessValue.isEmpty)) {
      _showAddValidationMessage("Enter the material thickness.");
      return;
    }

    if (_costCalculation == null) {
      _showAddValidationMessage(
        "Cost has not been calculated yet. Check the size values and wait for calculation.",
        backgroundColor: Colors.orange,
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

    final normalizedQuantity = quantity <= 0 ? 1.0 : quantity;
    final lineTotal = usesManualPrice
        ? _manualLineTotal(manualUnitPrice)
        : _costCalculation!.pricing.totalMaterialCost;
    final unitPrice = normalizedQuantity > 0
        ? lineTotal / normalizedQuantity
        : lineTotal;
    final standardArea = _costCalculation!.dimensions.standardAreaSqm;
    final manualPricePerSqm = usesManualPrice
        ? (_requiresProjectSize(material)
              ? (_manualSqmPriceBasis == 'sqm'
                    ? manualUnitPrice
                    : (standardArea > 0
                          ? manualUnitPrice / standardArea
                          : null))
              : (_manualPriceUsesAreaRate()
                    ? manualUnitPrice
                    : (standardArea > 0
                          ? manualUnitPrice / standardArea
                          : null)))
        : null;
    final manualFullUnitPrice = usesManualPrice
        ? (_requiresProjectSize(material)
              ? (_manualSqmPriceBasis == 'sqm' && standardArea > 0
                    ? manualUnitPrice * standardArea
                    : manualUnitPrice)
              : (_manualPriceUsesAreaRate() && standardArea > 0
                    ? manualUnitPrice * standardArea
                    : manualUnitPrice))
        : null;
    final calculationPayload = {
      "mode": _costCalculation!.calculation.mode,
      "billingMode":
          _costCalculation!.material.billingMode ?? material.billingMode,
      "minimumUnits": _costCalculation!.calculation.minimumUnits,
      "billableUnits": _costCalculation!.calculation.billableUnits,
      "quantity": _costCalculation!.calculation.quantity,
      "needsPricing": needsManualPrice && !usesManualPrice,
      "pricePerSqm": manualPricePerSqm ?? _costCalculation!.pricing.pricePerSqm,
      "pricePerUnit": usesManualPrice
          ? manualUnitPrice
          : _costCalculation!.pricing.pricePerUnit,
      "pricePerFullUnit":
          manualFullUnitPrice ?? _costCalculation!.pricing.pricePerFullUnit,
      "totalMaterialCost": lineTotal,
      if (usesManualPrice && _manualPriceBasisForRequest() != null)
        "manualPriceBasis": _manualPriceBasisForRequest(),
    };

    // Create item with API calculation results
    final item = {
      "materialId": material.id,
      "name": material.name,
      "category": material.category,
      "subCategory": material.subCategory,
      "billingMode":
          _costCalculation!.material.billingMode ?? material.billingMode,
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
      "quantity": _formatQuantity(normalizedQuantity),
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
      _manualSqmPriceBasis = 'sqm';
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
            const SizedBox(height: 10),
          ],

          // Material selection
          if (_isLoadingMaterials)
            _buildMaterialLoadingSkeleton()
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

          const SizedBox(height: 10),

          // Foam Variants Selection (if foam material)
          if (isFoam && hasFoamVariants) _buildFoamVariantSelection(),

          // Material name is auto-generated from the selected material and hidden from UI.
          const SizedBox(height: 4),

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
            const SizedBox(height: 12),
          ],

          if (requiresProjectSize ||
              requiresThickness ||
              usesQuantityBasedInput) ...[
            if (requiresProjectSize) ...[
              _buildSectionHeader("Project Size (what you need)"),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildManualInputField(
                    "Length (longer)",
                    lengthController,
                    () => _calculateCosts(),
                  ),
                  const SizedBox(width: 8),
                  _buildManualInputField(
                    "Width (shorter)",
                    widthController,
                    () => _calculateCosts(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (usesQuantityBasedInput) ...[
              _buildSectionHeader("Required Quantity"),
              const SizedBox(height: 8),
              _buildStandaloneInputField(
                _quantityInputLabel(_selectedMaterial),
                quantityController,
                () => _calculateCosts(),
                allowDecimal: !_quantityRequiresWholeNumber(_selectedMaterial),
              ),
              const SizedBox(height: 10),
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
                                  fontSize: 12,
                                  color: const Color(0xFF7B7B7B),
                                ),
                              ),
                              const SizedBox(height: 5),

                              TextField(
                                controller: thicknessController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 11,
                                  ),
                                  hintText: "Enter thickness",
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFBDBDBD),
                                    fontSize: 12,
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
                  const SizedBox(width: 8),
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
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
          ],
          if (_selectedMaterial != null) ...[
            _buildManualPricingSection(
              showCurrentUnitPrice:
                  usesQuantityBasedInput &&
                  !isUnpricedQuantityMaterial &&
                  !_effectiveNeedsPricing(),
            ),
            const SizedBox(height: 14),
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

          const SizedBox(height: 14),
          CustomButton(text: "Add Item", onPressed: _handleAddItem),
        ],
      ),
    );
  }

  Widget _buildMaterialLoadingSkeleton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.45, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildSkeletonBox(
                    width: index == 2 ? 148 : 92,
                    height: 34,
                    radius: 8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSkeletonBox(width: 110, height: 34, radius: 8),
              _buildSkeletonBox(width: 92, height: 34, radius: 8),
              _buildSkeletonBox(width: 128, height: 34, radius: 8),
            ],
          ),
          const SizedBox(height: 14),
          _buildSkeletonBox(width: 140, height: 14, radius: 999),
          const SizedBox(height: 8),
          _buildSkeletonBox(width: double.infinity, height: 42, radius: 8),
          const SizedBox(height: 12),
          _buildSkeletonBox(width: 132, height: 14, radius: 999),
          const SizedBox(height: 8),
          _buildSkeletonBox(width: double.infinity, height: 42, radius: 8),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8DED6).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(radius),
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
            fontSize: 12,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: const Color(0xFF302E2E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualPricingSection({required bool showCurrentUnitPrice}) {
    final isRequired =
        _effectiveNeedsPricing() ||
        _costCalculation?.calculation.needsPricing == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Manual Pricing"),
        const SizedBox(height: 8),
        if (showCurrentUnitPrice) ...[
          _buildReadOnlyField(
            "Current ${_unitPriceLabel(_selectedMaterial).toLowerCase()}",
            _formattedUnitPrice(_selectedMaterial),
          ),
          const SizedBox(height: 8),
        ],
        _buildCurrencyInputField(
          _manualPriceInputLabel(),
          manualUnitPriceController,
        ),
        if (_requiresProjectSize(_selectedMaterial)) ...[
          const SizedBox(height: 8),
          _buildManualSqmPriceBasisSelector(),
        ],
        const SizedBox(height: 6),
        Text(
          isRequired
              ? "Required for this unpriced material."
              : "Optional. Enter a value to override the calculated price for this item.",
          style: GoogleFonts.openSans(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  Widget _buildManualSqmPriceBasisSelector() {
    Widget option({
      required String value,
      required String label,
      required String helper,
    }) {
      final selected = _manualSqmPriceBasis == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (_manualSqmPriceBasis == value) return;
            setState(() => _manualSqmPriceBasis = value);
            _calculateCosts();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFFF3E8) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? const Color(0xFFA16438)
                    : const Color(0xFFE0E0E0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFFA16438)
                        : const Color(0xFF302E2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  helper,
                  style: GoogleFonts.openSans(
                    fontSize: 10,
                    color: const Color(0xFF7B7B7B),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manual price basis',
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            option(value: 'sqm', label: 'Per sq m', helper: 'Rate per area'),
            const SizedBox(width: 8),
            option(
              value: 'full_unit',
              label: 'Full sheet',
              helper: 'Price for one sheet',
            ),
          ],
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
              fontSize: 12,
              color: const Color(0xFF7B7B7B),
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              hintText: "Enter value",
              hintStyle: const TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 12,
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
    VoidCallback onChanged, {
    bool allowDecimal = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          inputFormatters: allowDecimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}$'))]
              : [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            hintText: "Enter value",
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
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
            fontSize: 12,
            color: const Color(0xFF7B7B7B),
          ),
        ),

        const SizedBox(height: 5),

        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            hintText: 'Enter manual price',
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
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
            fontSize: 12,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<FoamVariant>(
          initialValue: _selectedFoamVariant,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCalculationResults() {
    final usesQuantityBasedInput = _usesQuantityBasedInput(_selectedMaterial);
    final needsPricing = _effectiveNeedsPricing();
    final effectiveProjectCost = _effectiveProjectCost();
    final effectiveUnitPrice = _effectiveUnitPriceForQuantityMaterial() ?? 0;
    final quantity = _parseQuantityInput();
    final manualUnitPrice = _parseAmountInput(manualUnitPriceController.text);
    final standardArea = _costCalculation!.dimensions.standardAreaSqm;
    final displayPricePerSqm =
        manualUnitPrice != null && manualUnitPrice > 0 && standardArea > 0
        ? (_requiresProjectSize(_selectedMaterial)
              ? (_manualSqmPriceBasis == 'sqm'
                    ? manualUnitPrice
                    : manualUnitPrice / standardArea)
              : (_manualPriceUsesAreaRate()
                    ? manualUnitPrice
                    : manualUnitPrice / standardArea))
        : _costCalculation!.pricing.pricePerSqm;
    final displayFullUnitPrice = manualUnitPrice != null && manualUnitPrice > 0
        ? (_requiresProjectSize(_selectedMaterial)
              ? (_manualSqmPriceBasis == 'sqm' && standardArea > 0
                    ? manualUnitPrice * standardArea
                    : manualUnitPrice)
              : (_manualPriceUsesAreaRate() && standardArea > 0
                    ? manualUnitPrice * standardArea
                    : manualUnitPrice))
        : _costCalculation!.pricing.totalBoardPrice;
    final billableUnits = _costCalculation!.calculation.billableUnits;
    final billableUnitsText = billableUnits == billableUnits.roundToDouble()
        ? billableUnits.toInt().toString()
        : billableUnits.toStringAsFixed(4);
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
            _buildResultRow("Quantity:", _formatQuantity(quantity)),
            _buildResultRow(
              _unitPriceLabel(_selectedMaterial),
              _formatCurrency(effectiveUnitPrice),
            ),
            const Divider(color: Color(0xFFCCA183)),
            _buildResultRow(
              "Project Cost:",
              _formatCurrency(effectiveProjectCost),
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
              _formatCurrency(displayPricePerSqm),
            ),
            _buildResultRow(
              "Full Board Price:",
              _formatCurrency(displayFullUnitPrice),
            ),
            const Divider(color: Color(0xFFCCA183)),
            _buildResultRow(
              "Project Cost:",
              _formatCurrency(effectiveProjectCost),
            ),
            _buildResultRow("Billable Units:", "$billableUnitsText unit(s)"),
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
        fontSize: 13,
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
            fontSize: 12,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          key: ValueKey<String>("${label}_${items.join('|')}"),
          initialValue: normalizedValue,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(
                    v,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: items.first == "No thickness available" ? null : onChanged,
        ),
      ],
    );
  }
}
