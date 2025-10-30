import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Dashboad/Widget/emptyQuote.dart';
import 'package:wworker/App/Dashboad/Widget/itemCard.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/UI/AddMaterial.dart';
import 'package:wworker/App/Quotation/UI/AllclientQuotations.dart';
import 'package:wworker/App/Quotation/UI/BomList.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';





class AllQuotations extends ConsumerStatefulWidget {
  const AllQuotations({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AllQuotationsState();
}

class _AllQuotationsState extends ConsumerState<AllQuotations> {


  @override
  Widget build(BuildContext context) {
    final materialData = ref.watch(materialProvider);
    final materials = List<Map<String, dynamic>>.from(materialData["materials"] ?? []);
    final additionalCosts = List<Map<String, dynamic>>.from(materialData["additionalCosts"] ?? []);

    final hasItems = materials.isNotEmpty || additionalCosts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: CustomText(title: "Quotations",)),
      body: SafeArea(
        child: Column(
          children: [
           


            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasItems)
                      const CustomEmptyQuotes(
                        title: "Quotation",
                        buttonText: "",
                        emptyMessage: "No Items Added Yet",
                      )
                    else ...[
                
                      if (materials.isNotEmpty) ...[
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
                            onDelete: () {
                              ref.read(materialProvider.notifier).deleteMaterial(index);
                            },
                          );
                        }),
                        const SizedBox(height: 25),
                      ],

        
                      if (additionalCosts.isNotEmpty) ...[
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
                            onDelete: () {
                              ref.read(materialProvider.notifier).deleteAdditionalCost(index);
                            },
                          );
                        }),
                        const SizedBox(height: 25),
                      ],
                    ],
                  ],
                ),
              ),
            ),



            Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              color: Colors.white,
              child: Column(
                children: [


CustomButton(
  text: hasItems ? "Continue" : "Create New BOM",
  icon: Icons.add,
  onPressed: () {
    Nav.push(AddMaterial());
  },
),


                  const SizedBox(height: 12),

                  CustomButton(
                    text: "Add item from BOM List",
                    outlined: true,
                    icon: Icons.add,
                    onPressed: () {
                      Nav.push(BOMList());
                    },
                  ),

                  const SizedBox(height: 12),

                  CustomButton(
                    text: "Add item from Quotation",
                    outlined: true,
                    icon: Icons.add,
                    onPressed: () {
                      Nav.push(AllClientQuotations());
                    },
                  ),



                ],
              ),
            ),


          ],
        ),
      ),
    );
  }
}
