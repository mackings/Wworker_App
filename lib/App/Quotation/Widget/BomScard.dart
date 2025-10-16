import 'package:flutter/material.dart';



class BOMSummaryCard extends StatelessWidget {
  final Map<String, dynamic> item; // we pass one map for flexibility

  const BOMSummaryCard({
    super.key,
    required this.item,
  });

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
    // detect if this is material or additional cost
    final bool isMaterial = item.containsKey("Materialname");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMaterial) ...[
            _buildRow('Product', item["Product"] ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Material Name', item["Materialname"] ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Width', item["Width"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Length', item["Length"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Thickness', item["Thickness"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Unit', item["Unit"]?.toString() ?? "-"),
            const SizedBox(height: 12),
            _buildRow('Square Meter', item["Sqm"]?.toString() ?? "-"),
          ] else ...[
            _buildRow('Description', item["description"] ?? "-"),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),

          // 🟩 Price / Amount
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item["Price"]?.toString() ??
                          item["amount"]?.toString() ??
                          "-",
                      style: const TextStyle(
                        color: Color(0xFF302E2E),
                        fontSize: 16,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                    Text(
                      'Last updated: ${item["lastUpdated"] ?? "-"}',
                      style: const TextStyle(
                        color: Color(0xFF302E2E),
                        fontSize: 10,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
