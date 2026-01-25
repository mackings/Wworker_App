import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemsCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onDelete;
  final VoidCallback? onAdd;
  final bool showAddButton;
  final bool showPriceIncrementToggle;
  final bool isPriceIncrementDisabled;
  final ValueChanged<bool>? onPriceIncrementToggle;
  final bool useBomStyle;
  final VoidCallback? onEdit;

  const ItemsCard({
    super.key,
    required this.item,
    this.onDelete,
    this.onAdd,
    this.showAddButton =
        false, // default = false (so existing pages won't break)
    this.showPriceIncrementToggle = false,
    this.isPriceIncrementDisabled = false,
    this.onPriceIncrementToggle,
    this.useBomStyle = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (useBomStyle) {
      return _buildBomStyleCard(context);
    }

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
          /// 🔹 Item details
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
                  .map(
                    (entry) => _buildRow(
                      entry.key,
                      entry.value,
                      textStyleLabel,
                      textStyleValue,
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          if (showPriceIncrementToggle) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Disable price increment",
                      style: GoogleFonts.openSans(
                        color: const Color(0xFF302E2E),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 18),
                      color: const Color(0xFF7B7B7B),
                      onPressed: () => _showPriceIncrementHelp(context),
                      tooltip: "What does this mean?",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: isPriceIncrementDisabled,
                  onChanged: onPriceIncrementToggle,
                  activeColor: const Color(0xFF8B4513),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          /// 🔹 Action button (Add or Delete)
          GestureDetector(
            onTap: showAddButton ? onAdd : onDelete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: showAddButton
                      ? const Color(0xFF2E7D32) // green border for Add
                      : const Color(0xFF8B4513), // brown border for Delete
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    showAddButton
                        ? Icons.add_circle_outline
                        : Icons.delete_outline,
                    color: showAddButton
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF8B4513),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    showAddButton ? "Add to List" : "Delete Item",
                    style: GoogleFonts.openSans(
                      color: showAddButton
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF8B4513),
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

  Widget _buildBomStyleCard(BuildContext context) {
    final rows = <MapEntry<String, String>>[];
    const orderedKeys = [
      "Product",
      "Materialname",
      "Width",
      "Length",
      "Thickness",
      "Unit",
      "Sqm",
      "Price",
      "quantity",
      "Total",
    ];

    for (final key in orderedKeys) {
      final value = item[key];
      if (value == null) continue;
      final valueText = value.toString().trim();
      if (valueText.isEmpty) continue;
      rows.add(MapEntry(key, valueText));
    }

    Widget buildRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
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
            Flexible(
              flex: 6,
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  color: Color(0xFF302E2E),
                  fontSize: 12,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD3D3D3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...rows.map((row) => buildRow(row.key, row.value)),

              if (rows.isNotEmpty) const SizedBox(height: 8),

              if (item["Total"] != null && item["Total"].toString().isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFA16438),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(
                          color: Color(0xFF302E2E),
                          fontSize: 13,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w600,
                          height: 1.33,
                        ),
                      ),
                      Text(
                        item["Total"].toString(),
                        style: const TextStyle(
                          color: Color(0xFFA16438),
                          fontSize: 14,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w700,
                          height: 1.33,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              if (showPriceIncrementToggle) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Disable price increment",
                          style: GoogleFonts.openSans(
                            color: const Color(0xFF302E2E),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.help_outline, size: 18),
                          color: const Color(0xFF7B7B7B),
                          onPressed: () => _showPriceIncrementHelp(context),
                          tooltip: "What does this mean?",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: isPriceIncrementDisabled,
                      onChanged: onPriceIncrementToggle,
                      activeColor: const Color(0xFF8B4513),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              GestureDetector(
                onTap: showAddButton ? onAdd : onDelete,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: showAddButton
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF8B4513),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        showAddButton
                            ? Icons.add_circle_outline
                            : Icons.delete_outline,
                        color: showAddButton
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF8B4513),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        showAddButton ? "Add to List" : "Delete Item",
                        style: GoogleFonts.openSans(
                          color: showAddButton
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF8B4513),
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
        ),
        if (onEdit != null)
          Positioned(
            top: 6,
            right: 18,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, size: 18),
                color: const Color(0xFF8B4513),
                onPressed: onEdit,
                tooltip: "Edit item",
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ),
          ),
      ],
    );
  }

  void _showPriceIncrementHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3D3D3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Disable price increment",
              style: GoogleFonts.openSans(
                color: const Color(0xFF302E2E),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When enabled, the item total uses the base price only and "
              "does not multiply by quantity.",
              style: GoogleFonts.openSans(
                color: const Color(0xFF7B7B7B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Got it"),
              ),
            ),
          ],
        ),
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
          Flexible(
            child: Text(
              value.toString(),
              style: valueStyle,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
