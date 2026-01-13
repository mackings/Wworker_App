import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Quotation/Api/materialService.dart';
import 'package:wworker/App/Quotation/Model/MaterialCostModel.dart';
import 'package:wworker/App/Quotation/Model/Materialmodel.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';




class AddMaterialCard extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final void Function(Map<String, dynamic>)? onAddItem;

  const AddMaterialCard({
    super.key,
    this.title = "Add Materials",
    this.icon,
    this.color,
    this.onAddItem,
  });

  @override
  State<AddMaterialCard> createState() => _AddMaterialCardState();
}

class _AddMaterialCardState extends State<AddMaterialCard> {
  final MaterialService _materialService = MaterialService();
  
  final List<String> linearUnits = ["mm", "cm", "m", "ft", "inches"];

  // API Data
  List<MaterialModel> _materials = [];
  bool _isLoadingMaterials = true;
  MaterialModel? _selectedMaterial;
  String? _selectedMaterialType;
  bool _isCustomType = false;

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
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoadingMaterials = true);
    final materials = await _materialService.getMaterials();
    setState(() {
      _materials = materials;
      _isLoadingMaterials = false;
      // Auto-select first material if available
      if (_materials.isNotEmpty && _selectedMaterial == null) {
        _selectedMaterial = _materials.first;
        _setDefaultUnitsForMaterial(_materials.first);
        _loadThicknessesForMaterial(_materials.first);
      }
    });
  }



  /// Set default units based on material type
/// Set default units based on material type
void _setDefaultUnitsForMaterial(MaterialModel material) {
  final materialUnit = material.unit?.toLowerCase() ?? '';

  String defaultUnit;

  if (materialUnit.contains('length') ||
      materialUnit.contains('sheet') ||
      materialUnit.contains('width')) {
    defaultUnit = 'cm';
  } else if (materialUnit.contains('square meter') ||
      materialUnit.contains('sqm') ||
      materialUnit.contains('m²')) {
    defaultUnit = 'm';
  } else if (materialUnit.contains('yard') ||
      materialUnit.contains('inch')) {
    defaultUnit = 'in';
  } else {
    final allowedUnits = ["mm", "cm", "m", "ft", "in"];
    defaultUnit = allowedUnits.contains(material.standardUnit)
        ? material.standardUnit!
        : 'cm';
  }

  // ✅ Update state AFTER build completes
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      setState(() {
        unit = defaultUnit;
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
    thicknesses.addAll(material.foamThicknesses
        .map((ft) => ft.thickness.toString())
        .toList());
  }

  if (material.foamVariants.isNotEmpty) {
    thicknesses.addAll(material.foamVariants
        .map((fv) => fv.thickness.toString())
        .toList());
  }

  // 2. Common thicknesses
  if (material.commonThicknesses.isNotEmpty) {
    thicknesses.addAll(material.commonThicknesses
        .map((ct) => ct.thickness.toString())
        .toList());
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
        unit == null) {
      return;
    }

    final w = double.tryParse(widthController.text);
    final l = double.tryParse(lengthController.text);

    if (w == null || l == null) return;

    setState(() => _isCalculating = true);

    try {
      final result = await _materialService.calculateMaterialCost(
        materialId: _selectedMaterial!.id,
        requiredWidth: w,
        requiredLength: l,
        requiredUnit: unit!,
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
    // Validate all required fields
    if (_selectedMaterial == null ||
        materialTypeController.text.trim().isEmpty ||
        widthController.text.isEmpty ||
        lengthController.text.isEmpty ||
        thickness == null ||
        unit == null ||
        _costCalculation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields and calculate costs before adding."),
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
      "Thickness": thickness,
      "Unit": unit,
      "Sqm": _costCalculation!.dimensions.projectAreaSqm.toStringAsFixed(2),
      "Price": _costCalculation!.pricing.projectCost.toStringAsFixed(2),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6E6E6)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadMaterials,
                  tooltip: "Refresh materials",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Material type selection (horizontal scroll tabs from API)
          if (_isLoadingMaterials)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_materials.isEmpty)
            Center(
              child: Text(
                "No materials available",
                style: GoogleFonts.openSans(
                  color: const Color(0xFF7B7B7B),
                ),
              ),
            )
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
                child: _buildDropdown(
                  "Thickness",
                  _availableThicknesses.isNotEmpty
                      ? _availableThicknesses
                      : ["No thickness available"],
                  thickness,
                  (v) => setState(() => thickness = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown("Unit", linearUnits, unit, (v) {
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
              "Note: Thickness is auto-populated from material data and is for reference only",
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
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
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
                        child: Text(
                          type.name,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Color(0xFFA16438)),
                    SizedBox(width: 4),
                    Text(
                      "Enter custom name",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFA16438),
                      ),
                    ),
                  ],
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
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    color: const Color(0xFFA16438),
                    onPressed: () {
                      setState(() {
                        _isCustomType = false;
                        _selectedMaterialType = null;
                        materialTypeController.clear();
                      });
                    },
                    tooltip: "Back to types",
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCalculationResults() {
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
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(
                      v,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged:
              items.first == "No thickness available" ? null : onChanged,
        ),
      ],
    );
  }
}
