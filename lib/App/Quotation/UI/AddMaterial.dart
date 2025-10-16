import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Dashboad/Widget/MaterialCard.dart';
import 'package:wworker/App/Dashboad/Widget/OthercostCard.dart';
import 'package:wworker/App/Dashboad/Widget/itemCard.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';



class AddMaterial extends ConsumerStatefulWidget {
  const AddMaterial({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddMaterialState();
}

class _AddMaterialState extends ConsumerState<AddMaterial> {
  String? userId;
  bool isLoading = true;

  // 👇 Separate expand states for Material and Additional Cost
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
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialProvider);
    final notifier = ref.read(materialProvider.notifier);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------ ADD MATERIAL CARD ------------------
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 19, vertical: 19),
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
                    onAddItem: notifier.addItem,
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),

                const SizedBox(height: 25),

                // ------------------ ADDITIONAL COST CARD ------------------
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 19, vertical: 19),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => isAdditionalExpanded = !isAdditionalExpanded),
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
                    onAddItem: (item) => notifier.addItem(item),
                  ),
                  crossFadeState: isAdditionalExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),

                const SizedBox(height: 25),

               
                Text(
                  "Items (${materials.length})",
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
                    onDelete: () => notifier.deleteItem(index),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



