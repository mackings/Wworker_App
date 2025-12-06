// invoice_template_minimal.dart
import 'package:flutter/material.dart';

class MinimalInvoiceTemplate extends StatelessWidget {
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

  const MinimalInvoiceTemplate({
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            _buildClientInfo(),
            const SizedBox(height: 32),
            if (description.isNotEmpty) ...[
              _buildDescription(),
              const SizedBox(height: 32),
            ],
            _buildItemsTable(),
            const SizedBox(height: 32),
            _buildFinancialSummary(),
            const SizedBox(height: 48),
            _buildFooter(),
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

            const SizedBox(height: 16),
            Text(companyName, style: const TextStyle(fontSize: 11)),
            Text(companyAddress, style: const TextStyle(fontSize: 11)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Invoice',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w300,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Date :', _formatDate(invoiceDate)),
            _buildInfoRow('Inv No.', invoiceNumber),
            _buildInfoRow('QT No.', quotationNumber),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BILLED TO:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          clientName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(clientAddress, style: const TextStyle(fontSize: 12)),
        Text(clientPhone, style: const TextStyle(fontSize: 12)),
        Text(clientEmail, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          left: BorderSide(color: Colors.grey[800]!, width: 3),
        ),
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildItemsTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[800]!, width: 2),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'RATE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
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
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'AMOUNT',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
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
                      '₦${item.sellingPrice.toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
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
            )),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(width: 150),
            Expanded(
              child: Column(
                children: [
                  _buildSummaryRow('Sub-Total', grandTotal),
                  _buildSummaryRow('Tax (30%)', grandTotal * 0.0),
                  const Divider(height: 24, thickness: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '₦${grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isExistingInvoice) ...[
                    const SizedBox(height: 16),
                    _buildSummaryRow('Amount Paid', amountPaid, isGreen: true),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Balance', balance, isBold: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value,
      {bool isBold = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Info',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bank: First Bank Nigeria',
                    style: TextStyle(fontSize: 11),
                  ),
                  const Text(
                    'Account No: 0123 4567 8901',
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
                    const Icon(Icons.phone, size: 14),
                    const SizedBox(width: 6),
                    Text(companyPhone, style: const TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 14),
                    const SizedBox(width: 6),
                    Text(companyEmail, style: const TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14),
                    const SizedBox(width: 6),
                    Text(companyAddress, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}