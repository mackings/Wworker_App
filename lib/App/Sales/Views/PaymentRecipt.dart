import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:wworker/App/Order/Model/orderModel.dart';



class PaymentReceiptPage extends StatelessWidget {
  final OrderModel order;

  const PaymentReceiptPage({
    super.key,
    required this.order,
  });

  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFA16438)),
        ),
      );

      // Generate PDF
      final pdf = await _generatePdf();

      // Close loading
      Navigator.pop(context);

      // Show print/share dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#A16438'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PAYMENT RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Receipt #${order.orderNumber}',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Payment Date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Payment Date:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    dateFormat.format(order.updatedAt),
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Client Information
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Client Information',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPdfRow('Name:', order.clientName),
                    _buildPdfRow('Email:', order.email),
                    _buildPdfRow('Phone:', order.phoneNumber),
                    _buildPdfRow('Address:', order.clientAddress),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Order Items
              pw.Text(
                'Order Items',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              // Check if items exist
              if (order.items.isNotEmpty)
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F5F5F5'),
                      ),
                      children: [
                        _buildTableCell('Item', isHeader: true),
                        _buildTableCell('Quantity', isHeader: true),
                        _buildTableCell('Total', isHeader: true),
                      ],
                    ),
                    // Items
                    ...order.items.map((item) {
                      // Get the woodType for the item name
                      final name = item['woodType']?.toString() ?? 'N/A';
                      final quantity = item['quantity'] ?? 0;
                      
                      // Get the selling price per unit
                      final pricePerUnit = (item['sellingPrice'] ?? 0.0).toDouble();
                      
                      // Calculate total: quantity × price per unit
                      final total = quantity * pricePerUnit;

                      return pw.TableRow(
                        children: [
                          _buildTableCell(name),
                          _buildTableCell(quantity.toString()),
                          _buildTableCell('₦${_formatNumber(total)}'),
                        ],
                      );
                    }).toList(),
                  ],
                )
              else
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Center(
                    child: pw.Text(
                      'No items found',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey,
                      ),
                    ),
                  ),
                ),
              
              pw.SizedBox(height: 20),

              // Payment Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F9F9F9'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildSummaryRow('Subtotal:', '₦${_formatNumber(order.totalSellingPrice)}'),
                    pw.SizedBox(height: 8),
                    _buildSummaryRow('Discount:', '-₦${_formatNumber(order.discountAmount)}'),
                    pw.Divider(thickness: 2),
                    _buildSummaryRow(
                      'Total Amount:',
                      '₦${_formatNumber(order.totalAmount)}',
                      isBold: true,
                    ),
                    pw.SizedBox(height: 8),
                    _buildSummaryRow('Amount Paid:', '₦${_formatNumber(order.amountPaid)}'),
                    pw.Divider(thickness: 2),
                    _buildSummaryRow(
                      'Balance:',
                      '₦${_formatNumber(order.balance)}',
                      isBold: true,
                      color: PdfColor.fromHex('#A16438'),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###.##');
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Debug: Print order items
    print('Order items count: ${order.items.length}');
    print('Order items: ${order.items}');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "Receipt",
          style: TextStyle(
            color: Color(0xFF302E2E),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFFA16438)),
            onPressed: () => _downloadReceipt(context),
            tooltip: 'Download Receipt',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFA16438),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wood Worker',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Receipt #${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Date:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF302E2E),
                            ),
                          ),
                          Text(
                            '${dateFormat.format(order.updatedAt)} at ${timeFormat.format(order.updatedAt)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF302E2E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Client Information
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Client Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF302E2E),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow('Name:', order.clientName),
                            const SizedBox(height: 8),
                            _buildDetailRow('Email:', order.email),
                            const SizedBox(height: 8),
                            _buildDetailRow('Phone:', order.phoneNumber),
                            const SizedBox(height: 8),
                            _buildDetailRow('Address:', order.clientAddress),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // // Order Items
                      // const Text(
                      //   'Order Items',
                      //   style: TextStyle(
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.bold,
                      //     color: Color(0xFF302E2E),
                      //   ),
                      // ),
                      // const SizedBox(height: 12),
                      
                      // // Check if items exist
                      // if (order.items.isEmpty)
                      //   Container(
                      //     padding: const EdgeInsets.all(40),
                      //     decoration: BoxDecoration(
                      //       border: Border.all(color: Colors.grey[300]!),
                      //       borderRadius: BorderRadius.circular(8),
                      //     ),
                      //     child: Center(
                      //       child: Column(
                      //         children: [
                      //           Icon(Icons.inbox_outlined, 
                      //                size: 48, 
                      //                color: Colors.grey[400]),
                      //           const SizedBox(height: 8),
                      //           Text(
                      //             'No items found',
                      //             style: TextStyle(
                      //               fontSize: 14,
                      //               color: Colors.grey[600],
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   )
                      // else
                      //   Container(
                      //     decoration: BoxDecoration(
                      //       border: Border.all(color: Colors.grey[300]!),
                      //       borderRadius: BorderRadius.circular(8),
                      //     ),
                      //     child: Column(
                      //       children: [
                      //         // Table Header
                      //         Container(
                      //           padding: const EdgeInsets.all(12),
                      //           decoration: BoxDecoration(
                      //             color: Colors.grey[200],
                      //             borderRadius: const BorderRadius.only(
                      //               topLeft: Radius.circular(8),
                      //               topRight: Radius.circular(8),
                      //             ),
                      //           ),
                      //           child: const Row(
                      //             children: [
                      //               Expanded(
                      //                 flex: 4,
                      //                 child: Text(
                      //                   'Item',
                      //                   style: TextStyle(
                      //                     fontWeight: FontWeight.bold,
                      //                     fontSize: 12,
                      //                   ),
                      //                 ),
                      //               ),
                      //               Expanded(
                      //                 flex: 2,
                      //                 child: Text(
                      //                   'Qty',
                      //                   style: TextStyle(
                      //                     fontWeight: FontWeight.bold,
                      //                     fontSize: 12,
                      //                   ),
                      //                   textAlign: TextAlign.center,
                      //                 ),
                      //               ),
                      //               Expanded(
                      //                 flex: 3,
                      //                 child: Text(
                      //                   'Total',
                      //                   style: TextStyle(
                      //                     fontWeight: FontWeight.bold,
                      //                     fontSize: 12,
                      //                   ),
                      //                   textAlign: TextAlign.right,
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //         // Table Items
                      //         ...order.items.asMap().entries.map((entry) {
                      //           final index = entry.key;
                      //           final item = entry.value;
                                
                      //           // Get the woodType for the item name
                      //           final name = item['woodType']?.toString() ?? 'N/A';
                      //           final quantity = item['quantity'] ?? 0;
                                
                      //           // Get the selling price per unit
                      //           final pricePerUnit = (item['sellingPrice'] ?? 0.0).toDouble();
                                
                      //           // Calculate total: quantity × price per unit
                      //           final total = quantity * pricePerUnit;

                      //           return Container(
                      //             padding: const EdgeInsets.all(12),
                      //             decoration: BoxDecoration(
                      //               border: Border(
                      //                 bottom: index < order.items.length - 1
                      //                     ? BorderSide(color: Colors.grey[300]!)
                      //                     : BorderSide.none,
                      //               ),
                      //             ),
                      //             child: Row(
                      //               children: [
                      //                 Expanded(
                      //                   flex: 4,
                      //                   child: Text(
                      //                     name,
                      //                     style: const TextStyle(fontSize: 12),
                      //                   ),
                      //                 ),
                      //                 Expanded(
                      //                   flex: 2,
                      //                   child: Text(
                      //                     quantity.toString(),
                      //                     style: const TextStyle(fontSize: 12),
                      //                     textAlign: TextAlign.center,
                      //                   ),
                      //                 ),
                      //                 Expanded(
                      //                   flex: 3,
                      //                   child: Text(
                      //                     '₦${_formatNumber(total)}',
                      //                     style: const TextStyle(fontSize: 12),
                      //                     textAlign: TextAlign.right,
                      //                   ),
                      //                 ),
                      //               ],
                      //             ),
                      //           );
                      //         }).toList(),
                      //       ],
                      //     ),
                      //   ),
                      
                      // const SizedBox(height: 24),

                      // Payment Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRows(
                              'Subtotal:',
                              '₦${_formatNumber(order.totalSellingPrice)}',
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryRows(
                              'Discount:',
                              '-₦${_formatNumber(order.discountAmount)}',
                            ),
                            const Divider(height: 24, thickness: 2),
                            _buildSummaryRows(
                              'Total Amount:',
                              '₦${_formatNumber(order.totalAmount)}',
                              isBold: true,
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryRows(
                              'Amount Paid:',
                              '₦${_formatNumber(order.amountPaid)}',
                            ),
                            const Divider(height: 24, thickness: 2),
                            _buildSummaryRows(
                              'Balance:',
                              '₦${_formatNumber(order.balance)}',
                              isBold: true,
                              color: const Color(0xFFA16438),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Download Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadReceipt(context),
                          icon: const Icon(Icons.download, size: 20),
                          label: const Text(
                            'Download Receipt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA16438),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF302E2E),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF302E2E),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRows(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? const Color(0xFF302E2E),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? const Color(0xFF302E2E),
          ),
        ),
      ],
    );
  }
}