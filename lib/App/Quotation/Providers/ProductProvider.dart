import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wworker/App/Quotation/Api/ProductService.dart';
import 'package:wworker/App/Quotation/Model/ProductModel.dart';

final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(),
);

final productProvider =
    StateNotifierProvider<ProductNotifier, List<ProductModel>>((ref) {
      return ProductNotifier(ref);
    });

class ProductNotifier extends StateNotifier<List<ProductModel>> {
  final Ref ref;

  ProductNotifier(this.ref) : super([]);

  Future<void> fetchProducts() async {
    final response = await ref.read(productServiceProvider).getAllProducts();

    if (response["success"] == true && response["data"] != null) {
      final List<dynamic> rawData = response["data"];
      state = rawData.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      state = [];
    }
  }
}
