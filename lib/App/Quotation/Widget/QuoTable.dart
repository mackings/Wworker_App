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

  const QuotationTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: constraints.maxWidth > 600 ? 600 : constraints.maxWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFBFBFB)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildRows(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final headerStyle = GoogleFonts.openSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF8B4513),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F8F2),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFF8B4513)),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Center(child: Text('Product', style: headerStyle)),
          ),
          Expanded(
            flex: 4,
            child: Center(child: Text('Desc', style: headerStyle)),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('Qty', style: headerStyle)),
          ),
          Expanded(
            flex: 3,
            child: Center(child: Text('Price', style: headerStyle)),
          ),
          Expanded(
            flex: 3,
            child: Center(child: Text('Total', style: headerStyle)),
          ),
        ],
      ),
    );
  }

  Widget _buildRows() {
    return Column(children: items.map((item) => _buildRow(item)).toList());
  }

  Widget _buildRow(QuotationItem item) {
    final textStyle = GoogleFonts.openSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF302E2E),
      height: 1.5,
    );

    final totalStyle = GoogleFonts.openSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF302E2E),
      height: 1.5,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFD3D3D3)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(item.product, style: textStyle)),
          Expanded(flex: 2, child: Text(item.description, style: textStyle)),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(item.quantity.toString(), style: textStyle),
            ),
          ),
          Expanded(flex: 3, child: Text(item.unitPrice, style: textStyle)),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(item.total, style: totalStyle),
            ),
          ),
        ],
      ),
    );
  }
}
