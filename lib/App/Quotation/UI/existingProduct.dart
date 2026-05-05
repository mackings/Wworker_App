import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Product/UI/addProduct.dart';
import 'package:wworker/App/Quotation/Model/ProductModel.dart';
import 'package:wworker/App/Quotation/Providers/ProductProvider.dart';
import 'package:wworker/App/Quotation/Widget/ExistingProductCard.dart';

class SelectExistingProductScreen extends ConsumerStatefulWidget {
  const SelectExistingProductScreen({super.key});

  @override
  ConsumerState<SelectExistingProductScreen> createState() =>
      _SelectExistingProductScreenState();
}

class _SelectExistingProductScreenState
    extends ConsumerState<SelectExistingProductScreen> {
  bool isLoading = true;
  String? selectedProductId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    await ref.read(productProvider.notifier).fetchProducts();
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _selectProduct(ProductModel product) async {
    setState(() => selectedProductId = product.productId);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProduct(existingProduct: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Products",
          style: GoogleFonts.openSans(
            color: const Color(0xFF211D1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB7835E)),
            )
          : products.isEmpty
          ? _EmptyProducts(onRefresh: _loadProducts)
          : RefreshIndicator(
              color: const Color(0xFFB7835E),
              onRefresh: _loadProducts,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                itemCount: products.length + 1,
                separatorBuilder: (_, index) =>
                    SizedBox(height: index == 0 ? 12 : 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _SelectionNotice(count: products.length);
                  }

                  final product = products[index - 1];
                  return ExistingProductCard(
                    imageUrl: product.image,
                    name: product.name,
                    productId: product.productId,
                    category: product.category,
                    isSelected: selectedProductId == product.productId,
                    onTap: () => _selectProduct(product),
                  );
                },
              ),
            ),
    );
  }
}

class _SelectionNotice extends StatelessWidget {
  final int count;

  const _SelectionNotice({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C211B),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.touch_app_outlined,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select a product to continue",
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Choose one of your $count products. You can review it, then continue to build the BOM.",
                  style: GoogleFonts.openSans(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyProducts({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFFB7835E),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "No products available",
              style: GoogleFonts.openSans(
                color: const Color(0xFF211D1A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Add a product first, then return here to select it and continue.",
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                color: const Color(0xFF756A61),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B4513),
                side: const BorderSide(color: Color(0xFFB7835E)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
