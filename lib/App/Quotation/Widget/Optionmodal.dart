import 'package:flutter/material.dart';

class SelectOptionSheet extends StatelessWidget {
  final String title;
  final List<OptionItem> options;

  const SelectOptionSheet({
    super.key,
    required this.title,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: const ShapeDecoration(
        color: Color(0xFFFCFCFC),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: Color(0xFFD3D3D3)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🟤 Handle bar + title
          Column(
            children: [
              Container(
                width: 80,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3D3D3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF302E2E),
                  fontSize: 16,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 🟢 Dynamic options list
          ...options.map(
            (option) => GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close the modal
                option.onTap?.call(); // Execute the callback
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Color(0xFFD3D3D3)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(
                        color: Color(0xFF302E2E),
                        fontSize: 14,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OptionItem {
  final String label;
  final VoidCallback? onTap;

  OptionItem({required this.label, this.onTap});
}
