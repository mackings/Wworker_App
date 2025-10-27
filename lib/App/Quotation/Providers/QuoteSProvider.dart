import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';


final quotationSummaryProvider =
    StateNotifierProvider<QuotationSummaryNotifier, Map<String, dynamic>>((ref) {
  return QuotationSummaryNotifier(ref);
});

class QuotationSummaryNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;

  QuotationSummaryNotifier(this.ref)
      : super({
          "product": null,
          "materials": [],
          "additionalCosts": [],
        });

  // 🧱 Load from material provider
  void loadFromMaterialProvider() {
    final materialState = ref.read(materialProvider);
    state = {
      ...state,
      "materials": materialState["materials"] ?? [],
      "additionalCosts": materialState["additionalCosts"] ?? [],
    };
  }

  // 🧩 Set product after creation
  void setProduct(Map<String, dynamic> productData) {
    state = {
      ...state,
      "product": {
        "name": productData["name"],
        "image": productData["image"],
        "description": productData["description"],
        "productId": productData["productId"],
      },
    };
  }

  // 🚀 Clear everything (optional)
  void clear() {
    state = {
      "product": null,
      "materials": [],
      "additionalCosts": [],
    };
  }
}
