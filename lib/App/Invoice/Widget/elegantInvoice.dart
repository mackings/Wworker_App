// invoice_template_elegant.dart
import 'package:flutter/material.dart';

class ElegantInvoiceTemplate extends StatelessWidget {
  final String companyName;
  final String companyAddress;
  final String companyBusStop;
  final String companyPhone;
  final String companyEmail;
  final String clientName;
  final String clientAddress;
  final String clientBusStop;
  final String clientPhone;
  final String clientEmail;
  final String invoiceNumber;
  final String quotationNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String? paymentStatus;
  final String description;
  final List<dynamic> items;
  final double grandTotal;
  final double amountPaid;
  final double balance;
  final bool isExistingInvoice;

  const ElegantInvoiceTemplate({
    super.key,
    required this.companyName,
    required this.companyAddress,
    required this.companyBusStop,
    required this.companyPhone,
    required this.companyEmail,
    required this.clientName,
    required this.clientAddress,
    required this.clientBusStop,
    required this.clientPhone,
    required this.clientEmail,
    required this.invoiceNumber,
    required this.quotationNumber,
    required this.invoiceDate,
    this.dueDate,
    this.paymentStatus,
    required this.description,
    required this.items,
    required this.grandTotal,
    this.amountPaid = 0,
    this.balance = 0,
    this.isExistingInvoice = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFFAF8F5),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildClientInfo(),
            const SizedBox(height: 24),
            if (description.isNotEmpty) ...[
              _buildDescription(),
              const SizedBox(height: 24),
            ],
            _buildItemsTable(),
            const SizedBox(height: 24),
            _buildFinancialSummary(),
            const SizedBox(height: 32),
            _buildFooter(),
            const SizedBox(height: 24),
            _buildBotanicalDecoration(),
            const SizedBox(height: 40), // Extra padding at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INVOICE',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w300,
                color: Color(0xFF6B7C6E),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Invoice To :',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              clientName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(clientPhone, style: const TextStyle(fontSize: 12)),
            Text(clientEmail, style: const TextStyle(fontSize: 12)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8B9D8A), width: 2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.eco,
                color: Color(0xFF8B9D8A),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Invoice No :', invoiceNumber),
            _buildDetailRow('Date :', _formatDate(invoiceDate)),
            _buildDetailRow('Quotation No.', quotationNumber),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clientAddress,
            style: const TextStyle(fontSize: 13),
          ),
          if (clientBusStop.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Near: $clientBusStop',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B9D8A).withOpacity(0.3),
        ),
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: Color(0xFF4A5C4C),
        ),
      ),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF8B9D8A), width: 1),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'SERVICE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFF6B7C6E),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'QTY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFF6B7C6E),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'PRICE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFF6B7C6E),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'TOTAL',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFF6B7C6E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFE8E8E8)),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.woodType ?? item.foamType ?? 'Material',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.description?.isNotEmpty ?? false)
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '₦${item.sellingPrice.toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₦${(item.sellingPrice * item.quantity).toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(width: 0),
              Expanded(
                child: Column(
                  children: [
                    _buildSummaryRow('Sub-total:', grandTotal),
                    _buildSummaryRow('Tax:', 0.0),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SERVICE:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A5C4C),
                            ),
                          ),
                          Text(
                            '₦${grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A5C4C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExistingInvoice) ...[
                      const SizedBox(height: 16),
                      _buildSummaryRow('Amount Paid:', amountPaid, isGreen: true),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Balance:', balance, isBold: true),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value,
      {bool isBold = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₦${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isGreen ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E8).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment to :',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bank name    : $companyName Bank',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const Text(
                      'Bank code    : 12345678999',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 12),
                      const SizedBox(width: 6),
                      Text(companyPhone, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 12),
                      const SizedBox(width: 6),
                      Text(companyEmail, style: const TextStyle(fontSize: 10)),
                    ]
                    ),
                  
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.language, size: 12),
                      const SizedBox(width: 6),
                      Text(companyAddress, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotanicalDecoration() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Opacity(
        opacity: 0.3,
        child: Icon(
          Icons.eco,
          size: 80,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}