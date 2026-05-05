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
  final bool showQuantityControls;
  final int quantity;
  final VoidCallback? onIncreaseQuantity;
  final VoidCallback? onDecreaseQuantity;

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
    this.showQuantityControls = false,
    this.quantity = 1,
    this.onIncreaseQuantity,
    this.onDecreaseQuantity,
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
                  .where((entry) => entry.key != "disableIncrement")
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
                  activeThumbColor: const Color(0xFF8B4513),
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
    final detailRows = <MapEntry<String, String>>[];
    const orderedKeys = [
      "Width",
      "Length",
      "Thickness",
      "Unit",
      "Sqm",
      "quantity",
    ];

    for (final key in orderedKeys) {
      final value = item[key];
      if (value == null) continue;
      final valueText = value.toString().trim();
      if (valueText.isEmpty) continue;
      detailRows.add(MapEntry(_prettyLabel(key), valueText));
    }

    final title = (item["Materialname"] ?? item["type"] ?? item["name"] ?? "")
        .toString()
        .trim();
    final subtitle = (item["Product"] ?? item["description"] ?? "")
        .toString()
        .trim();
    final price =
        item["Total"] ?? item["LineTotal"] ?? item["Price"] ?? item["amount"];
    final priceText = price == null || price.toString().trim().isEmpty
        ? null
        : price.toString();
    final showTopDelete = !showAddButton && onDelete != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8DED6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
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
                  color: const Color(0xFFFFF3E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item["amount"] != null
                      ? Icons.payments_outlined
                      : Icons.layers_outlined,
                  color: const Color(0xFF8B4513),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? "BOM item" : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        color: const Color(0xFF211D1A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          color: const Color(0xFF756A61),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onEdit != null || showTopDelete) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      _TopActionButton(
                        icon: Icons.edit_outlined,
                        tooltip: "Edit item",
                        color: const Color(0xFF8B4513),
                        onPressed: onEdit!,
                      ),
                    if (showTopDelete) ...[
                      if (onEdit != null) const SizedBox(width: 6),
                      _TopActionButton(
                        icon: Icons.delete_outline,
                        tooltip: "Delete item",
                        color: const Color(0xFFA1421F),
                        onPressed: () => _showDeleteConfirmation(context),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),

          if (detailRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: detailRows
                  .map((row) => _MeasureBox(label: row.key, value: row.value))
                  .toList(),
            ),
          ],

          if (showQuantityControls) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD3D3D3)),
              ),
              child: Row(
                children: [
                  const Text(
                    "Quantity",
                    style: TextStyle(
                      color: Color(0xFF302E2E),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onDecreaseQuantity,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: const Color(0xFF8B4513),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                        color: Color(0xFF302E2E),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onIncreaseQuantity,
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFF8B4513),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],

          if (priceText != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA16438), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Line Total",
                    style: TextStyle(
                      color: Color(0xFF302E2E),
                      fontSize: 13,
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.33,
                    ),
                  ),
                  Text(
                    priceText,
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

          if (showPriceIncrementToggle) ...[
            const SizedBox(height: 12),
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
                  activeThumbColor: const Color(0xFF8B4513),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (showAddButton)
            GestureDetector(
              onTap: showAddButton ? onAdd : onDelete,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
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
              "does not multiply by quotation quantity.",
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

  void _showDeleteConfirmation(BuildContext context) {
    final title = (item["Materialname"] ?? item["type"] ?? item["name"] ?? "")
        .toString()
        .trim();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const ShapeDecoration(
          color: Color(0xFFFCFCFC),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: Color(0xFFE8DED6)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D0C9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDE6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFA1421F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Delete item?",
                      style: GoogleFonts.openSans(
                        color: const Color(0xFF211D1A),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title.isEmpty
                    ? "This item will be removed from the BOM."
                    : "$title will be removed from the BOM.",
                style: GoogleFonts.openSans(
                  color: const Color(0xFF756A61),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF302E2E),
                        side: const BorderSide(color: Color(0xFFD8D0C9)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.openSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        onDelete?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA1421F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        "Delete",
                        style: GoogleFonts.openSans(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _prettyLabel(String key) {
    switch (key) {
      case "Sqm":
        return "Sqm";
      case "quantity":
        return "Qty";
      default:
        return key;
    }
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

class _MeasureBox extends StatelessWidget {
  final String label;
  final String value;

  const _MeasureBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8DED6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.openSans(
              color: const Color(0xFF756A61),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: GoogleFonts.openSans(
              color: const Color(0xFF211D1A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _TopActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFAF7F3),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8DED6)),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
        ),
      ),
    );
  }
}
