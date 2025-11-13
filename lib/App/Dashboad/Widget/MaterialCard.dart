import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Dashboad/Widget/Calculation_helper.dart';
import 'package:wworker/App/Product/Api/ProService.dart';
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
  final List<String> units = ["mm", "cm", "m", "ft", "in"];
  final List<String> products = ["Wood", "Board", "Foam", "Other materials"];

  String selectedProduct = "Wood";
  final List<String> numbers = List.generate(100, (i) => "${i + 1}");

  // Project/Required dimensions
  String? width, length, thickness, unit;

  // Standard material dimensions
  String? standardWidth, standardLength, standardUnit;

  // Calculated values
  double? projectAreaSqm;
  double? standardAreaSqm;
  double? pricePerSqm; // User enters this
  double? totalBoardPrice; // Calculated: standardArea × pricePerSqm
  double? projectCost;
  int? minimumUnits;
  double wasteThreshold = 0.75; // Default 75%

  final TextEditingController materialNameController = TextEditingController();
  final TextEditingController pricePerUnitController = TextEditingController();

  @override
  void dispose() {
    materialNameController.dispose();
    pricePerUnitController.dispose();
    super.dispose();
  }

  /// Calculate project area from width × length
  void _calculateProjectArea() {
    if (width != null && length != null && unit != null) {
      final w = double.tryParse(width!);
      final l = double.tryParse(length!);

      if (w != null && l != null) {
        setState(() {
          projectAreaSqm = MaterialCalculationHelper.calculateArea(
            width: w,
            length: l,
            unit: unit!,
          );
          _calculateAllCosts();
        });
      }
    }
  }

  /// Calculate standard material area
  void _calculateStandardArea() {
    if (standardWidth != null &&
        standardLength != null &&
        standardUnit != null) {
      final w = double.tryParse(standardWidth!);
      final l = double.tryParse(standardLength!);

      if (w != null && l != null) {
        setState(() {
          standardAreaSqm = MaterialCalculationHelper.calculateArea(
            width: w,
            length: l,
            unit: standardUnit!,
          );
          _calculateAllCosts();
        });
      }
    }
  }

  /// Calculate all costs and minimum units
  void _calculateAllCosts() {
    if (standardAreaSqm != null &&
        pricePerUnitController.text.isNotEmpty &&
        projectAreaSqm != null) {
      final pricePerUnit = double.tryParse(pricePerUnitController.text.trim());

      if (pricePerUnit != null && standardAreaSqm! > 0) {
        setState(() {
          // Step 1: Price per sqm is what user entered
          pricePerSqm = pricePerUnit;

          // Step 2: Calculate total board price
          totalBoardPrice = MaterialCalculationHelper.calculateTotalBoardPrice(
            totalAreaSqm: standardAreaSqm!,
            pricePerSqm: pricePerUnit,
          );

          // Step 3: Calculate project cost
          projectCost = MaterialCalculationHelper.calculateProjectCost(
            requiredAreaSqm: projectAreaSqm!,
            pricePerSqm: pricePerUnit,
          );

          // Step 4: Calculate minimum units needed
          minimumUnits = MaterialCalculationHelper.calculateMinimumUnits(
            requiredArea: projectAreaSqm!,
            unitArea: standardAreaSqm!,
            wasteThreshold: wasteThreshold,
          );
        });
      }
    }
  }

  void _handleAddItem() {
    // Validate all required fields
    if (materialNameController.text.trim().isEmpty ||
        width == null ||
        length == null ||
        thickness == null ||
        unit == null ||
        standardWidth == null ||
        standardLength == null ||
        standardUnit == null ||
        pricePerUnitController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields before adding."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Ensure calculations are done
    if (projectAreaSqm == null ||
        standardAreaSqm == null ||
        pricePerSqm == null ||
        totalBoardPrice == null ||
        projectCost == null ||
        minimumUnits == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please wait for calculations to complete."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calculate waste information
    final wasteInfo = MaterialCalculationHelper.calculateWasteInfo(
      requiredArea: projectAreaSqm!,
      unitArea: standardAreaSqm!,
      unitsUsed: minimumUnits!,
    );

    // Create item WITHOUT underscore fields (only display fields)
    final item = {
      // Display Fields (shown to user)
      "Product": selectedProduct,
      "Materialname": materialNameController.text.trim(),
      "Width": width,
      "Length": length,
      "Thickness": thickness,
      "Unit": unit,
      "Sqm": projectAreaSqm!.toStringAsFixed(2),
      "Price": projectCost!.toStringAsFixed(2),
      "quantity": minimumUnits.toString(),
    };

    // If you need the calculation fields for backend, create a separate map
    final calculationData = {
      "_ProjectAreaSqm": projectAreaSqm.toString(),
      "_StandardWidth": standardWidth,
      "_StandardLength": standardLength,
      "_StandardUnit": standardUnit,
      "_StandardAreaSqm": standardAreaSqm.toString(),
      "_PricePerSqm": pricePerSqm.toString(),
      "_TotalBoardPrice": totalBoardPrice.toString(),
      "_ProjectCost": projectCost.toString(),
      "_MinimumUnits": minimumUnits.toString(),
      "_WasteThreshold": wasteThreshold.toString(),
      "_TotalAreaUsed": wasteInfo['totalAreaUsed'].toString(),
      "_WasteArea": wasteInfo['wasteArea'].toString(),
      "_WastePercentage": wasteInfo['wastePercentage'].toString(),
    };

    // Pass both maps if needed, or just the display item
    widget.onAddItem?.call(item);

    // Reset form
    setState(() {
      width = null;
      length = null;
      thickness = null;
      unit = null;
      standardWidth = null;
      standardLength = null;
      standardUnit = null;
      projectAreaSqm = null;
      standardAreaSqm = null;
      pricePerSqm = null;
      totalBoardPrice = null;
      projectCost = null;
      minimumUnits = null;
    });

    materialNameController.clear();
    pricePerUnitController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Material added successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 35,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD3D3D3)),
        borderRadius: BorderRadius.circular(12),
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
            ],
          ),

          const SizedBox(height: 16),

          // Product type selection
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: products.map((p) {
                final selected = selectedProduct == p;
                return GestureDetector(
                  onTap: () => setState(() => selectedProduct = p),
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
                      p,
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
          _buildInput("Material Name", controller: materialNameController),

          const SizedBox(height: 20),

          // Section 1: Standard Material Size
          _buildSectionHeader("Standard Material Size (from supplier)"),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDropdown("Length (longer)", numbers, standardLength, (v) {
                setState(() => standardLength = v);
                _calculateStandardArea();
              }),
              _buildDropdown("Width (shorter)", numbers, standardWidth, (v) {
                setState(() => standardWidth = v);
                _calculateStandardArea();
              }),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDropdown("Unit", units, standardUnit, (v) {
                setState(() => standardUnit = v);
                _calculateStandardArea();
              }),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 95) / 2,
                child: _buildInput(
                  "Price per sq m",
                  controller: pricePerUnitController,
                  hint: "₦ per sq m",
                  onChanged: (_) => _calculateAllCosts(),
                ),
              ),
            ],
          ),

          // Display standard area and total board price
          if (standardAreaSqm != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Standard Area: ${MaterialCalculationHelper.formatArea(standardAreaSqm!)}",
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: const Color(0xFF7B7B7B),
                      ),
                    ),
                    if (totalBoardPrice != null)
                      Text(
                        "Full Board Price: ${MaterialCalculationHelper.formatCurrency(totalBoardPrice!)}",
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA16438),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Section 2: Project/Required Size
          _buildSectionHeader("Project Size (what you need)"),
          const SizedBox(height: 12),

          // Length + Width
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDropdown("Length (longer)", numbers, length, (v) {
                setState(() => length = v);
                _calculateProjectArea();
              }),
              _buildDropdown("Width (shorter)", numbers, width, (v) {
                setState(() => width = v);
                _calculateProjectArea();
              }),
            ],
          ),

          const SizedBox(height: 12),

          // Thickness + Unit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDropdown(
                "Thickness",
                numbers,
                thickness,
                (v) => setState(() => thickness = v),
              ),
              _buildDropdown("Unit", units, unit, (v) {
                setState(() => unit = v);
                _calculateProjectArea();
              }),
            ],
          ),

          // Note about thickness
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "Note: Thickness is for reference only, not used in area calculations",
              style: GoogleFonts.openSans(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ),

          // Display project area
          if (projectAreaSqm != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Project Area: ${MaterialCalculationHelper.formatArea(projectAreaSqm!)}",
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: const Color(0xFF7B7B7B),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Waste Threshold Slider
          _buildSectionHeader(
            "Waste Threshold (round up when remainder exceeds)",
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: wasteThreshold,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  label: "${(wasteThreshold * 100).toInt()}%",
                  activeColor: const Color(0xFFA16438),
                  inactiveColor: const Color(0xFFCCA183),
                  onChanged: (value) {
                    setState(() {
                      wasteThreshold = value;
                      _calculateAllCosts();
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${(wasteThreshold * 100).toInt()}%",
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFA16438),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Section 3: Calculated Results
          if (pricePerSqm != null &&
              totalBoardPrice != null &&
              projectCost != null &&
              minimumUnits != null)
            Container(
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
                    "Price per sq m:",
                    MaterialCalculationHelper.formatCurrency(pricePerSqm!),
                  ),
                  _buildResultRow(
                    "Full Board Price:",
                    MaterialCalculationHelper.formatCurrency(totalBoardPrice!),
                  ),
                  const Divider(color: Color(0xFFCCA183)),
                  _buildResultRow(
                    "Project Cost:",
                    MaterialCalculationHelper.formatCurrency(projectCost!),
                  ),
                  _buildResultRow("Minimum Boards:", "$minimumUnits board(s)"),
                  // Show waste information
                  if (standardAreaSqm != null && projectAreaSqm != null)
                    Builder(
                      builder: (context) {
                        final wasteInfo =
                            MaterialCalculationHelper.calculateWasteInfo(
                              requiredArea: projectAreaSqm!,
                              unitArea: standardAreaSqm!,
                              unitsUsed: minimumUnits!,
                            );
                        return Column(
                          children: [
                            const Divider(color: Color(0xFFCCA183)),
                            _buildResultRow(
                              "Total Area Used:",
                              MaterialCalculationHelper.formatArea(
                                wasteInfo['totalAreaUsed'],
                              ),
                            ),
                            _buildResultRow(
                              "Waste:",
                              "${MaterialCalculationHelper.formatArea(wasteInfo['wasteArea'])} (${wasteInfo['wastePercentage'].toStringAsFixed(1)}%)",
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),

          const SizedBox(height: 20),
          CustomButton(text: "Add Item", onPressed: _handleAddItem),
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

  Widget _buildInput(
    String label, {
    TextEditingController? controller,
    String? hint,
    void Function(String)? onChanged,
  }) => Column(
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
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(12),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    ],
  );

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 95) / 2,
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
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
            items: items
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
