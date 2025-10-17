import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';

class BOMSummaryCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;

  const BOMSummaryCard({
    super.key,
    required this.item, required Null Function() onQuantityChanged,
  });

  @override
  ConsumerState<BOMSummaryCard> createState() => _BOMSummaryCardState();
}

class _BOMSummaryCardState extends ConsumerState<BOMSummaryCard> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = (widget.item["quantity"] ?? 1).toInt(); // default to 1
  }

  void _updateQuantity(int newQuantity) {
    setState(() => quantity = newQuantity);
    widget.item["quantity"] = quantity;

    // 🔹 Update provider state
    final state = ref.read(materialProvider.notifier).state;

    final materials = List<Map<String, dynamic>>.from(state["materials"]);
    final index = materials.indexWhere((m) =>
        m["Materialname"] == widget.item["Materialname"] &&
        m["Product"] == widget.item["Product"]);
    if (index != -1) {
      materials[index] = widget.item;
    }

    ref.read(materialProvider.notifier).state = {
      ...state,
      "materials": materials,
    };
  }

  void _increaseQuantity() => _updateQuantity(quantity + 1);

  void _decreaseQuantity() {
    if (quantity > 1) _updateQuantity(quantity - 1);
  }

  Widget _buildRow(String label, String value) {
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

  @override
  Widget build(BuildContext context) {
    final bool isMaterial = widget.item.containsKey("Materialname");

    // Price or additional cost
    final double price = double.tryParse(
          (widget.item["Price"] ?? widget.item["amount"] ?? "0").toString(),
        ) ??
        0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMaterial) ...[
            _buildRow('Product', widget.item["Product"] ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Material Name', widget.item["Materialname"] ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Width', widget.item["Width"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Length', widget.item["Length"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Thickness', widget.item["Thickness"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Unit', widget.item["Unit"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Square Meter', widget.item["Sqm"]?.toString() ?? "-"),
            const SizedBox(height: 16),

            // Quantity controls
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
                      onPressed: _decreaseQuantity,
                    ),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _increaseQuantity,
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            _buildRow('Description', widget.item["description"] ?? "-"),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),

          // Price display only
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

