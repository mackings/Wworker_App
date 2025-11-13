import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Dashboad/Widget/emptyQuote.dart';
import 'package:wworker/App/Dashboad/Widget/itemCard.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/UI/AddMaterial.dart';
import 'package:wworker/App/Quotation/UI/BomSummary.dart';
import 'package:wworker/App/Quotation/Widget/AddListedBom.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';

class BOMList extends ConsumerStatefulWidget {
  const BOMList({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BOMListState();
}

class _BOMListState extends ConsumerState<BOMList> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(materialProvider);
    final notifier = ref.read(materialProvider.notifier);

    final materials = List<Map<String, dynamic>>.from(data["materials"] ?? []);
    final additionalCosts = List<Map<String, dynamic>>.from(
      data["additionalCosts"] ?? [],
    );

    if (data["isLoaded"] != true) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: (materials.isEmpty && additionalCosts.isEmpty)
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: CustomEmptyQuotes(
                  title: "Bill of Materials",
                  buttonText: "Add Material",
                  emptyMessage:
                      "No materials or additional costs have been added yet.",
                  onButtonTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddMaterial()),
                    );
                  },
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// --- MATERIALS SECTION ---
                    if (materials.isNotEmpty) ...[
                      Text(
                        "Items (${materials.length})",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...materials.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        return ItemsCard(
                          item: item,
                          onDelete: () async {
                            await notifier.deleteMaterial(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Material deleted successfully"),
                              ),
                            );
                          },
                        );
                      }),
                    ],

                    const SizedBox(height: 25),

                    if (additionalCosts.isNotEmpty) ...[
                      Text(
                        "Other Costs (${additionalCosts.length})",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...additionalCosts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final cost = entry.value;

                        return ItemsCard(
                          item: cost,
                          onDelete: () async {
                            await notifier.deleteAdditionalCost(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Additional cost deleted successfully",
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ],
                ),
              ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: "Add from BOM List",
              outlined: true,
              onPressed: () async {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (context) => const AddFromBOMSheet(),
                );
              },
            ),

            const SizedBox(height: 10),
            CustomButton(
              text: "Continue",
              onPressed: () {
                Nav.push(AddMaterial());
                // Nav.push(BOMSummary());
              },
            ),
          ],
        ),
      ),
    );
  }
}
