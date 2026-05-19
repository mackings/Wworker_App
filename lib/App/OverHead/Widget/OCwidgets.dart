// overhead_cost_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _ohInk = Color(0xFF211D1A);
const Color _ohMuted = Color(0xFF756A61);
const Color _ohBrand = Color(0xFF8B4513);
const Color _ohBorder = Color(0xFFE8DED6);

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _ohBorder),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _ohBrand.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: _ohBrand, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Add Cost",
                      style: GoogleFonts.openSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _ohInk,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _ohBrand,
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
                const SizedBox(height: 14),

                // Category Tabs
                CategoryTabsWidget(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategoryChanged: onCategoryChanged,
                ),

                const SizedBox(height: 14),

                // Description Field
                CustomTextField(
                  label: "Description",
                  controller: descriptionController,
                  hintText: "e.g., Office Rent",
                ),

                const SizedBox(height: 12),

                // Period Dropdown
                CustomDropdown(
                  label: "Period",
                  value: selectedPeriod,
                  items: periods,
                  onChanged: onPeriodChanged,
                ),

                const SizedBox(height: 12),

                // Cost Field
                CustomTextField(
                  label: "Cost",
                  controller: costController,
                  hintText: "15,000",
                  keyboardType: TextInputType.number,
                  suffixText: "NGN",
                ),

                const SizedBox(height: 14),

                // Add Item Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onAddItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA16438),
                      disabledBackgroundColor: const Color(0xFFCCA183),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                              const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Add item",
                                style: GoogleFonts.openSans(
                                  fontSize: 14,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFF3E8) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _ohBrand : _ohBorder),
              ),
              child: Text(
                category,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: selected ? _ohBrand : _ohMuted,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
            fontSize: 12,
            color: _ohMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
            suffixText: suffixText,
            suffixStyle: GoogleFonts.openSans(
              fontSize: 12,
              color: _ohMuted,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _ohBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _ohBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _ohBrand, width: 1.3),
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
            fontSize: 12,
            color: _ohMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _ohBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _ohBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _ohBrand, width: 1.3),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _ohInk,
                    ),
                  ),
                ),
              )
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ohBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _ohBrand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: _ohBrand,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: _ohInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.category} • ${item.period}',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: _ohMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "₦${item.cost.toStringAsFixed(2)}",
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _ohBrand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 17),
              label: const Text("Delete"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFA1421F),
                textStyle: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
  final List<String> durations = const [
    'Hourly',
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ohBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "View Total By:",
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _ohInk,
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
                    color: isSelected ? _ohBrand : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _ohBrand : _ohBorder,
                    ),
                  ),
                  child: Text(
                    duration,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : _ohInk,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ohBorder),
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
                  color: _ohInk,
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
                    fontWeight: FontWeight.w500,
                    color: _ohBrand,
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
                  fontWeight: FontWeight.w600,
                  color: _ohInk,
                ),
              ),
              Text(
                "₦${total.toStringAsFixed(2)}",
                style: GoogleFonts.openSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _ohBrand,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
