import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Product/UI/addProduct.dart';
import 'package:wworker/App/Quotation/Model/ProductModel.dart';
import 'package:wworker/App/Quotation/Providers/ProductProvider.dart';
import 'package:wworker/App/Quotation/Widget/ExistingProductCard.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';




class SelectExistingProductScreen extends ConsumerStatefulWidget {
  const SelectExistingProductScreen({super.key});

  @override
  ConsumerState<SelectExistingProductScreen> createState() =>
      _SelectExistingProductScreenState();
}

class _SelectExistingProductScreenState
    extends ConsumerState<SelectExistingProductScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    await ref.read(productProvider.notifier).fetchProducts();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: CustomText(title: "Products"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Center(child: Text("No products available"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ExistingProductCard(
                    imageUrl: p.image,
                    name: p.name,
                    productId: p.productId,
                    category: p.category,
                    onTap: () {
                      print(p.productId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddProduct(existingProduct: p as ProductModel?),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
