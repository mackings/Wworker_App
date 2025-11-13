import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class ClientQuotationCard extends StatelessWidget {
  final Map<String, dynamic> quotation;
  final VoidCallback? onDelete;

  const ClientQuotationCard({
    super.key,
    required this.quotation,
    this.onDelete,
  });

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(date);
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
        ? item['image']
        : 'https://placehold.co/66x64';
    final category = item?['woodType'] ?? 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F8F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT SIDE

          // LEFT SIDE
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image + Client Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Client Name & Phone under the image
                    CustomText(
                      title: clientName,
                      titleFontSize: 13,
                      titleFontWeight: FontWeight.w600,
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      title: phoneNumber,
                      titleFontSize: 12,
                      titleFontWeight: FontWeight.w400,
                      titleColor: const Color(0xFF7B7B7B),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Description & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title: description,
                        titleFontSize: 12,
                        titleFontWeight: FontWeight.w500,
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        title: quotationNumber,
                        titleFontSize: 11,
                        titleFontWeight: FontWeight.w700,
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 10),
                      CustomText(
                        title: category,
                        titleFontSize: 11,
                        titleFontWeight: FontWeight.w400,
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        title: date,
                        titleFontSize: 11,
                        titleFontWeight: FontWeight.w400,
                        titleColor: const Color(0xFF7B7B7B),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // RIGHT SIDE
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  title: formattedTotal,
                  titleFontSize: 16,
                  titleFontWeight: FontWeight.w600,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFEBF1E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Center(
                    child: CustomText(
                      title: status,
                      titleFontSize: 12,
                      titleFontWeight: FontWeight.w600,
                      titleColor: const Color(0xFF7B7B7B),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFFD72638),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Color(0xFFD72638),
                        ),
                        const SizedBox(width: 6),
                        CustomText(
                          title: 'Delete',
                          titleFontSize: 13,
                          titleFontWeight: FontWeight.w600,
                          titleColor: const Color(0xFFD72638),
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
