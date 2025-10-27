import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class QuoteGlanceCard extends StatelessWidget {
  final String imageUrl;
  final String productName;
  final String bomNo;
  final String description;
  final double costPrice;
  final double sellingPrice;
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;

  const QuoteGlanceCard({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.bomNo,
    required this.description,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });

  Widget _buildRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF121111),
                fontSize: 12,
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                color: color ?? const Color(0xFF302E2E),
                fontSize: 12,
                fontFamily: 'Open Sans',
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                height: 1.33,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cardWidth = isWide ? screenWidth * 0.5 : screenWidth * 0.9;

        return Center(
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: ShapeDecoration(
              color: const Color(0xFFF5F8F2),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼️ Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl.isNotEmpty
                        ? imageUrl
                        : "https://placehold.co/400x250",
                    height: isWide ? 250 : 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),

                // 📋 Product details
                _buildRow('Product Name', productName),
                _buildRow('BOM NO', bomNo),
                _buildRow('Description', description),
                _buildRow('Cost Price', "₦${costPrice.toStringAsFixed(2)}",
                    bold: true),
                _buildRow('Selling Price', "₦${sellingPrice.toStringAsFixed(2)}",
                    bold: true),

                const SizedBox(height: 10),

                // 🔢 Quantity control
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        color: Color(0xFF7B7B7B),
                        fontSize: 13,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onDecrease,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD3D3D3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.remove, size: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(
                            color: Color(0xFF7B7B7B),
                            fontSize: 14,
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: onIncrease,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD3D3D3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 🗑️ Delete item button
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                            width: 1, color: Color(0xFF8B4513)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, color: Color(0xFF8B4513)),
                        SizedBox(width: 8),
                        Text(
                          'Delete Item',
                          style: TextStyle(
                            color: Color(0xFF8B4513),
                            fontSize: 15,
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
