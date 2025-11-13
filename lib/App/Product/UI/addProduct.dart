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

  const AddProduct({super.key, this.existingProduct});

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

    if (existing != null && !_isEdited) {
      _proceedWithQuotation(existing);
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
        _proceedWithQuotation(productData);
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

  Future<void> _proceedWithQuotation(dynamic productData) async {
    final quotationNotifier = ref.read(quotationSummaryProvider.notifier);
    final materialNotifier = ref.read(materialProvider.notifier);

    final materialState = materialNotifier.state;
    final materials = List<Map<String, dynamic>>.from(
      materialState["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      materialState["additionalCosts"] ?? [],
    );

    // ✅ Safely get product name
    final productName = (productData is ProductModel)
        ? productData.name
        : (productData is Map<String, dynamic>)
        ? productData["name"]
        : "Unknown";

    // ✅ Update materials with product name
    final updatedMaterials = materials
        .map((m) => {...m, "Product": productName})
        .toList();

    final newQuotation = {
      "product": (productData is ProductModel)
          ? {
              "productId": productData.productId,
              "name": productData.name,
              "category": productData.category,
              "description": productData.description,
              "image": productData.image,
            }
          : productData,
      "materials": updatedMaterials,
      "additionalCosts": additionalCosts,
    };

    await quotationNotifier.addNewQuotation(newQuotation);

    if (context.mounted) {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => const QuotationSummary()),
      // );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BOMSummary()),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Quotation created successfully!"),
        backgroundColor: Colors.green,
      ),
    );
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
