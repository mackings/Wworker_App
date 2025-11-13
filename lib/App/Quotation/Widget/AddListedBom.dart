import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Dashboad/Widget/itemCard.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Model/BOmModel.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';

class AddFromBOMSheet extends ConsumerStatefulWidget {
  const AddFromBOMSheet({super.key});

  @override
  ConsumerState<AddFromBOMSheet> createState() => _AddFromBOMSheetState();
}

class _AddFromBOMSheetState extends ConsumerState<AddFromBOMSheet> {
  final BOMService _service = BOMService();
  bool isLoading = true;
  List<BOMModel> bomList = [];

  @override
  void initState() {
    super.initState();
    _loadBOMs();
  }

  Future<void> _loadBOMs() async {
    final response = await _service.getAllBOMs();
    if (response["success"] == true) {
      final List data = response["data"];
      setState(() {
        bomList = data.map((e) => BOMModel.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Failed to load BOMs")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Flatten all materials + additionalCosts across all BOMs
    final allItems = bomList
        .expand(
          (bom) => [
            ...bom.materials.map((m) => m.toJson()),
            // ...bom.additionalCosts.map((c) => c.toJson()),
          ],
        )
        .toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : allItems.isEmpty
              ? const Center(
                  child: Text(
                    "No materials or additional costs found.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: allItems.length,
                  itemBuilder: (context, index) {
                    final item = allItems[index];

                    // ✅ Extract only relevant fields
                    final materialData = {
                      "Materialname":
                          item["type"] ?? item["Materialname"] ?? "",
                      "Product": item["woodType"] ?? item["Product"] ?? "",
                      "WoodType": item["woodType"] ?? "",
                      "Width": item["width"]?.toString() ?? "",
                      "Length": item["length"]?.toString() ?? "",
                      "Thickness": item["thickness"]?.toString() ?? "",
                      "Unit": item["unit"] ?? "cm",
                      "Sqm": item["squareMeter"]?.toString() ?? "",
                      "Price": item["price"]?.toString() ?? "",
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ItemsCard(
                        item: materialData,
                        showAddButton: true,
                        onAdd: () async {
                          final notifier = ref.read(materialProvider.notifier);
                          await notifier.addMaterial(materialData);
                          Nav.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Item added successfully!"),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
