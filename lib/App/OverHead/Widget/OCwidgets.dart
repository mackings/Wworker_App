// overhead_cost_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==============================
// 1. ADD COST FORM WIDGET
// ==============================
class AddCostFormWidget extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final String selectedCategory;
  final List<String> categories;
  final Function(String) onCategoryChanged;
  final TextEditingController descriptionController;
  final String? selectedPeriod;
  final List<String> periods;
  final Function(String?) onPeriodChanged;
  final TextEditingController costController;
  final bool isLoading;
  final VoidCallback onAddItem;

  const AddCostFormWidget({
    super.key,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.descriptionController,
    required this.selectedPeriod,
    required this.periods,
    required this.onPeriodChanged,
    required this.costController,
    required this.isLoading,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD3D3D3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: onToggleExpand,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.add,
                      color: Color(0xFFA16438),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Add Cost",
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF302E2E),
                      ),
                    ),
                  ],
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFFA16438),
                ),
              ],
            ),
          ),

          // Expandable Form
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Category Tabs
                CategoryTabsWidget(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategoryChanged: onCategoryChanged,
                ),

                const SizedBox(height: 20),

                // Description Field
                CustomTextField(
                  label: "Description",
                  controller: descriptionController,
                  hintText: "e.g., Office Rent",
                ),

                const SizedBox(height: 16),

                // Period Dropdown
                CustomDropdown(
                  label: "Period",
                  value: selectedPeriod,
                  items: periods,
                  onChanged: onPeriodChanged,
                ),

                const SizedBox(height: 16),

                // Cost Field
                CustomTextField(
                  label: "Cost",
                  controller: costController,
                  hintText: "15,000",
                  keyboardType: TextInputType.number,
                  suffixText: "NGN",
                ),

                const SizedBox(height: 20),

                // Add Item Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onAddItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA16438),
                      disabledBackgroundColor: const Color(0xFFCCA183),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, size: 20, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                "Add item",
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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

// ==============================
// 2. CATEGORY TABS WIDGET
// ==============================
class CategoryTabsWidget extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const CategoryTabsWidget({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final selected = selectedCategory == category;
          return GestureDetector(
            onTap: () => onCategoryChanged(category),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected
                        ? const Color(0xFFA16438)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                category,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: selected
                      ? const Color(0xFFA16438)
                      : const Color(0xFF9E9E9E),
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ==============================
// 3. CUSTOM TEXT FIELD WIDGET
// ==============================
class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final String? suffixText;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFBDBDBD),
              fontSize: 13,
            ),
            suffixText: suffixText,
            suffixStyle: GoogleFonts.openSans(
              fontSize: 14,
              color: const Color(0xFF7B7B7B),
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==============================
// 4. CUSTOM DROPDOWN WIDGET
// ==============================
class CustomDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: const Color(0xFF7B7B7B),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
              ),
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ==============================
// 5. ITEM CARD WIDGET
// ==============================
class OverheadCostItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onDelete;

  const OverheadCostItemCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          _buildItemRow("Category", item.category),
          _buildItemRow("Description", item.description),
          _buildItemRow("Period", item.period),
          _buildItemRow("Cost", "₦${item.cost.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(
                "Delete Item",
                style: GoogleFonts.openSans(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA16438),
                side: const BorderSide(color: Color(0xFFA16438)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: const Color(0xFF7B7B7B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF302E2E),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================
// 6. DURATION SELECTOR WIDGET
// ==============================
class DurationSelectorWidget extends StatelessWidget {
  final String selectedDuration;
  final Function(String) onDurationChanged;
  final List<String> durations = const ['Hourly', 'Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly'];

  const DurationSelectorWidget({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "View Total By:",
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF302E2E),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: durations.map((duration) {
              final isSelected = selectedDuration == duration;
              return GestureDetector(
                onTap: () => onDurationChanged(duration),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFA16438)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFA16438)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Text(
                    duration,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : const Color(0xFF302E2E),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ==============================
// 7. TOTAL DISPLAY WIDGET
// ==============================
class TotalDisplayWidget extends StatelessWidget {
  final int itemCount;
  final double total;
  final String duration;

  const TotalDisplayWidget({
    super.key,
    required this.itemCount,
    required this.total,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Items ($itemCount)",
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF302E2E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  duration,
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFA16438),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total ($duration):",
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF302E2E),
                ),
              ),
              Text(
                "₦${total.toStringAsFixed(2)}",
                style: GoogleFonts.openSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFA16438),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}