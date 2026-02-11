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
  int _selectedCategoryIndex = 0;
  int _selectedSubCategoryIndex = 0;
  String? _selectedVariantId;
  bool _isLoadingMaterials = true;
  MaterialModel? _selectedMaterial;
  String? _selectedMaterialType;
  bool _isCustomType = false;
  String? _dimensionUnit; // Unit for requiredWidth/requiredLength sent to API

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
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoadingMaterials = true);
    final results = await Future.wait([
      _materialService.getMaterials(),
      _materialService.getGroupedMaterials(),
    ]);

    final materials = results[0] as List<MaterialModel>;
    final groupedResult = results[1] as Map<String, dynamic>;
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

  List<String> _materialUnits() {
    final units = <String>{};
    for (final m in _materials) {
      final u = (m.unit ?? '').toString().trim();
      if (u.isNotEmpty) units.add(u);
    }
    if (units.isEmpty) {
      units.add('Piece');
    }
    final list = units.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
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
    final matches = RegExp(r'(\\d+(?:\\.\\d+)?|\\d+\\s*/\\s*\\d+)')
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

  void _prefillFromVariantSizeString(String raw) {
    final triplet = _parseSizeTriplet(raw);
    if (triplet == null) return;
    // If we have 3 values: treat as thickness, width, length.
    if (triplet.length >= 3) {
      final t = triplet[0];
      final w = triplet[1];
      final l = triplet[2];

      if (widthController.text.trim().isEmpty) {
        widthController.text = w.toString();
      }
      if (lengthController.text.trim().isEmpty) {
        lengthController.text = l.toString();
      }

      // Only use thickness from size as a fallback when API thickness is null.
      if (thicknessController.text.trim().isEmpty &&
          (_selectedMaterial?.thickness == null)) {
        thicknessController.text = t.toString();
      }
    } else if (triplet.length == 2) {
      final w = triplet[0];
      final l = triplet[1];
      if (widthController.text.trim().isEmpty) {
        widthController.text = w.toString();
      }
      if (lengthController.text.trim().isEmpty) {
        lengthController.text = l.toString();
      }
    }

    // Infer dimension unit from the size string if possible.
    final inferred = _normalizeLinearUnit(raw.contains('"') ? 'inches' : null);
    if (_dimensionUnit == null && inferred != null) {
      _dimensionUnit = inferred;
    }
  }

  void _prefillProjectSizeAndUnit(MaterialModel material) {
    final sw = material.standardWidth;
    final sl = material.standardLength;
    final su = _normalizeLinearUnit(material.standardUnit);

    final canPrefillSize = sw != null && sl != null && sw > 0 && sl > 0;
    if (canPrefillSize) {
      final longer = sw >= sl ? sw : sl;
      final shorter = sw >= sl ? sl : sw;

      if (lengthController.text.trim().isEmpty) {
        lengthController.text = longer.toString();
      }
      if (widthController.text.trim().isEmpty) {
        widthController.text = shorter.toString();
      }
    }

    if (unit == null || !linearUnits.contains(unit)) {
      if (su != null) {
        _dimensionUnit = su;
      }
    }

    // If we now have enough info, auto-calc once.
    if (_selectedMaterial != null &&
        widthController.text.trim().isNotEmpty &&
        lengthController.text.trim().isNotEmpty &&
        _dimensionUnit != null) {
      Future.microtask(() => _calculateCosts());
    }
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

    return MaterialModel(
      id: id,
      name: (variant['name'] ?? '').toString(),
      category: category,
      subCategory: subCategory,
      size: (variant['size'] ?? '').toString(),
      unit: (variant['unit'] ?? '').toString(),
      color: (variant['color'] ?? '').toString(),
      pricingUnit: (variant['pricingUnit'] ?? '').toString(),
      pricePerUnit: pricePerUnit,
      pricePerSqm: pricePerSqm,
      catalogPrice: _asDouble(variant['catalogPrice']),
      isCatalogMaterial: variant['isCatalogMaterial'] == true,
    );
  }

  void _selectGroupedVariant({
    required String category,
    required String subCategory,
    required Map<String, dynamic> variant,
    required int categoryIndex,
    required int subCategoryIndex,
  }) {
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
    }

    // Prefill length/width from size string when it represents dimensions (e.g. 1"x10"x144").
    final size = (variant['size'] ?? '').toString().trim();
    if (size.isNotEmpty) {
      _prefillFromVariantSizeString(size);
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
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryIndex = idx;
                      _selectedSubCategoryIndex = 0;
                      _selectedVariantId = null;
                    });
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
                    onSelected: (_) {
                      setState(() {
                        _selectedSubCategoryIndex = idx;
                        _selectedVariantId = null;
                      });
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFA16438)
                          : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                    color: selected ? const Color(0xFFFFF3E0) : Colors.white,
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
    // Unit dropdown is for the material's selling/pricing unit (e.g. Piece, Yard).
    final matUnit = (material.unit ?? '').toString().trim();
    if (matUnit.isNotEmpty) {
      unit = matUnit;
    }

    // Dimension unit for calculation comes from standardUnit.
    _dimensionUnit =
        _normalizeLinearUnit(material.standardUnit) ?? _dimensionUnit;

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
      _isCustomType = false;
      _costCalculation = null;
      materialTypeController.clear();

      // Auto-set units based on material type
      _setDefaultUnitsForMaterial(material);

      // Load thicknesses for this material
      _loadThicknessesForMaterial(material);

      // Thickness from API (if present); otherwise allow user input later.
      thicknessController.text = material.thickness?.toString() ?? '';
    });

    // Prefill project size + unit from API standard dims/unit (without overwriting user input).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefillProjectSizeAndUnit(material);
    });
  }

  void _onMaterialTypeSelected(String? type) {
    setState(() {
      if (type == 'custom') {
        _isCustomType = true;
        _selectedMaterialType = null;
        materialTypeController.clear();
      } else {
        _isCustomType = false;
        _selectedMaterialType = type;
        materialTypeController.text = type ?? '';
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
    if (_selectedMaterial == null ||
        widthController.text.isEmpty ||
        lengthController.text.isEmpty ||
        _dimensionUnit == null) {
      return;
    }

    // Thickness is required before calling the cost API.
    // This prevents auto-calling as soon as width/length are prefilled.
    final t = thicknessController.text.trim().isNotEmpty
        ? thicknessController.text.trim()
        : (thickness ?? '').trim();
    if (t.isEmpty) return;

    final w = double.tryParse(widthController.text);
    final l = double.tryParse(lengthController.text);

    if (w == null || l == null) return;

    setState(() => _isCalculating = true);

    try {
      final result = await _materialService.calculateMaterialCost(
        materialId: _selectedMaterial!.id,
        requiredWidth: w,
        requiredLength: l,
        requiredUnit: _dimensionUnit!,
        materialType: _selectedMaterialType,
        foamThickness: _selectedFoamVariant?.thickness,
        foamDensity: _selectedFoamVariant?.density,
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
    final thicknessValue = (thicknessController.text.trim().isNotEmpty)
        ? thicknessController.text.trim()
        : thickness;

    // Validate all required fields
    if (_selectedMaterial == null ||
        materialTypeController.text.trim().isEmpty ||
        widthController.text.isEmpty ||
        lengthController.text.isEmpty ||
        unit == null ||
        thicknessValue == null ||
        thicknessValue.isEmpty ||
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

    // Create item with API calculation results
    final item = {
      "Product": _selectedMaterial!.name,
      "Materialname": materialTypeController.text.trim(),
      "Width": widthController.text,
      "Length": lengthController.text,
      "Thickness": thicknessValue,
      "Unit": unit,
      "Sqm": _costCalculation!.dimensions.projectAreaSqm.toStringAsFixed(2),
      "Price": _costCalculation!.pricing.projectCost.toStringAsFixed(2),
      "needsPricing": _costCalculation!.calculation.needsPricing,
      "quantity": "1",
    };

    widget.onAddItem?.call(item);

    // Reset form (but keep material selection, units, and thickness)
    setState(() {
      _selectedMaterialType = null;
      _selectedFoamVariant = null;
      _isCustomType = false;
      widthController.clear();
      lengthController.clear();
      _costCalculation = null;
    });

    materialTypeController.clear();

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
    final hasTypes = _selectedMaterial?.types.isNotEmpty ?? false;
    final hasFoamVariants = _selectedMaterial?.foamVariants.isNotEmpty ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          if (widget.showHeader || _isLoadingMaterials)
            Row(
              mainAxisAlignment: widget.showHeader
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              children: [
                if (widget.showHeader)
                  Row(
                    children: [
                      if (widget.icon != null)
                        Icon(widget.icon, color: widget.color),
                      if (widget.icon != null) const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF302E2E),
                        ),
                      ),
                    ],
                  ),
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

          if (widget.showHeader || _isLoadingMaterials)
            const SizedBox(height: 16),

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

          // Material Type/Name - Smart Dropdown with Custom Input (for non-foam or foam with types)
          if (_selectedMaterial != null && (!isFoam || hasTypes))
            _buildMaterialTypeField(),

          const SizedBox(height: 20),

          // Display standard material info (read-only from API)
          if (_selectedMaterial != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
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

          // Project/Required Size
          _buildSectionHeader("Project Size (what you need)"),
          const SizedBox(height: 12),

          // Length + Width (Manual Input)
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

          // Thickness (Auto from API) + Unit (Dropdown)
          Row(
            children: [
              Expanded(
                child: _availableThicknesses.isNotEmpty
                    ? _buildDropdown(
                        "Thickness",
                        _availableThicknesses,
                        thickness,
                        (v) {
                          setState(() => thickness = v);
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
                            keyboardType: const TextInputType.numberWithOptions(
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
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown("Unit", _materialUnits(), unit, (v) {
                  setState(() => unit = v);
                  _calculateCosts();
                }),
              ),
            ],
          ),

          // Note about thickness
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "Note: Thickness is required before costs can be calculated.",
              style: GoogleFonts.openSans(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Calculating indicator
          if (_isCalculating)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
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

  Widget _buildMaterialTypeField() {
    final hasTypes = _selectedMaterial!.types.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Material Name",
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 6),

        if (hasTypes && !_isCustomType)
          DropdownButtonFormField<String>(
            value: _selectedMaterialType,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
            hint: const Text("Select type or enter custom"),
            items: [
              ..._selectedMaterial!.types.map((type) {
                return DropdownMenuItem(
                  value: type.name,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(type.name, overflow: TextOverflow.ellipsis),
                      ),
                      if (type.pricePerSqm != null && type.pricePerSqm! > 0)
                        Text(
                          '₦${type.pricePerSqm!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFA16438),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const DropdownMenuItem(
                value: 'custom',
                child: Text(
                  "Enter custom name",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFA16438),
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              _onMaterialTypeSelected(value);
              _calculateCosts();
            },
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: materialTypeController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(12),
                    hintText: hasTypes
                        ? "Enter custom material name"
                        : "Enter material name",
                    hintStyle: const TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
              ),
              if (hasTypes && _isCustomType)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isCustomType = false;
                        _selectedMaterialType = null;
                        materialTypeController.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFA16438),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "Back",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCalculationResults() {
    final needsPricing = _costCalculation?.calculation.needsPricing == true;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA16438)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Calculated Costs",
            style: GoogleFonts.openSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFA16438),
            ),
          ),
          if (needsPricing) ...[
            const SizedBox(height: 6),
            Text(
              "This material is unpriced. It will be added with 0 cost.",
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
          ],
          const SizedBox(height: 8),
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
            "₦${_costCalculation!.pricing.projectCost.toStringAsFixed(2)}",
          ),
          _buildResultRow(
            "Minimum Boards:",
            "${_costCalculation!.quantity.minimumUnits} board(s)",
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
