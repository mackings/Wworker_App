import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Dashboad/Widget/emptyQuote.dart';
import 'package:wworker/App/Quotation/UI/AddMaterial.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';

class AllQuotations extends ConsumerStatefulWidget {
  const AllQuotations({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AllQuotationsState();
}

class _AllQuotationsState extends ConsumerState<AllQuotations> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
            child: Column(
              children: [
                CustomEmptyQuotes(
                  title: "Quotation",
                  buttonText: "",
                  emptyMessage: "No Items Added Yet",
                ),

                SizedBox(height: 230),

                CustomButton(
                  text: "Create new BOM",
                  icon: Icons.add,
                  onPressed: () {
                    Nav.push(AddMaterial());
                  },
                ),
                SizedBox(height: 20),
                CustomButton(
                  text: "Add item from BOM List",
                  outlined: true,
                  icon: Icons.add,
                  onPressed: () {},
                ),

                SizedBox(height: 20),
                CustomButton(
                  text: "Add item from Quotation",
                  outlined: true,
                  icon: Icons.add,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
