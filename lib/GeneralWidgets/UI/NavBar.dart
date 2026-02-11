import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final List<BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;

  const CustomBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.selectedColor = const Color(0xFF8B4513),
    this.unselectedColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    // Paint the device bottom inset area too (keeps it white instead of letting
    // the page behind show through).
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return GestureDetector(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected ? selectedColor : unselectedColor,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? selectedColor : unselectedColor,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  BottomNavItem({required this.icon, required this.label});
}
