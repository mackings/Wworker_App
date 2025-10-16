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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _handleAddItem() {
    if (selectedType == null ||
        nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields before adding."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final costItem = {
      "type": selectedType,
      "name": nameController.text.trim(),
      "description": descriptionController.text.trim(),
      "amount": amountController.text.trim(),
    };

    widget.onAddItem?.call(costItem);

    setState(() {
      selectedType = null;
    });
    nameController.clear();
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
    final costTypes = widget.costTypes ??
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
                  
                  Text(widget.title,
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF302E2E),
                      )),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

          _buildInput("Name", controller: nameController),
          const SizedBox(height: 16),
          _buildInput("Description", controller: descriptionController),
          const SizedBox(height: 16),
          _buildInput("Amount", controller: amountController),

          const SizedBox(height: 20),
          CustomButton(text: "Add Item", onPressed: _handleAddItem),
        ],
      ),
    );
  }

  Widget _buildInput(String label, {TextEditingController? controller}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.openSans(
                  fontSize: 16, color: const Color(0xFF7B7B7B))),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
        ],
      );
}
