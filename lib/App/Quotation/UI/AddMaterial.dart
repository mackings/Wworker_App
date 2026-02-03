import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Dashboad/Widget/MaterialCard.dart';
import 'package:wworker/App/Dashboad/Widget/OthercostCard.dart';
import 'package:wworker/App/Dashboad/Widget/itemCard.dart';
import 'package:wworker/App/Product/UI/addProduct.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/AllclientQuotations.dart';
import 'package:wworker/App/Quotation/UI/BomList.dart';
import 'package:wworker/App/Quotation/UI/BomSummary.dart';
import 'package:wworker/App/Quotation/UI/QuoteSummary.dart';
import 'package:wworker/App/Quotation/UI/existingProduct.dart';
import 'package:wworker/App/Quotation/Widget/Optionmodal.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';



class AddMaterial extends ConsumerStatefulWidget {
  final bool autoPopAfterAdd;

  const AddMaterial({super.key, this.autoPopAfterAdd = false});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddMaterialState();
}

class _AddMaterialState extends ConsumerState<AddMaterial> {
  String? userId;
  bool isUserLoading = true;
  bool isExpanded = false;
  bool isAdditionalExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("userId");
    setState(() {
      userId = savedUserId;
      isUserLoading = false;
    });
  }

  Map<String, dynamic> _buildDisplayItem(Map<String, dynamic> item) {
    final displayItem = Map<String, dynamic>.from(item);
    displayItem.remove("disableIncrement");
    final price =
        double.tryParse((item["Price"] ?? "0").toString()) ?? 0.0;
    final quantity =
        int.tryParse((item["quantity"] ?? "1").toString()) ?? 1;
    // Always respect material quantity on the materials page.
    final total = price * quantity;
    final totalRounded = total.round();
    displayItem["Total"] =
        NumberFormat.decimalPattern().format(totalRounded);
    return displayItem;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(materialProvider);
    final notifier = ref.read(materialProvider.notifier);

    // ✅ Wait for both user + provider data to load
    final isProviderLoaded = data["isLoaded"] == true;

    if (isUserLoading || !isProviderLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "User not logged in",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // ✅ Extract lists safely
    final materials = List<Map<String, dynamic>>.from(data["materials"] ?? []);
    final additionalCosts = List<Map<String, dynamic>>.from(
      data["additionalCosts"] ?? [],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text("Materials"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [
          GuideHelpIcon(
            title: "Add Materials",
            message:
                "Step 1: add materials with sizes and units. "
                "Step 2: add extra costs if needed. "
                "Step 3: review the list below and continue to create a BOM. "
                "The goal is to capture every cost item used in a quotation.",
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --- MATERIAL SECTION ---
              _buildSectionCard(
                title: "Add Material",
                icon: Icons.layers_outlined,
                isExpanded: isExpanded,
                onChanged: (value) => setState(() => isExpanded = value),
                child: AddMaterialCard(
                  title: "Material Details",
                  icon: Icons.add_circle_outline,
                  showHeader: false,
                  onAddItem: (item) async {
                    await notifier.addMaterial(item);
                    if (widget.autoPopAfterAdd && mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),

              const SizedBox(height: 25),

              /// --- ADDITIONAL COST SECTION ---
              _buildSectionCard(
                title: "Additional Cost",
                icon: Icons.attach_money_outlined,
                isExpanded: isAdditionalExpanded,
                onChanged: (value) =>
                    setState(() => isAdditionalExpanded = value),
                child: OtherCostsCard(
                  title: "Cost Details",
                  icon: Icons.add_circle_outline,
                  onAddItem: (item) async {
                    await notifier.addAdditionalCost(item);
                  },
                ),
              ),

              const SizedBox(height: 25),

              /// --- MATERIAL LIST ---
              _buildSectionHeader("Materials", materials.length),
              const SizedBox(height: 12),
              ...materials.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isDisabled = item["disableIncrement"] == true;
                final displayItem = _buildDisplayItem(item);
                return ItemsCard(
                  item: displayItem,
                  showQuantityControls: true,
                  quantity:
                      int.tryParse((item["quantity"] ?? "1").toString()) ?? 1,
                  onIncreaseQuantity: () {
                    final currentQty =
                        int.tryParse((item["quantity"] ?? "1").toString()) ??
                        1;
                    final updated = {
                      ...item,
                      "quantity": (currentQty + 1).toString(),
                    };
                    notifier.updateMaterial(index, updated);
                  },
                  onDecreaseQuantity: () {
                    final currentQty =
                        int.tryParse((item["quantity"] ?? "1").toString()) ??
                        1;
                    if (currentQty <= 1) return;
                    final updated = {
                      ...item,
                      "quantity": (currentQty - 1).toString(),
                    };
                    notifier.updateMaterial(index, updated);
                  },
                  showPriceIncrementToggle: true,
                  useBomStyle: true,
                  isPriceIncrementDisabled: isDisabled,
                  onPriceIncrementToggle: (value) {
                    final updated = {...item, "disableIncrement": value};
                    notifier.updateMaterial(index, updated);
                  },
                  onDelete: () {
                    notifier.deleteMaterial(index);
                  },
                );
              }),

              const SizedBox(height: 25),

              /// --- ADDITIONAL COST LIST ---
              _buildSectionHeader("Additional Costs", additionalCosts.length),
              const SizedBox(height: 12),
              ...additionalCosts.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return ItemsCard(
                  item: item,
                  showPriceIncrementToggle: true,
                  isPriceIncrementDisabled: item["disableIncrement"] == true,
                  onPriceIncrementToggle: (value) {
                    final updated = {...item, "disableIncrement": value};
                    notifier.updateAdditionalCost(index, updated);
                  },
                  onDelete: () => notifier.deleteAdditionalCost(index),
                );
              }),

              SizedBox(height: 20),

              CustomButton(
                text: (materials.isEmpty && additionalCosts.isEmpty)
                    ? "Create New BOM"
                    : "Continue",
                outlined: (materials.isEmpty && additionalCosts.isEmpty),
                onPressed: () {
                  if (materials.isEmpty && additionalCosts.isEmpty) {
                    setState(() {
                      isExpanded = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Add at least one material or additional cost to continue",
                        ),
                      ),
                    );
                  } else {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => SelectOptionSheet(
                        title: "Select Product",
                        options: [
                          OptionItem(
                            label: "Create New Product",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddProduct(),
                                ),
                              );
                            },
                          ),
                          OptionItem(
                            label: "Select Existing Products",
                            onTap: () async {
                              Navigator.pop(context);
                              final selectedProduct = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SelectExistingProductScreen(),
                                ),
                              );

                              if (selectedProduct != null) {
                                final productData = selectedProduct.toJson();

                                final quotationNotifier = ref.read(
                                  quotationSummaryProvider.notifier,
                                );
                                final materialNotifier = ref.read(
                                  materialProvider.notifier,
                                );

                                final materials =
                                    List<Map<String, dynamic>>.from(
                                      materialNotifier.state["materials"] ?? [],
                                    );
                                final additionalCosts =
                                    List<Map<String, dynamic>>.from(
                                      materialNotifier
                                              .state["additionalCosts"] ??
                                          [],
                                    );

                                final updatedMaterials = materials
                                    .map(
                                      (m) => {
                                        ...m,
                                        "Product": productData["name"],
                                      },
                                    )
                                    .toList();

                                final newQuotation = {
                                  "product": productData,
                                  "materials": updatedMaterials,
                                  "additionalCosts": additionalCosts,
                                };

                                await quotationNotifier.addNewQuotation(
                                  newQuotation,
                                );

                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const QuotationSummary(),
                                    ),
                                  );

                                  //  Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(builder: (context) => const BOMSummary()),
                                  //   );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 12),

              // CustomButton(
              //   text: "Add item from BOM List",
              //   outlined: true,
              //   icon: Icons.add,
              //   onPressed: () {
              //     Nav.push(BOMList());
              //   },
              // ),
              // const SizedBox(height: 12),
              CustomButton(
                text: "Add item from Quotation",
                outlined: true,
                icon: Icons.add,
                onPressed: () {
                  Nav.push(AllClientQuotations());
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF302E2E),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Text(
            "$count",
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8B4513),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required ValueChanged<bool> onChanged,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: onChanged,
          leading: Icon(icon, color: const Color(0xFF8B4513)),
          title: Text(
            title,
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF302E2E),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
