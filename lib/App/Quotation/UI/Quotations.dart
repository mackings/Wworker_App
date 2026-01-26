import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Dashboad/Widget/emptyQuote.dart';
import 'package:wworker/App/Dashboad/Widget/itemCard.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/AddMaterial.dart';
import 'package:wworker/App/Quotation/UI/FirstQuote.dart';
import 'package:wworker/App/Quotation/UI/AllclientQuotations.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Api/materialService.dart';
import 'package:wworker/App/Quotation/Model/MaterialCostModel.dart';
import 'package:wworker/App/Quotation/Model/Materialmodel.dart';
import 'package:wworker/App/Quotation/UI/BomSummary.dart';
import 'package:wworker/App/Quotation/Widget/QGlancecard.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/App/OverHead/Widget/OCCalculator.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';



class AllQuotations extends ConsumerStatefulWidget {
  const AllQuotations({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AllQuotationsState();
}

class _AllQuotationsState extends ConsumerState<AllQuotations> {
  final BOMService _bomService = BOMService();
  List<Map<String, dynamic>> allQuotations = [];
  Map<int, int> quantities = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllQuotations();
  }

  Future<List<_BomImportItem>> _fetchBoms() async {
    final response = await _bomService.getAllBOMs();
    if (response["success"] == true) {
      final data = response["data"] as List<dynamic>? ?? [];
      return data
          .map((item) => _BomImportItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> _importBom(BuildContext context, _BomImportItem bom) async {
    final quotationNotifier = ref.read(quotationSummaryProvider.notifier);
    final newQuotation = {
      "product": bom.product,
      "materials": bom.materials,
      "additionalCosts": bom.additionalCosts,
      "costPrice": bom.pricing.costPrice,
      "sellingPrice": bom.pricing.sellingPrice,
      "overheadCost": bom.pricing.overheadCost,
      "markupPercentage": bom.pricing.markupPercentage,
      "pricingMethod": bom.pricing.pricingMethod,
      "expectedDuration": bom.expectedDurationValue,
      "expectedPeriod": bom.expectedDurationUnit,
      "importedFromBom": bom.id,
    };

    await quotationNotifier.addNewQuotation(newQuotation);
    await _loadAllQuotations();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ BOM imported to quotations"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editBomBeforeImport(BuildContext context, _BomImportItem bom) async {
    final materialNotifier = ref.read(materialProvider.notifier);
    final quotationNotifier = ref.read(quotationSummaryProvider.notifier);

    await materialNotifier.clearAll();
    for (final item in bom.materials) {
      await materialNotifier.addMaterial(item);
    }
    for (final cost in bom.additionalCosts) {
      await materialNotifier.addAdditionalCost(cost);
    }

    await quotationNotifier.setProduct(bom.product);
    await PricingSettingsManager.saveMarkup(bom.pricing.markupPercentage);
    await PricingSettingsManager.savePricingMethod(bom.pricing.pricingMethod);

    if (mounted) {
      Navigator.pop(context);
      Nav.push(const BOMSummary());
    }
  }

  void _showImportBomsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.98,
          minChildSize: 0.8,
          maxChildSize: 0.98,
          expand: true,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: FutureBuilder<List<_BomImportItem>>(
                future: _fetchBoms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final boms = snapshot.data ?? [];
                  if (boms.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          "No BOMs available to import",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }

                  return SafeArea(
                    top: false,
                    child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Import BOMs",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF302E2E),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: boms.length,
                          itemBuilder: (context, index) {
                            final bom = boms[index];
                            return _ImportBomDetailsCard(
                              bom: bom,
                              onImport: () => _importBom(context, bom),
                              onEdit: () => _editBomBeforeImport(context, bom),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadAllQuotations() async {
    setState(() => isLoading = true);

    final quotations = await ref
        .read(quotationSummaryProvider.notifier)
        .getAllQuotations();

    setState(() {
      allQuotations = quotations;
      // Initialize quantities for each quotation
      for (int i = 0; i < quotations.length; i++) {
        quantities[i] = 1;
      }
      isLoading = false;
    });
  }

  void _increaseQuantity(int index) {
    setState(() {
      quantities[index] = (quantities[index] ?? 1) + 1;
    });
    _logQuantityChange(index);
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if ((quantities[index] ?? 1) > 1) {
        quantities[index] = (quantities[index] ?? 1) - 1;
      }
    });
    _logQuantityChange(index);
  }

  void _logQuantityChange(int index) {
    if (index < 0 || index >= allQuotations.length) return;
    final quotation = allQuotations[index];
    final quantity = quantities[index] ?? 1;
    final costPrice = _getCostPrice(quotation);
    final sellingPrice = _getSellingPrice(quotation);
    final totalCost = _calculateTotalCost(quotation, quantity);
    final totalSelling = _calculateTotalSellingPrice(quotation, quantity);

    debugPrint(
      "📊 [QUOTE QTY] index=$index qty=$quantity "
      "costUnit=${costPrice.toStringAsFixed(2)} "
      "sellUnit=${sellingPrice.toStringAsFixed(2)} "
      "costTotal=${totalCost.toStringAsFixed(2)} "
      "sellTotal=${totalSelling.toStringAsFixed(2)}",
    );
  }

  Future<void> _deleteQuotation(String quotationId, int index) async {
    await ref
        .read(quotationSummaryProvider.notifier)
        .deleteQuotationById(quotationId);
    await _loadAllQuotations(); // Refresh the list

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Quotation deleted"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Get cost price from quotation (materials + additional costs)
  double _getCostPrice(Map<String, dynamic> quotation) {
    // If costPrice is already calculated and stored
    if (quotation.containsKey("costPrice")) {
      return (quotation["costPrice"] as num?)?.toDouble() ?? 0.0;
    }

    // Otherwise calculate it
    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );

    double materialTotal = materials.fold<double>(
      0,
      (sum, item) =>
          sum + (double.tryParse(item["Price"]?.toString() ?? "0") ?? 0.0),
    );

    double additionalTotal = additionalCosts.fold<double>(
      0,
      (sum, item) =>
          sum + (double.tryParse(item["amount"]?.toString() ?? "0") ?? 0.0),
    );

    return materialTotal + additionalTotal;
  }

  // ✅ Get selling price from quotation (cost price + overhead)
  double _getSellingPrice(Map<String, dynamic> quotation) {
    // If sellingPrice is already calculated and stored
    if (quotation.containsKey("sellingPrice")) {
      return (quotation["sellingPrice"] as num?)?.toDouble() ?? 0.0;
    }

    // Otherwise return cost price (for backward compatibility)
    return _getCostPrice(quotation);
  }

  // ✅ Calculate total with quantity multiplier
  double _calculateTotalCost(Map<String, dynamic> quotation, int quantity) {
    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );

    double materialTotal = 0.0;
    for (final material in materials) {
      final price =
          double.tryParse((material["Price"] ?? "0").toString()) ?? 0.0;
      final materialQty =
          int.tryParse((material["quantity"] ?? "1").toString()) ?? 1;
      final disableIncrement = material["disableIncrement"] == true;
      final multiplier = disableIncrement ? 1 : quantity;
      materialTotal += price * materialQty * multiplier;
    }

    double additionalTotal = 0.0;
    for (final cost in additionalCosts) {
      final amount =
          double.tryParse((cost["amount"] ?? "0").toString()) ?? 0.0;
      additionalTotal += amount * quantity;
    }

    return materialTotal + additionalTotal;
  }

  // ✅ Calculate total selling price with quantity multiplier
  double _calculateTotalSellingPrice(
    Map<String, dynamic> quotation,
    int quantity,
  ) {
    final baseCost = _getCostPrice(quotation);
    final baseSelling = _getSellingPrice(quotation);
    if (baseCost <= 0) return 0.0;
    final totalCost = _calculateTotalCost(quotation, quantity);
    final ratio = baseSelling / baseCost;
    return totalCost * ratio;
  }

  Future<void> _showBomBreakdownSheet(
    Map<String, dynamic> quotation,
    int index,
  ) async {
    final product = Map<String, dynamic>.from(quotation["product"] ?? {});
    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.7,
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                product["name"]?.toString().isNotEmpty == true
                                    ? product["name"].toString()
                                    : "Edit BOM",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF302E2E),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildEditSectionHeader(
                              title: "Materials",
                              count: materials.length,
                              icon: Icons.layers_outlined,
                              onAdd: () async {
                                Navigator.pop(context);
                                await _openMaterialEditorForBom(quotation);
                              },
                            ),
                            const SizedBox(height: 8),
                            if (materials.isEmpty)
                              _buildEmptySection("No materials added yet.")
                            else
                              ...materials.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                return ItemsCard(
                                  item: item,
                                  useBomStyle: true,
                                  showPriceIncrementToggle: true,
                                  isPriceIncrementDisabled:
                                      item["disableIncrement"] == true,
                                  onPriceIncrementToggle: (value) {
                                    setSheetState(() {
                                      materials[idx] = {
                                        ...item,
                                        "disableIncrement": value,
                                      };
                                    });
                                  },
                                  onEdit: () async {
                                    final updated =
                                        await _showMaterialFormSheet(
                                      initial: item,
                                    );
                                    if (updated == null) return;
                                    setSheetState(() {
                                      materials[idx] = updated;
                                    });
                                  },
                                  onDelete: () {
                                    setSheetState(() {
                                      materials.removeAt(idx);
                                    });
                                  },
                                );
                              }),
                            const SizedBox(height: 16),
                            _buildEditSectionHeader(
                              title: "Additional Costs",
                              count: additionalCosts.length,
                              icon: Icons.attach_money_outlined,
                              onAdd: () async {
                                final newItem =
                                    await _showAdditionalCostFormSheet();
                                if (newItem == null) return;
                                setSheetState(() {
                                  additionalCosts.add(newItem);
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            if (additionalCosts.isEmpty)
                              _buildEmptySection("No additional costs added.")
                            else
                              ...additionalCosts.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                return ItemsCard(
                                  item: item,
                                  useBomStyle: true,
                                  onEdit: () async {
                                    final updated =
                                        await _showAdditionalCostFormSheet(
                                      initial: item,
                                    );
                                    if (updated == null) return;
                                    setSheetState(() {
                                      additionalCosts[idx] = updated;
                                    });
                                  },
                                  onDelete: () {
                                    setSheetState(() {
                                      additionalCosts.removeAt(idx);
                                    });
                                  },
                                );
                              }),
                            const SizedBox(height: 24),
                            CustomButton(
                              text: "Save Changes",
                              onPressed: () async {
                                final updated =
                                    _buildUpdatedQuotationForSave(
                                  quotation,
                                  materials,
                                  additionalCosts,
                                );
                                final id = quotation["id"] as String? ?? "";
                                if (id.isEmpty) return;

                                final success = await ref
                                    .read(quotationSummaryProvider.notifier)
                                    .updateQuotationById(id, updated);

                                if (!mounted) return;
                                Navigator.pop(context);
                                if (success) {
                                  await _loadAllQuotations();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("✅ BOM updated"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Failed to update BOM"),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openMaterialEditorForBom(
    Map<String, dynamic> quotation,
  ) async {
    final materialNotifier = ref.read(materialProvider.notifier);
    final quotationId = quotation["id"] as String?;
    if (quotationId == null || quotationId.isEmpty) return;

    await materialNotifier.clearAll();
    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );

    for (final item in materials) {
      await materialNotifier.addMaterial(item);
    }
    for (final cost in additionalCosts) {
      await materialNotifier.addAdditionalCost(cost);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMaterial(autoPopAfterAdd: true),
      ),
    );

    final updatedState = ref.read(materialProvider);
    final updatedMaterials = List<Map<String, dynamic>>.from(
      updatedState["materials"] ?? [],
    );
    final updatedCosts = List<Map<String, dynamic>>.from(
      updatedState["additionalCosts"] ?? [],
    );

    final updatedPayload = _buildUpdatedQuotationForSave(
      quotation,
      updatedMaterials,
      updatedCosts,
    );

    await ref
        .read(quotationSummaryProvider.notifier)
        .updateQuotationById(quotationId, updatedPayload);

    await _loadAllQuotations();
    if (!mounted) return;
    final updatedIndex = allQuotations.indexWhere(
      (q) => q["id"] == quotationId,
    );
    if (updatedIndex == -1) return;
    final updatedQuotation = allQuotations[updatedIndex];
    await _showBomBreakdownSheet(updatedQuotation, updatedIndex);
  }

  Map<String, dynamic> _buildUpdatedQuotationForSave(
    Map<String, dynamic> quotation,
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) {
    final updated = Map<String, dynamic>.from(quotation);
    updated["materials"] = materials;
    updated["additionalCosts"] = additionalCosts;

    final baseCost = _getCostPrice({
      ...quotation,
      "materials": materials,
      "additionalCosts": additionalCosts,
    });
    updated["costPrice"] = baseCost;

    final existingCost =
        (quotation["costPrice"] as num?)?.toDouble() ?? 0.0;
    final existingSell =
        (quotation["sellingPrice"] as num?)?.toDouble() ?? 0.0;
    if (existingCost > 0 && existingSell > 0) {
      final ratio = existingSell / existingCost;
      updated["sellingPrice"] = baseCost * ratio;
    } else {
      updated["sellingPrice"] = baseCost;
    }

    return updated;
  }

  Widget _buildEditSectionHeader({
    required String title,
    required int count,
    required IconData icon,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Icon(icon, color: ColorsApp.btnColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "$title ($count)",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF302E2E),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Add"),
          style: TextButton.styleFrom(
            foregroundColor: ColorsApp.btnColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSectionLabel({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ColorsApp.btnColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF302E2E),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showMaterialFormSheet({
    Map<String, dynamic>? initial,
  }) async {
    final materialService = MaterialService();
    MaterialCostModel? costCalculation;
    bool isCalculating = false;
    List<MaterialModel> availableMaterials = [];
    String? resolvedMaterialId;

    final nameController = TextEditingController(
      text: initial?["Materialname"]?.toString() ?? "",
    );
    final widthController = TextEditingController(
      text: initial?["Width"]?.toString() ?? "",
    );
    final lengthController = TextEditingController(
      text: initial?["Length"]?.toString() ?? "",
    );
    final thicknessController = TextEditingController(
      text: initial?["Thickness"]?.toString() ?? "",
    );
    final unitController = TextEditingController(
      text: initial?["Unit"]?.toString() ?? "",
    );
    final sqmController = TextEditingController(
      text: initial?["Sqm"]?.toString() ?? "",
    );
    final priceController = TextEditingController(
      text: initial?["Price"]?.toString() ?? "",
    );
    final quantityController = TextEditingController(
      text: initial?["quantity"]?.toString() ?? "1",
    );
    bool disableIncrement = initial?["disableIncrement"] == true;
    String? unitValue =
        unitController.text.trim().isEmpty ? null : unitController.text.trim();
    const linearUnits = ["mm", "cm", "m", "ft", "in"];
    double? latestPriceValue;

    Future<String?> _resolveMaterialId() async {
      if (resolvedMaterialId != null) return resolvedMaterialId;
      if (availableMaterials.isEmpty) {
        availableMaterials = await materialService.getMaterials();
      }
      final productName = initial?["Product"]?.toString() ?? "";
      if (productName.isEmpty) return null;
      try {
        final match = availableMaterials.firstWhere(
          (m) => m.name.toLowerCase() == productName.toLowerCase(),
        );
        resolvedMaterialId = match.id;
      } catch (_) {
        resolvedMaterialId = null;
      }
      return resolvedMaterialId;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.98,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    Future<void> calculateCost() async {
                      if (isCalculating) return;
                      setModalState(() => isCalculating = true);
                      final width =
                          double.tryParse(widthController.text.trim());
                      final length =
                          double.tryParse(lengthController.text.trim());
                      final unit = unitValue ?? unitController.text.trim();
                      final quantity =
                          int.tryParse(quantityController.text.trim()) ?? 1;

                      if (width == null || length == null || unit.isEmpty) {
                        setModalState(() => isCalculating = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Enter width, length, and unit first."),
                          ),
                        );
                        return;
                      }

                      final materialId = await _resolveMaterialId();
                      if (materialId == null || materialId.isEmpty) {
                        setModalState(() => isCalculating = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Material not found. Please check the material name.",
                            ),
                          ),
                        );
                        return;
                      }

                      final result = await materialService.calculateMaterialCost(
                        materialId: materialId,
                        requiredWidth: width,
                        requiredLength: length,
                        requiredUnit: unit,
                        materialType:
                            nameController.text.trim().isEmpty
                                ? null
                                : nameController.text.trim(),
                        foamThickness:
                            double.tryParse(thicknessController.text.trim()),
                        quantity: quantity,
                      );

                      setModalState(() {
                        isCalculating = false;
                        costCalculation = result;
                        if (result != null) {
                          sqmController.text =
                              result.dimensions.projectAreaSqm
                                  .toStringAsFixed(2);
                          latestPriceValue =
                              result.pricing.totalMaterialCost.roundToDouble();
                          priceController.text = NumberFormat.decimalPattern()
                              .format(latestPriceValue!.toInt());
                        }
                      });
                    }

                    return Column(
                      children: [
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Edit Material",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF302E2E),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormSectionLabel(
                                  icon: Icons.layers_outlined,
                                  title: "Material Details",
                                ),
                                const SizedBox(height: 10),
                                CustomTextField(
                                  label: "Material Name",
                                  controller: nameController,
                                ),
                                const SizedBox(height: 16),
                                _buildFormSectionLabel(
                                  icon: Icons.straighten_outlined,
                                  title: "Dimensions",
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        label: "Width",
                                        controller: widthController,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CustomTextField(
                                        label: "Length",
                                        controller: lengthController,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        label: "Thickness",
                                        controller: thicknessController,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CustomTextField(
                                        label: "Unit",
                                        isDropdown: true,
                                        dropdownItems: linearUnits,
                                        value: unitValue,
                                        onChanged: (value) {
                                          setModalState(() {
                                            unitValue = value;
                                            unitController.text =
                                                value ?? "";
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CustomTextField(
                                        label: "Sqm",
                                        controller: sqmController,
                                        enabled: false,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        label: "Quantity",
                                        controller: quantityController,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CustomTextField(
                                        label: "Price",
                                        controller: priceController,
                                        enabled: false,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Disable price increment",
                                      style: TextStyle(
                                        color: Color(0xFF302E2E),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: disableIncrement,
                                      onChanged: (value) {
                                        setModalState(() {
                                          disableIncrement = value;
                                        });
                                      },
                                      activeColor: const Color(0xFF8B4513),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (isCalculating)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
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
                                if (!isCalculating)
                                  CustomButton(
                                    text: "Calculate",
                                    outlined: true,
                                    onPressed: calculateCost,
                                  ),
                                if (costCalculation != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFA16438),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Calculated Price",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF302E2E),
                                          ),
                                        ),
                                        Text(
                                          "₦${priceController.text}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFA16438),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                CustomButton(
                                  text: "Save Changes",
                                  onPressed: costCalculation == null
                                      ? () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Please calculate cost before saving.",
                                              ),
                                            ),
                                          );
                                        }
                                      : () {
                                          Navigator.pop(
                                            context,
                                            {
                                              "Product":
                                                  initial?["Product"] ?? "",
                                              "Materialname":
                                                  nameController.text.trim(),
                                              "Width":
                                                  widthController.text.trim(),
                                              "Length":
                                                  lengthController.text.trim(),
                                              "Thickness": thicknessController
                                                  .text
                                                  .trim(),
                                              "Unit":
                                                  unitValue ??
                                                      unitController.text
                                                          .trim(),
                                              "Sqm":
                                                  sqmController.text.trim(),
                                              "Price":
                                                  latestPriceValue != null
                                                      ? latestPriceValue!
                                                          .toStringAsFixed(0)
                                                      : priceController.text
                                                          .trim()
                                                          .replaceAll(
                                                            ",",
                                                            "",
                                                          ),
                                              "quantity": quantityController
                                                      .text
                                                      .trim()
                                                      .isEmpty
                                                  ? "1"
                                                  : quantityController.text
                                                      .trim(),
                                              "disableIncrement":
                                                  disableIncrement,
                                            },
                                          );
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );

    return result;
  }

  Future<Map<String, dynamic>?> _showAdditionalCostFormSheet({
    Map<String, dynamic>? initial,
  }) async {
    final typeController = TextEditingController(
      text: initial?["type"]?.toString() ?? "",
    );
    final descriptionController = TextEditingController(
      text: initial?["description"]?.toString() ?? "",
    );
    final amountController = TextEditingController(
      text: initial?["amount"]?.toString() ?? "",
    );

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    initial == null
                        ? "Add Additional Cost"
                        : "Edit Additional Cost",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF302E2E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: "Cost Type",
                    controller: typeController,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: "Description",
                    controller: descriptionController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: "Amount",
                    controller: amountController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text:
                        initial == null ? "Add Cost" : "Save Changes",
                    onPressed: () {
                      Navigator.pop(
                        context,
                        {
                          "type": typeController.text.trim(),
                          "description": descriptionController.text.trim(),
                          "amount": amountController.text.trim(),
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for provider updates
    ref.listen<Map<String, dynamic>>(quotationSummaryProvider, (prev, next) {
      _loadAllQuotations();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: CustomText(title: "Quotations"),
        actions: const [
          GuideHelpIcon(
            title: "Import BOMs",
            message:
                "Import BOMs to turn them into quotations. Review existing quotations "
                "here, adjust quantities, and confirm pricing with the client. Once "
                "approved, you can proceed to Orders or Invoices.",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : allQuotations.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        child: CustomEmptyQuotes(
                          title: "",
                          buttonText: "",
                          emptyMessage: "No Quotations Found",
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAllQuotations,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 20,
                        ),
                        itemCount: allQuotations.length,
                        itemBuilder: (context, index) {
                          final quotation = allQuotations[index];
                          final product = quotation["product"] ?? {};
                          final currentQuantity = quantities[index] ?? 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: QuoteGlanceCard(
                              imageUrl: product["image"] ?? "",
                              productName: product["name"] ?? "Unknown Product",
                              bomNo: product["productId"] ?? "N/A",
                              description: product["description"] ?? "",
                              costPrice: _calculateTotalCost(
                                quotation,
                                currentQuantity,
                              ),
                              sellingPrice: _calculateTotalSellingPrice(
                                quotation,
                                currentQuantity,
                              ),
                              quantity: currentQuantity,
                              onEdit: () => _showBomBreakdownSheet(
                                quotation,
                                index,
                              ),
                              onIncrease: () => _increaseQuantity(index),
                              onDecrease: () => _decreaseQuantity(index),
                              onDelete: () =>
                                  _deleteQuotation(quotation["id"], index),
                            ),
                          );
                        },
                      ),
                    ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Full width continue button
                    if (allQuotations.isNotEmpty) ...[
                      CustomButton(
                        text: "Continue",
                        icon: Icons.arrow_forward,
                        onPressed: () {
                          final quotationQuantitiesMap = <String, int>{};
                          for (int i = 0; i < allQuotations.length; i++) {
                            final quotationId =
                                allQuotations[i]["id"] as String;
                            quotationQuantitiesMap[quotationId] =
                                quantities[i] ?? 1;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FirstQuote(
                                selectedQuotations: allQuotations,
                                quotationQuantities: quotationQuantitiesMap,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    /// Buttons row
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            textSize: 15,
                            text: "Create",
                            outlined: allQuotations.isNotEmpty,
                            icon: Icons.add,
                            onPressed: () {
                              Nav.push(AddMaterial());
                            },
                          ),
                        ),
                        // const SizedBox(width: 12),
                        // Expanded(
                        //   child: CustomButton(
                        //     textSize: 15,
                        //     text: "BOM",
                        //     outlined: true,
                        //     onPressed: () {
                        //       // Nav.push(ImportQuotationsPage());
                        //     },
                        //   ),
                        // ),
                        const SizedBox(width: 12),

                    Expanded(child:  CustomButton(
                      text: "Import BOM",
                      outlined: true,
                      onPressed: _showImportBomsSheet,
                    ),)

                        
                        // Expanded(
                        //   child: CustomButton(
                        //     textSize: 15,
                        //     text: "Import",
                        //     outlined: true,
                        //     onPressed: () {
                        //       // Nav.push(const AllClientQuotations(
                        //       //   isImportMode: true,
                        //       // ));
                        //     },
                        //   ),
                        // ),
                      ],
                    ),
                    //const SizedBox(height: 12),
 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BomImportItem {
  final String id;
  final String bomNumber;
  final String name;
  final String description;
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> materials;
  final List<Map<String, dynamic>> additionalCosts;
  final _BomPricing pricing;
  final int? expectedDurationValue;
  final String? expectedDurationUnit;

  _BomImportItem({
    required this.id,
    required this.bomNumber,
    required this.name,
    required this.description,
    required this.product,
    required this.materials,
    required this.additionalCosts,
    required this.pricing,
    required this.expectedDurationValue,
    required this.expectedDurationUnit,
  });

  factory _BomImportItem.fromJson(Map<String, dynamic> json) {
    final rawProduct = json["product"];
    final rawProductId = json["productId"];
    Map<String, dynamic> product = {};

    if (rawProduct is Map<String, dynamic>) {
      product = Map<String, dynamic>.from(rawProduct);
    } else if (rawProductId is Map<String, dynamic>) {
      product = Map<String, dynamic>.from(rawProductId);
    } else if (json["productData"] is Map<String, dynamic>) {
      product = Map<String, dynamic>.from(json["productData"]);
    }

    final imageValue =
        product["image"] ??
        product["imageUrl"] ??
        json["image"] ??
        json["productImage"] ??
        '';
    final materials = (json["materials"] as List<dynamic>? ?? [])
        .map((item) => _mapMaterial(item as Map<String, dynamic>))
        .toList();
    final additionalCosts = (json["additionalCosts"] as List<dynamic>? ?? [])
        .map((item) => _mapCost(item as Map<String, dynamic>))
        .toList();
    final expectedDuration = json["expectedDuration"] as Map<String, dynamic>?;

    return _BomImportItem(
      id: json["_id"] ?? "",
      bomNumber: json["bomNumber"] ?? "BOM",
      name: json["name"] ?? "",
      description: json["description"] ?? "",
      product: {
        "productId": product["productId"] ?? product["_id"] ?? "",
        "name": product["name"] ?? "",
        "description": product["description"] ?? "",
        "image": imageValue ?? "",
      },
      materials: materials,
      additionalCosts: additionalCosts,
      pricing: _BomPricing.fromJson(json["pricing"] as Map<String, dynamic>?),
      expectedDurationValue: expectedDuration?["value"],
      expectedDurationUnit: expectedDuration?["unit"],
    );
  }

  static Map<String, dynamic> _mapMaterial(Map<String, dynamic> item) {
    return {
      "Product": item["type"] ?? item["name"] ?? "Material",
      "Materialname": item["description"] ?? item["name"] ?? "Imported Item",
      "Width": item["width"]?.toString() ?? "",
      "Length": item["length"]?.toString() ?? "",
      "Thickness": item["thickness"]?.toString() ?? "",
      "Unit": item["unit"] ?? "",
      "Sqm": item["squareMeter"]?.toString() ?? "",
      "Price": item["price"]?.toString() ?? "",
      "quantity": item["quantity"]?.toString() ?? "1",
    };
  }

  static Map<String, dynamic> _mapCost(Map<String, dynamic> item) {
    return {
      "type": item["name"] ?? "",
      "description": item["description"] ?? "",
      "amount": item["amount"]?.toString() ?? "0",
    };
  }
}

class _BomPricing {
  final String pricingMethod;
  final double markupPercentage;
  final double materialsTotal;
  final double additionalTotal;
  final double overheadCost;
  final double costPrice;
  final double sellingPrice;

  _BomPricing({
    required this.pricingMethod,
    required this.markupPercentage,
    required this.materialsTotal,
    required this.additionalTotal,
    required this.overheadCost,
    required this.costPrice,
    required this.sellingPrice,
  });

  factory _BomPricing.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return _BomPricing(
        pricingMethod: "Method 1",
        markupPercentage: 0,
        materialsTotal: 0,
        additionalTotal: 0,
        overheadCost: 0,
        costPrice: 0,
        sellingPrice: 0,
      );
    }
    return _BomPricing(
      pricingMethod: json["pricingMethod"] ?? "Method 1",
      markupPercentage: (json["markupPercentage"] ?? 0).toDouble(),
      materialsTotal: (json["materialsTotal"] ?? 0).toDouble(),
      additionalTotal: (json["additionalTotal"] ?? 0).toDouble(),
      overheadCost: (json["overheadCost"] ?? 0).toDouble(),
      costPrice: (json["costPrice"] ?? 0).toDouble(),
      sellingPrice: (json["sellingPrice"] ?? 0).toDouble(),
    );
  }
}

class _ImportBomCard extends StatelessWidget {
  final _BomImportItem bom;
  final VoidCallback onImport;
  final VoidCallback onEdit;

  const _ImportBomCard({
    required this.bom,
    required this.onImport,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = bom.product["image"]?.toString() ?? "";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey.shade500,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bom.name.isEmpty ? bom.bomNumber : bom.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF302E2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bom.bomNumber,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "₦${bom.pricing.sellingPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA16438),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "Edit",
                  outlined: true,
                  height: 44,
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: "Import",
                  height: 44,
                  onPressed: onImport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImportBomDetailsCard extends StatelessWidget {
  final _BomImportItem bom;
  final VoidCallback onImport;
  final VoidCallback onEdit;

  const _ImportBomDetailsCard({
    required this.bom,
    required this.onImport,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = bom.product["image"]?.toString() ?? "";
    final formatter = NumberFormat.decimalPattern();
    final costLabel = formatter.format(bom.pricing.costPrice.round());
    final sellingLabel = formatter.format(bom.pricing.sellingPrice.round());
    final overheadLabel = formatter.format(bom.pricing.overheadCost.round());
    final materialsCount = bom.materials.length;
    final additionalCount = bom.additionalCosts.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.grey.shade500,
                      size: 40,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bom.name.isEmpty ? bom.bomNumber : bom.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF302E2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bom.bomNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bom.description.isEmpty ? "No description" : bom.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Items • $materialsCount materials",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "Costs • $additionalCount",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Cost Price",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      "₦$costLabel",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Overhead Cost",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      "₦$overheadLabel",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA16438)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Selling Price",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF302E2E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "₦$sellingLabel",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA16438),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "Edit",
                        outlined: true,
                        textColor: ColorsApp.btnColor,
                        borderColor: ColorsApp.btnColor,
                        height: 52,
                        textSize: 18,
                        padding: 8,
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        text: "Import",
                        height: 52,
                        textSize: 18,
                        padding: 8,
                        backgroundColor: ColorsApp.btnColor,
                        textColor: Colors.white,
                        onPressed: onImport,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
