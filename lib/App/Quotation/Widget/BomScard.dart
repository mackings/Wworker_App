import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';


class BOMSummaryCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onQuantityChanged;

  const BOMSummaryCard({
    super.key,
    required this.item,
    this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int quantity = 1;
    final q = item["quantity"];
    if (q is int) {
      quantity = q;
    } else if (q is double) {
      quantity = q.toInt();
    } else if (q is String) {
      quantity = int.tryParse(q) ?? 1;
    }

    void updateQuantity(int newQuantity) {
      item["quantity"] = newQuantity.toString();

      final state = ref.read(materialProvider.notifier).state;
      final materials = List<Map<String, dynamic>>.from(state["materials"]);

      final index = materials.indexWhere((m) =>
          m["Materialname"] == item["Materialname"] &&
          m["Product"] == item["Product"]);

      if (index != -1) materials[index] = item;

      ref.read(materialProvider.notifier).state = {
        ...state,
        "materials": materials,
      };

      onQuantityChanged?.call();
    }

    void increaseQuantity() => updateQuantity(quantity + 1);
    void decreaseQuantity() {
      if (quantity > 1) updateQuantity(quantity - 1);
    }

    final bool isMaterial = item.containsKey("Woodtype") ||
        item.containsKey("Materialname") ||
        item.containsKey("Product");

    final double price = double.tryParse(
          (item["Price"] ?? item["amount"] ?? "0").toString(),
        ) ??
        0;

    Widget buildRow(String label, String value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF302E2E),
              fontSize: 16,
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF302E2E),
              fontSize: 16,
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMaterial) ...[
            buildRow('Product', item["Product"] ?? "-"),
            const SizedBox(height: 12),
            buildRow('Material Name', item["Woodtype"] ?? "-"),
            const SizedBox(height: 12),
            buildRow('Width', item["Width"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            buildRow('Length', item["Length"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            buildRow('Thickness', item["Thickness"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            buildRow('Unit', item["Unit"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            buildRow('Square Meter', item["Sqm"]?.toString() ?? "-"),
            const SizedBox(height: 16),

            // 🔹 Quantity controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantity',
                  style: TextStyle(
                    color: Color(0xFF302E2E),
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: decreaseQuantity,
                    ),
                    Text(
                      item["quantity"]?.toString() ?? "1",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: increaseQuantity,
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            buildRow('Description', item["description"] ?? "-"),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),

          // 🔹 Price section
          Container(
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: const Color(0xFFF5F8F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(
                    color: Color(0xFF302E2E),
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
                Text(
                  "₦${price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Color(0xFF302E2E),
                    fontSize: 16,
                    fontFamily: 'Open Sans',
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

