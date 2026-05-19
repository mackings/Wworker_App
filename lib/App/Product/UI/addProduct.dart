import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Product/providers/provider.dart';
import 'package:wworker/App/Quotation/Model/ProductModel.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/BomSummary.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';

class AddProduct extends ConsumerStatefulWidget {
  final ProductModel? existingProduct;
  final bool returnToHomeOnSave;

  const AddProduct({
    super.key,
    this.existingProduct,
    this.returnToHomeOnSave = false,
  });

  @override
  ConsumerState<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends ConsumerState<AddProduct> {
  static const Color _pageBg = Color(0xFFFAF7F3);
  static const Color _ink = Color(0xFF211D1A);
  static const Color _muted = Color(0xFF756A61);
  static const Color _brand = Color(0xFF8B4513);
  static const Color _border = Color(0xFFE8DED6);
  static const List<String> _categoryOptions = [
    "Wood",
    "Foam",
    "Plank",
    "Others",
  ];
  static const List<String> _subCategoryOptions = [
    "Wood",
    "Foam",
    "Plank",
    "Others",
  ];

  String? selectedCategory;
  String? selectedSubCategory;
  String? imagePath;
  final nameController = TextEditingController();
  final descController = TextEditingController();

  bool isLoading = false;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProduct;

    if (existing != null) {
      nameController.text = existing.name;
      descController.text = existing.description;
      selectedCategory = existing.category;
      selectedSubCategory = existing.subCategory.isEmpty
          ? null
          : existing.subCategory;
      imagePath = existing.image;
    }

    // ✅ detect if user edits anything
    nameController.addListener(() => _checkForChanges());
    descController.addListener(() => _checkForChanges());
  }

  void _checkForChanges() {
    final existing = widget.existingProduct;
    if (existing == null) {
      _isEdited = true;
      return;
    }

    final edited =
        nameController.text != existing.name ||
        descController.text != existing.description ||
        selectedCategory != existing.category ||
        selectedSubCategory != existing.subCategory ||
        imagePath != existing.image;

    if (edited != _isEdited) {
      setState(() => _isEdited = edited);
    }
  }

  Future<void> _uploadProduct() async {
    final existing = widget.existingProduct;

    // ✅ If using existing product without edits, just proceed
    if (existing != null && !_isEdited) {
      _handleAfterSave(existing);
      return;
    }

    // ✅ Otherwise, create new product
    if (imagePath == null ||
        nameController.text.isEmpty ||
        descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select an image"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ref
          .read(productServiceProvider)
          .createProduct(
            name: nameController.text,
            subCategory: selectedSubCategory ?? "",
            description: descController.text,
            category: selectedCategory ?? "",
            imagePath: imagePath!,
          );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response["success"] == true) {
        final productData = response["data"];
        _handleAfterSave(productData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response["message"] ?? "Upload failed"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  // ✅ Store product data in provider and navigate to BOM Summary
  Future<void> _handleAfterSave(dynamic productData) async {
    if (widget.returnToHomeOnSave) {
      if (context.mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final quotationNotifier = ref.read(quotationSummaryProvider.notifier);

    // ✅ Store product data in provider (but don't create quotation yet)
    final productInfo = (productData is ProductModel)
        ? {
            "productId": productData.productId,
            "name": productData.name,
            "category": productData.category,
            "description": productData.description,
            "image": productData.image,
          }
        : productData;

    // ✅ Just set the product data without creating a quotation
    quotationNotifier.setProduct(productInfo);

    debugPrint("✅ Product data stored: ${productInfo["name"]}");

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BOMSummary()),
      );

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text("✅ Product selected! Add materials to continue."),
      //     backgroundColor: Colors.green,
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existingProduct;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        centerTitle: true,
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
        title: Text(
          existing != null ? "Edit Product" : "Add Product",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCard(existing),
                  const SizedBox(height: 16),
                  _buildTextInput(
                    label: "Product name",
                    hintText: "Enter product name",
                    controller: nameController,
                    icon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildTextInput(
                    label: "Product description",
                    hintText: "Enter product description",
                    controller: descController,
                    icon: Icons.text_fields_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildDropdownInput(
                    label: "Product type",
                    hintText: "Select a product type",
                    items: _categoryOptions,
                    value: selectedCategory,
                    onChanged: (value) {
                      setState(() => selectedCategory = value);
                      _checkForChanges();
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildDropdownInput(
                    label: "Sub category",
                    hintText: "Select a subcategory",
                    items: _subCategoryOptions,
                    value: selectedSubCategory,
                    onChanged: (value) {
                      setState(() => selectedSubCategory = value);
                      _checkForChanges();
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildActionButton(
                    text: existing != null && !_isEdited
                        ? "Use This Product"
                        : "Upload Product",
                    onPressed: _uploadProduct,
                  ),
                  const SizedBox(height: 10),
                  _buildActionButton(
                    text: "Cancel",
                    outlined: true,
                    onPressed: () {
                      Nav.pop();
                    },
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.brown),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageCard(ProductModel? existing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomImgBg(
        height: 170,
        borderRadius: 16,
        initialImageUrl: existing?.image,
        selectedImagePath: imagePath,
        overlayPadding: const EdgeInsets.symmetric(
          horizontal: 40,
          vertical: 42,
        ),
        iconSize: 42,
        textSize: 13,
        onImageSelected: (image) {
          setState(() {
            imagePath = image?.path;
          });
          _checkForChanges();
        },
      ),
    );
  }

  Widget _buildTextInput({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: _ink,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _fieldDecoration(hintText: hintText, suffixIcon: icon),
        ),
      ],
    );
  }

  Widget _buildDropdownInput({
    required String label,
    required String hintText,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final normalizedValue = items.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: normalizedValue,
          isExpanded: true,
          decoration: _fieldDecoration(hintText: hintText),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _muted,
            size: 22,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, color: _muted, size: 20),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brand, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: _brand,
                side: const BorderSide(color: _brand, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              child: Text(text),
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB7835E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              child: Text(text),
            ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }
}
