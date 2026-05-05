import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuoteGlanceCard extends StatelessWidget {
  final String imageUrl;
  final String productName;
  final String bomNo;
  final String description;
  final double costPrice;
  final double sellingPrice;
  final int quantity;
  final VoidCallback? onEdit;
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
    this.onEdit,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });

  static const _ink = Color(0xFF211D1A);
  static const _muted = Color(0xFF756A61);
  static const _accent = Color(0xFF8B4513);
  static const _line = Color(0xFFE8DED6);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    final costLabel = formatter.format(costPrice.round());
    final sellingLabel = formatter.format(sellingPrice.round());
    final margin = sellingPrice - costPrice;
    final marginLabel = formatter.format(margin.round());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  _buildMoneyStrip(
                    costLabel,
                    sellingLabel,
                    marginLabel,
                    margin,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QuantityStepper(
                        quantity: quantity,
                        onIncrease: onIncrease,
                        onDecrease: onDecrease,
                      ),
                      const Spacer(),
                      _CardActionButton(
                        icon: Icons.tune_rounded,
                        color: _accent,
                        backgroundColor: const Color(0xFFFFF3E8),
                        tooltip: 'Edit BOM',
                        onPressed: onEdit,
                      ),
                      const SizedBox(width: 8),
                      _CardActionButton(
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFB3261E),
                        backgroundColor: const Color(0xFFFFEDEA),
                        tooltip: 'Delete',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF8),
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductThumb(imageUrl: imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName.isEmpty ? 'Untitled product' : productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description.isEmpty ? 'No description' : description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EFE9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bomNo.isEmpty ? 'BOM N/A' : bomNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  Widget _buildMoneyStrip(
    String costLabel,
    String sellingLabel,
    String marginLabel,
    double margin,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InlineMetric(label: 'Cost', value: '₦$costLabel'),
          ),
          _MetricDivider(),
          Expanded(
            child: _InlineMetric(
              label: 'Selling',
              value: '₦$sellingLabel',
              color: _accent,
            ),
          ),
          _MetricDivider(),
          Expanded(
            child: _InlineMetric(
              label: 'Margin',
              value: '₦$marginLabel',
              color: margin >= 0 ? const Color(0xFF247A3D) : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String imageUrl;

  const _ProductThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 68,
        height: 68,
        child: imageUrl.isEmpty
            ? _fallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF2ECE6),
      child: const Icon(
        Icons.chair_alt_outlined,
        color: QuoteGlanceCard._accent,
        size: 28,
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InlineMetric({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: QuoteGlanceCard._muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: color ?? QuoteGlanceCard._ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: QuoteGlanceCard._line,
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: QuoteGlanceCard._line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_rounded, size: 18),
            color: QuoteGlanceCard._accent,
            tooltip: 'Decrease',
            constraints: const BoxConstraints.tightFor(width: 38, height: 38),
            padding: EdgeInsets.zero,
          ),
          SizedBox(
            width: 34,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: QuoteGlanceCard._ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded, size: 18),
            color: QuoteGlanceCard._accent,
            tooltip: 'Increase',
            constraints: const BoxConstraints.tightFor(width: 38, height: 38),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CardActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 42,
            height: 40,
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}
