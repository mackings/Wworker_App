import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Product/Api/ProService.dart';
import 'package:wworker/App/Product/Model/ProModel.dart';
import 'package:wworker/App/Product/UI/addProduct.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';



class AddMaterialCard extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final void Function(Map<String, dynamic>)? onAddItem;

  const AddMaterialCard({
    super.key,
    this.title = "Add Materials",
    this.icon,
    this.color,
    this.onAddItem,
  });

  @override
  State<AddMaterialCard> createState() => _AddMaterialCardState();
}

class _AddMaterialCardState extends State<AddMaterialCard> {
  String? selectedProduct;
  final List<String> units = ["cm", "m", "mm"];
  final List<String> numbers = List.generate(100, (i) => "${i + 1}");

  String? width, length, thickness, unit;

  final TextEditingController materialNameController = TextEditingController();
  final TextEditingController sqmController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  final ProductService _productService = ProductService();
  List<ProductModel> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final fetched = await _productService.getProducts();
      setState(() {
        products = fetched;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("⚠️ Failed to fetch products: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    materialNameController.dispose();
    sqmController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void _handleAddItem() {
    if (selectedProduct == null ||
        materialNameController.text.trim().isEmpty ||
        width == null ||
        length == null ||
        thickness == null ||
        unit == null ||
        sqmController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields before adding."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final item = {
      "Product": selectedProduct,
      "Materialname": materialNameController.text.trim(),
      "Width": width,
      "Length": length,
      "Thickness": thickness,
      "Unit": unit,
      "Sqm": sqmController.text.trim(),
      "Price": priceController.text.trim(),
    };

    widget.onAddItem?.call(item);

    setState(() {
      selectedProduct = null;
      width = null;
      length = null;
      thickness = null;
      unit = null;
    });
    materialNameController.clear();
    sqmController.clear();
    priceController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Material added successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (widget.icon != null)
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
              TextButton(
                onPressed: () {
                  Nav.push(const AddProduct());
                },
                child: const Text("Add Product"),
              ),
            ],
          ),

          const SizedBox(height: 16),

// 🟢 Product list (no loading indicator shown)
if (products.isEmpty)
  const Text(
    "No products found.",
    style: TextStyle(color: Colors.grey),
  )
else
  SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: products.map((p) {
        final selected = selectedProduct == p.name;
        return GestureDetector(
          onTap: () => setState(() => selectedProduct = p.name),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              p.name,
              style: GoogleFonts.openSans(
                color: selected
                    ? const Color(0xFFA16438)
                    : const Color(0xFFCCA183),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  ),


          const SizedBox(height: 16),
          _buildInput("Material Name", controller: materialNameController),
          const SizedBox(height: 16),

          // Width + Length
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDropdown(
                "Width",
                numbers,
                width,
                (v) => setState(() => width = v),
              ),
              _buildDropdown(
                "Length",
                numbers,
                length,
                (v) => setState(() => length = v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Thickness + Unit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDropdown(
                "Thickness",
                numbers,
                thickness,
                (v) => setState(() => thickness = v),
              ),
              _buildDropdown(
                "Unit",
                units,
                unit,
                (v) => setState(() => unit = v),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildInput("Square Meter", controller: sqmController),
          const SizedBox(height: 16),
          _buildInput("Price", controller: priceController),

          const SizedBox(height: 20),
          CustomButton(text: "Add Item", onPressed: _handleAddItem),
        ],
      ),
    );
  }

  Widget _buildInput(String label, {TextEditingController? controller}) =>
      Column(
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

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 95) / 2,
      child: Column(
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
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
            items: items
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

