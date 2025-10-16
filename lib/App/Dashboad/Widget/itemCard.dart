import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemsCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onDelete;

  const ItemsCard({
    super.key,
    required this.item,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textStyleLabel = GoogleFonts.openSans(
      color: const Color(0xFF7B7B7B),
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );
    final textStyleValue = GoogleFonts.openSans(
      color: const Color(0xFF302E2E),
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        border: Border.all(color: const Color(0xFFD3D3D3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔲 Inner bordered container for item details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD3D3D3)),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              children: item.entries
                  .map((entry) => _buildRow(
                        entry.key,
                        entry.value,
                        textStyleLabel,
                        textStyleValue,
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          // 🗑️ Delete button
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8B4513)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline, color: Color(0xFF8B4513), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Delete Item",
                    style: GoogleFonts.openSans(
                      color: const Color(0xFF8B4513),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    dynamic value,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(value.toString(), style: valueStyle),
        ],
      ),
    );
  }
}
