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
import 'package:wworker/App/Quotation/UI/QuoteSummary.dart';
import 'package:wworker/App/Quotation/UI/existingProduct.dart';
import 'package:wworker/App/Quotation/Widget/Optionmodal.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';

class AddMaterial extends ConsumerStatefulWidget {
  final bool autoPopAfterAdd;

  const AddMaterial({super.key, this.autoPopAfterAdd = false});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddMaterialState();
}

class _AddMaterialState extends ConsumerState<AddMaterial> {
  static const Color _pageBg = Color(0xFFFAF7F3);
  static const Color _ink = Color(0xFF211D1A);
  static const Color _muted = Color(0xFF756A61);
  static const Color _brand = Color(0xFF8B4513);
  static const Color _border = Color(0xFFE8DED6);

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
    final calculation = item["calculation"];
    final calculatedTotal = calculation is Map
        ? double.tryParse((calculation["totalMaterialCost"] ?? "").toString())
        : null;
    final lineTotal = double.tryParse(
      (item["LineTotal"] ?? item["subtotal"] ?? "").toString(),
    );
    final price = double.tryParse((item["Price"] ?? "0").toString()) ?? 0.0;
    final quantity = int.tryParse((item["quantity"] ?? "1").toString()) ?? 1;
    // Always respect material quantity on the materials page.
    final total = calculatedTotal ?? lineTotal ?? price * quantity;
    final totalRounded = total.round();
    displayItem["Total"] = NumberFormat.decimalPattern().format(totalRounded);
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
      backgroundColor: _pageBg,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Build BOM",
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: _pageBg,
        surfaceTintColor: _pageBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _ink,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: GuideHelpIcon(
              title: "Add Materials",
              message:
                  "Step 1: add materials with sizes and units. "
                  "Step 2: add extra costs if needed. "
                  "Step 3: review the list below and continue to create a BOM. "
                  "The goal is to capture every cost item used in a quotation.",
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBomHero(materials.length, additionalCosts.length),
              const SizedBox(height: 12),

              /// --- MATERIAL SECTION ---
              _buildSectionCard(
                title: "Add Material",
                subtitle: "Choose materials, quantities, sizes, and pricing.",
                icon: Icons.layers_outlined,
                isExpanded: isExpanded,
                onChanged: (value) => setState(() => isExpanded = value),
                child: AddMaterialCard(
                  title: "Material Details",
                  icon: Icons.add_circle_outline,
                  showHeader: false,
                  onAddItem: (item) async {
                    await notifier.addMaterial(item);
                    if (widget.autoPopAfterAdd) {
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),

              const SizedBox(height: 10),

              /// --- ADDITIONAL COST SECTION ---
              _buildSectionCard(
                title: "Additional Cost",
                subtitle:
                    "Add labour, transport, installation, or other costs.",
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

              const SizedBox(height: 16),

              /// --- MATERIAL LIST ---
              _buildSectionHeader("Materials", materials.length),
              const SizedBox(height: 10),
              Column(
                children: [
                  if (materials.isEmpty)
                    _buildEmptyListCard(
                      icon: Icons.layers_outlined,
                      title: "No materials added",
                      message: "Open Add Material to start building this BOM.",
                    )
                  else
                    ...materials.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isDisabled = item["disableIncrement"] == true;
                      final displayItem = _buildDisplayItem(item);
                      return ItemsCard(
                        item: displayItem,
                        showQuantityControls: true,
                        quantity:
                            int.tryParse(
                              (item["quantity"] ?? "1").toString(),
                            ) ??
                            1,
                        onIncreaseQuantity: () {
                          final currentQty =
                              int.tryParse(
                                (item["quantity"] ?? "1").toString(),
                              ) ??
                              1;
                          final updated = {
                            ...item,
                            "quantity": (currentQty + 1).toString(),
                          };
                          notifier.updateMaterial(index, updated);
                        },
                        onDecreaseQuantity: () {
                          final currentQty =
                              int.tryParse(
                                (item["quantity"] ?? "1").toString(),
                              ) ??
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
                ],
              ),

              const SizedBox(height: 16),

              /// --- ADDITIONAL COST LIST ---
              _buildSectionHeader("Additional Costs", additionalCosts.length),
              const SizedBox(height: 10),
              Column(
                children: [
                  if (additionalCosts.isEmpty)
                    _buildEmptyListCard(
                      icon: Icons.payments_outlined,
                      title: "No extra costs",
                      message:
                          "Add this only when the BOM needs extra charges.",
                    )
                  else
                    ...additionalCosts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return ItemsCard(
                        item: item,
                        useBomStyle: true,
                        showPriceIncrementToggle: true,
                        isPriceIncrementDisabled:
                            item["disableIncrement"] == true,
                        onPriceIncrementToggle: (value) {
                          final updated = {...item, "disableIncrement": value};
                          notifier.updateAdditionalCost(index, updated);
                        },
                        onDelete: () => notifier.deleteAdditionalCost(index),
                      );
                    }),
                ],
              ),

              const SizedBox(height: 16),

              _buildActionPanel(
                hasItems: materials.isNotEmpty || additionalCosts.isNotEmpty,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _handleContinue({required bool hasItems}) {
    if (!hasItems) {
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
      return;
    }

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
                MaterialPageRoute(builder: (context) => const AddProduct()),
              );
            },
          ),
          OptionItem(
            label: "Select Existing Products",
            onTap: () async {
              final rootNavigator = Navigator.of(this.context);
              Navigator.pop(context);
              final selectedProduct = await rootNavigator.push(
                MaterialPageRoute(
                  builder: (_) => const SelectExistingProductScreen(),
                ),
              );

              if (selectedProduct != null) {
                final productData = selectedProduct.toJson();

                final quotationNotifier = ref.read(
                  quotationSummaryProvider.notifier,
                );
                final materialData = ref.read(materialProvider);

                final materials = List<Map<String, dynamic>>.from(
                  materialData["materials"] ?? [],
                );
                final additionalCosts = List<Map<String, dynamic>>.from(
                  materialData["additionalCosts"] ?? [],
                );

                final updatedMaterials = materials
                    .map((m) => {...m, "Product": productData["name"]})
                    .toList();

                final newQuotation = {
                  "product": productData,
                  "materials": updatedMaterials,
                  "additionalCosts": additionalCosts,
                };

                await quotationNotifier.addNewQuotation(newQuotation);

                if (mounted) {
                  rootNavigator.push(
                    MaterialPageRoute(
                      builder: (context) => const QuotationSummary(),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBomHero(int materialCount, int additionalCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: _brand,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Build your material list",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Add materials and extra costs, then attach the BOM to a new or existing product.",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryPill(
                  label: "Materials",
                  count: materialCount,
                  icon: Icons.layers_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryPill(
                  label: "Extra costs",
                  count: additionalCount,
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill({
    required String label,
    required int count,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _brand, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            "$count",
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
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
    required String subtitle,
    required IconData icon,
    required bool isExpanded,
    required ValueChanged<bool> onChanged,
    required Widget child,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          key: ValueKey("$title-$isExpanded"),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onChanged,
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: _ink,
          collapsedIconColor: _ink,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _brand, size: 20),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.openSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildEmptyListCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _brand, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    height: 1.3,
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

  Widget _buildActionPanel({required bool hasItems}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPrimaryAction(
            text: hasItems ? "Continue" : "Create New BOM",
            outlined: !hasItems,
            onPressed: () => _handleContinue(hasItems: hasItems),
          ),
          const SizedBox(height: 8),
          _buildSecondaryAction(
            text: "Add item from Quotation",
            icon: Icons.add_rounded,
            onPressed: () {
              Nav.push(AllClientQuotations());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction({
    required String text,
    required bool outlined,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: outlined ? Colors.white : _brand,
          foregroundColor: _brand,
          side: const BorderSide(color: _brand, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: outlined ? _brand : Colors.white),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: _brand,
          side: const BorderSide(color: _border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
