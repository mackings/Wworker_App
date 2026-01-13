import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Product/providers/provider.dart';
import 'package:wworker/App/Quotation/Model/ProductModel.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/BomSummary.dart';
import 'package:wworker/App/Quotation/UI/QuoteSummary.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';



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
      appBar: AppBar(
        title: CustomText(
          title: existing != null ? "Edit Existing Product" : "Add New Product",
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomImgBg(
                    initialImageUrl: existing?.image,
                    onImageSelected: (image) {
                      setState(() {
                        imagePath = image?.path;
                      });
                      _checkForChanges();
                    },
                  ),

                  const SizedBox(height: 20),
                  CustomTextField(
                    label: "Product name",
                    hintText: "Enter product name",
                    controller: nameController,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: "Product description",
                    hintText: "Enter product description",
                    controller: descController,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: "Category",
                    hintText: "Select a category",
                    isDropdown: true,
                    dropdownItems: ["Wood", "Foam", "Plank", "Others"],
                    value: selectedCategory,
                    onChanged: (value) {
                      setState(() => selectedCategory = value);
                      _checkForChanges();
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: "Sub category",
                    hintText: "Select a subcategory",
                    isDropdown: true,
                    dropdownItems: ["Wood", "Foam", "Plank", "Others"],
                    value: selectedSubCategory,
                    onChanged: (value) {
                      setState(() => selectedSubCategory = value);
                      _checkForChanges();
                    },
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: existing != null && !_isEdited
                        ? "Use This Product"
                        : "Upload Product",
                    onPressed: _uploadProduct,
                  ),

                  const SizedBox(height: 10),

                  CustomButton(
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
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.brown),
                ),
              ),
            ),
        ],
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
