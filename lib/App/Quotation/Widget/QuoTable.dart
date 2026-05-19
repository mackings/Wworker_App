import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuotationItem {
  final String product;
  final String description;
  final int quantity;
  final String unitPrice;
  final String total;

  QuotationItem({
    required this.product,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}

class QuotationTable extends StatelessWidget {
  final List<QuotationItem> items;
  static const Color _ink = Color(0xFF211D1A);
  static const Color _muted = Color(0xFF756A61);
  static const Color _brand = Color(0xFF8B4513);
  static const Color _border = Color(0xFFE8DED6);

  const QuotationTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(
      0,
      (sum, item) =>
          sum +
          (double.tryParse(item.total.replaceAll(RegExp(r'[₦,]'), '')) ?? 0),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
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
          _buildTitleRow(total),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _buildEmptyState()
          else
            ...items.asMap().entries.map(
              (entry) => _buildItemCard(entry.key + 1, entry.value),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(double total) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: _brand,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quotation Items',
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${items.length} item${items.length == 1 ? '' : 's'}',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E8),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _brand.withValues(alpha: 0.20)),
          ),
          child: Text(
            '₦${_formatTotal(total)}',
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _brand,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTotal(double value) {
    final text = value.toStringAsFixed(2);
    final parts = text.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$whole.${parts.last}';
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Text(
        'No quotation items added yet.',
        style: GoogleFonts.openSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _muted,
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, QuotationItem item) {
    final description = item.description.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$index',
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _brand,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: _muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  label: 'Qty',
                  value: item.quantity.toString(),
                  alignEnd: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(label: 'Unit', value: item.unitPrice),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(label: 'Total', value: item.total),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    bool alignEnd = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }
}
