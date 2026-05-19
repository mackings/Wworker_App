import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ClientQuotationCard extends StatelessWidget {
  final Map<String, dynamic> quotation;
  final VoidCallback? onDelete;
  final bool showSelectionIndicator;
  final bool isSelected;

  const ClientQuotationCard({
    super.key,
    required this.quotation,
    this.onDelete,
    this.showSelectionIndicator = false,
    this.isSelected = false,
  });

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatCurrency(dynamic value) {
    try {
      final amount = double.tryParse(value.toString()) ?? 0.0;
      final formatter = NumberFormat.currency(
        locale: 'en_NG',
        symbol: '₦',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    } catch (_) {
      return '₦0';
    }
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('approved') || normalized.contains('paid')) {
      return const Color(0xFF2E7D32);
    }
    if (normalized.contains('pending') || normalized.contains('draft')) {
      return const Color(0xFF8B4513);
    }
    if (normalized.contains('reject') || normalized.contains('cancel')) {
      return const Color(0xFFD72638);
    }
    return const Color(0xFF4E5BA6);
  }

  @override
  Widget build(BuildContext context) {
    final clientName = quotation['clientName'] ?? 'Unknown';
    final phoneNumber = quotation['phoneNumber'] ?? '';
    final description = quotation['description'] ?? '';
    final total = quotation['finalTotal']?.toString() ?? '0';
    final formattedTotal = _formatCurrency(total);
    final status = quotation['status']?.toString().toUpperCase() ?? 'DRAFT';
    final date = _formatDate(quotation['createdAt'] ?? '');
    final quotationNumber = quotation['quotationNumber'] ?? '';
    final item = (quotation['items'] != null && quotation['items'].isNotEmpty)
        ? quotation['items'][0]
        : null;
    final imageUrl = (item != null && (item['image']?.isNotEmpty ?? false))
        ? item['image'].toString()
        : '';
    final category = item?['woodType'] ?? 'N/A';
    final productName = item?['productName'] ?? description;
    final statusColor = _statusColor(status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? const Color(0xFF8B4513) : const Color(0xFFE8DED6),
          width: isSelected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuotationImage(imageUrl: imageUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.openSans(
                              color: const Color(0xFF211D1A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (showSelectionIndicator) ...[
                              _SelectionMark(isSelected: isSelected),
                              const SizedBox(height: 5),
                            ],
                            Text(
                              formattedTotal,
                              style: GoogleFonts.openSans(
                                color: const Color(0xFF8B4513),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (phoneNumber.toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phoneNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          color: const Color(0xFF756A61),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      productName.toString().isEmpty
                          ? 'Quotation item'
                          : productName.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        color: const Color(0xFF302E2E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description.toString().isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          color: const Color(0xFF756A61),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MetaPill(
                      icon: Icons.tag_rounded,
                      label: quotationNumber,
                      maxLabelWidth: 96,
                    ),
                    _MetaPill(
                      icon: Icons.layers_outlined,
                      label: category.toString(),
                      maxLabelWidth: 108,
                    ),
                    _MetaPill(
                      icon: Icons.event_outlined,
                      label: date,
                      maxLabelWidth: 92,
                    ),
                    _StatusPill(label: status, color: statusColor),
                  ],
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFD72638),
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  final bool isSelected;

  const _SelectionMark({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF8B4513) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFF8B4513) : const Color(0xFFD9CCC2),
          width: 1.4,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _QuotationImage extends StatelessWidget {
  final String imageUrl;

  const _QuotationImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DED6)),
      ),
      child: const Icon(
        Icons.receipt_long_outlined,
        color: Color(0xFF8B4513),
        size: 20,
      ),
    );

    if (imageUrl.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder;
        },
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final double maxLabelWidth;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.maxLabelWidth = 110,
  });

  @override
  Widget build(BuildContext context) {
    final display = label.trim().isEmpty ? 'N/A' : label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8DED6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF756A61)),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxLabelWidth),
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(
                color: const Color(0xFF756A61),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.openSans(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
