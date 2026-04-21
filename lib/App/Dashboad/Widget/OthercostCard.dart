import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';

class OtherCostsCard extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final List<String>? costTypes;
  final void Function(Map<String, dynamic>)? onAddItem;

  const OtherCostsCard({
    super.key,
    this.title = "Other Costs",
    this.icon,
    this.color,
    this.costTypes,
    this.onAddItem,
  });

  @override
  State<OtherCostsCard> createState() => _OtherCostsCardState();
}

class _OtherCostsCardState extends State<OtherCostsCard> {
  String? selectedType;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  static const Map<String, String> _defaultDescriptions = {
    "Logistics": "Logistics cost for handling and delivery of materials.",
    "Workmanship": "Workmanship cost for labour related to this project.",
    "Transport": "Transport cost for moving materials or personnel.",
    "Miscellaneous": "Miscellaneous project cost related to the selected item.",
  };

  String _fallbackDescriptionFor(String type) {
    return _defaultDescriptions[type] ??
        "$type cost associated with this project.";
  }

  void _handleAddItem() {
    if (selectedType == null || amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Select a cost detail and enter an amount before adding.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final selectedCostType = selectedType!;
    final description = descriptionController.text.trim().isEmpty
        ? _fallbackDescriptionFor(selectedCostType)
        : descriptionController.text.trim();

    final costItem = {
      "type": selectedCostType,
      "description": description,
      "amount": amountController.text.trim(),
    };

    widget.onAddItem?.call(costItem);

    setState(() {
      selectedType = null;
    });
    descriptionController.clear();
    amountController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cost added successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final costTypes =
        widget.costTypes ??
        ["Logistics", "Workmanship", "Transport", "Miscellaneous"];

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
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

          // Type selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: costTypes.map((type) {
                final selected = selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() => selectedType = type),
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
                      type,
                      style: GoogleFonts.openSans(
                        color: selected
                            ? const Color(0xFFA16438)
                            : const Color(0xFFCCA183),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          _buildInput(
            "Description (Optional)",
            controller: descriptionController,
            hintText: selectedType == null
                ? "Add extra details if needed"
                : _fallbackDescriptionFor(selectedType!),
          ),
          const SizedBox(height: 16),
          _buildInput(
            "Amount",
            controller: amountController,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 20),
          CustomButton(text: "Add Item", onPressed: _handleAddItem),
        ],
      ),
    );
  }

  Widget _buildInput(
    String label, {
    TextEditingController? controller,
    String? hintText,
    TextInputType? keyboardType,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.openSans(
          fontSize: 16,
          color: const Color(0xFF7B7B7B),
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(14),
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    ],
  );
}
