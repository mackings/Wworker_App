import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Product/providers/provider.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/BomSummary.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';



class AddProduct extends ConsumerStatefulWidget {
  const AddProduct({super.key});

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



Future<void> _uploadProduct() async {
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
    final response = await ref.read(productServiceProvider).createProduct(
          name: nameController.text,
          subCategory: selectedSubCategory ?? "",
          description: descController.text,
          category: selectedCategory ?? "",
          imagePath: imagePath!,
        );

    setState(() => isLoading = false);

    if (response["success"] == true) {
      final productData = response["data"];

      // 🔹 Access both providers
      final quotationNotifier = ref.read(quotationSummaryProvider.notifier);
      final materialNotifier = ref.read(materialProvider.notifier);

      // 🔹 Get existing materials from Material Provider
      final materialState = materialNotifier.state;
      final materials =
          List<Map<String, dynamic>>.from(materialState["materials"]);

      // 🔹 Add uploaded product name to each material
      final updatedMaterials = materials.map((m) {
        return {
          ...m,
          "Product": productData["name"], // attach uploaded product name
        };
      }).toList();

      // 🔹 Update Material Provider
      materialNotifier.state = {
        ...materialState,
        "materials": updatedMaterials,
      };

      // 🔹 Save product info into Quotation provider
      quotationNotifier.setProduct(productData);
      quotationNotifier.loadFromMaterialProvider();

      // ✅ Navigate to BOMSummary (not QuotationSummary)
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BOMSummary()),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Product uploaded and materials updated!"),
          backgroundColor: Colors.green,
        ),
      );
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
      SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          /// 🧱 Main Page Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(title: "New product"),
                    const SizedBox(height: 20),

                    CustomImgBg(
                      onImageSelected: (image) {
                        setState(() {
                          imagePath = image?.path;
                        });
                        debugPrint("📸 Image selected: ${image?.path}");
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
                      onChanged: (value) =>
                          setState(() => selectedCategory = value),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: "Sub category",
                      hintText: "Select a subcategory",
                      isDropdown: true,
                      dropdownItems: ["Wood", "Foam", "Plank", "Others"],
                      onChanged: (value) =>
                          setState(() => selectedSubCategory = value),
                    ),
                    const SizedBox(height: 40),

    
                    CustomButton(
                      text: "Upload Product",
                      onPressed: _uploadProduct,
                    ),

                  ],
                ),
              ),
            ),
          ),

          /// 🔄 Overlay Loader
          ///
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.brown,
                    strokeWidth: 4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
