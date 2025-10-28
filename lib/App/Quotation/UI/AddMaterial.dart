import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Dashboad/Widget/MaterialCard.dart';
import 'package:wworker/App/Dashboad/Widget/OthercostCard.dart';
import 'package:wworker/App/Dashboad/Widget/itemCard.dart';
import 'package:wworker/App/Product/UI/addProduct.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/BomSummary.dart';
import 'package:wworker/App/Quotation/UI/QuoteSummary.dart';
import 'package:wworker/App/Quotation/UI/existingProduct.dart';
import 'package:wworker/App/Quotation/Widget/Optionmodal.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';





class AddMaterial extends ConsumerStatefulWidget {
  const AddMaterial({super.key});

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
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --- MATERIAL SECTION ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 19,
                  vertical: 19,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () => setState(() => isExpanded = !isExpanded),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.remove : Icons.add,
                        color: Colors.brown,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Add Material",
                        style: GoogleFonts.openSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF302E2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                firstChild: const SizedBox.shrink(),
                secondChild: AddMaterialCard(
                  title: "Add Material",
                  icon: Icons.add,
                  onAddItem: (item) async {
                    await notifier.addMaterial(item);
                  },
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),

              const SizedBox(height: 25),

              /// --- ADDITIONAL COST SECTION ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 19,
                  vertical: 19,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () => setState(
                    () => isAdditionalExpanded = !isAdditionalExpanded,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAdditionalExpanded ? Icons.remove : Icons.add,
                        color: Colors.brown,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Additional Cost",
                        style: GoogleFonts.openSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF302E2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                firstChild: const SizedBox.shrink(),
                secondChild: OtherCostsCard(
                  title: "Additional Cost",
                  icon: Icons.attach_money,
                  onAddItem: (item) async {
                    await notifier.addAdditionalCost(item);
                  },
                ),
                crossFadeState: isAdditionalExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),

              const SizedBox(height: 25),

              /// --- MATERIAL LIST ---
              Text(
                "Materials (${materials.length})",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...materials.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return ItemsCard(
                  item: item,
                  onDelete: () => notifier.deleteMaterial(index),
                );
              }),

              const SizedBox(height: 25),

              /// --- ADDITIONAL COST LIST ---
              Text(
                "Additional Costs (${additionalCosts.length})",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...additionalCosts.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return ItemsCard(
                  item: item,
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
      MaterialPageRoute(builder: (_) => const SelectExistingProductScreen()),
    );

    if (selectedProduct != null) {
      final productData = selectedProduct.toJson();

      final quotationNotifier = ref.read(quotationSummaryProvider.notifier);
      final materialNotifier = ref.read(materialProvider.notifier);

      final materials = List<Map<String, dynamic>>.from(
        materialNotifier.state["materials"] ?? [],
      );
      final additionalCosts = List<Map<String, dynamic>>.from(
        materialNotifier.state["additionalCosts"] ?? [],
      );

      final updatedMaterials = materials.map((m) => {
            ...m,
            "Product": productData["name"],
          }).toList();

      final newQuotation = {
        "product": productData,
        "materials": updatedMaterials,
        "additionalCosts": additionalCosts,
      };

      await quotationNotifier.addNewQuotation(newQuotation);

      if (mounted) {
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuotationSummary()),
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


              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
