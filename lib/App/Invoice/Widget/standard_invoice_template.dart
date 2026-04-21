import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Invoice/Model/invoiceModel.dart';

class StandardInvoiceTheme {
  final Color accent;
  final Color accentSoft;
  final Color pageBackground;
  final Color panelBackground;
  final Color tableHeaderBackground;
  final Color textPrimary;
  final Color textMuted;
  final Color border;

  const StandardInvoiceTheme({
    required this.accent,
    required this.accentSoft,
    required this.pageBackground,
    required this.panelBackground,
    required this.tableHeaderBackground,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
  });
}

class StandardInvoiceTemplate extends StatefulWidget {
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
  final List<InvoiceDisplayItem> items;
  final double grandTotal;
  final double amountPaid;
  final double balance;
  final bool isExistingInvoice;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String bankCode;
  final StandardInvoiceTheme theme;

  const StandardInvoiceTemplate({
    super.key,
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
    this.bankName = "Your Bank",
    this.accountName = "Account Name",
    this.accountNumber = "0000000000",
    this.bankCode = "000000",
    required this.theme,
  });

  @override
  State<StandardInvoiceTemplate> createState() =>
      _StandardInvoiceTemplateState();
}

class _StandardInvoiceTemplateState extends State<StandardInvoiceTemplate> {
  String companyName = '';
  String companyAddress = '';
  String companyPhone = '';
  String companyEmail = '';
  bool isLoading = true;

  final NumberFormat _money = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );
  final DateFormat _date = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    var resolvedAddress = prefs.getString('companyAddress') ?? '';
    final activeCompanyString = prefs.getString('activeCompany');
    if (activeCompanyString != null && activeCompanyString.isNotEmpty) {
      try {
        final activeCompany = jsonDecode(activeCompanyString);
        if (activeCompany is Map<String, dynamic>) {
          final companyAddressValue =
              (activeCompany['address'] ??
                      activeCompany['companyAddress'] ??
                      '')
                  .toString()
                  .trim();
          if (companyAddressValue.isNotEmpty) {
            resolvedAddress = companyAddressValue;
          }
        }
      } catch (_) {}
    }

    setState(() {
      companyName = prefs.getString('companyName') ?? 'Your Company';
      companyEmail = prefs.getString('companyEmail') ?? '';
      companyPhone = prefs.getString('companyPhoneNumber') ?? '';
      companyAddress = resolvedAddress;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: widget.theme.accent),
      );
    }

    final computedGrandTotal = widget.items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final grandTotal = computedGrandTotal > 0
        ? computedGrandTotal
        : widget.grandTotal;
    final status = (widget.paymentStatus ?? '').trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final compact = availableWidth < 700;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Container(
              width: double.infinity,
              color: widget.theme.pageBackground,
              padding: EdgeInsets.all(compact ? 16 : 28),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 18 : 28),
                decoration: BoxDecoration(
                  color: widget.theme.panelBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: widget.theme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(compact: compact, status: status),
                    SizedBox(height: compact ? 20 : 28),
                    _buildInfoGrid(compact: compact),
                    if (widget.description.trim().isNotEmpty) ...[
                      SizedBox(height: compact ? 18 : 24),
                      _buildDescriptionCard(),
                    ],
                    SizedBox(height: compact ? 20 : 28),
                    _buildItemsTable(compact: compact),
                    SizedBox(height: compact ? 20 : 28),
                    _buildTotalsSection(compact: compact, total: grandTotal),
                    SizedBox(height: compact ? 20 : 28),
                    _buildPaymentSection(compact: compact),
                    SizedBox(height: compact ? 20 : 28),
                    _buildFooter(compact: compact),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatMoney(num? value) => _money.format((value ?? 0).toDouble());

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return _date.format(value);
  }

  List<String> _companyLines() {
    return [
      companyName,
      companyAddress,
      companyPhone,
      companyEmail,
    ].where((line) => line.trim().isNotEmpty).toList();
  }

  List<String> _clientLines() {
    return [
      widget.clientName,
      widget.clientAddress,
      widget.clientBusStop,
      widget.clientPhone,
      widget.clientEmail,
    ].where((line) => line.trim().isNotEmpty).toList();
  }

  Widget _buildHeader({required bool compact, required String status}) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INVOICE',
          style: TextStyle(
            fontSize: compact ? 28 : 34,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: widget.theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Invoice No. ${widget.invoiceNumber}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.theme.accent,
          ),
        ),
      ],
    );

    final companyBlock = Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        ..._companyLines().map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              line,
              textAlign: compact ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: widget.theme.textMuted,
                fontWeight: line == companyName
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
        ),
        if (status.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildStatusBadge(status),
        ],
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleBlock, const SizedBox(height: 16), companyBlock],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 24),
        Expanded(child: companyBlock),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalized = status.toLowerCase();
    final background = normalized == 'paid'
        ? const Color(0xFFE7F6EC)
        : normalized == 'partial'
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFFFEBEE);
    final textColor = normalized == 'paid'
        ? const Color(0xFF2E7D32)
        : normalized == 'partial'
        ? const Color(0xFFB26A00)
        : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoGrid({required bool compact}) {
    final invoiceMeta = [
      _InfoPair(label: 'Invoice Date', value: _formatDate(widget.invoiceDate)),
      _InfoPair(label: 'Due Date', value: _formatDate(widget.dueDate)),
      _InfoPair(label: 'Quotation No.', value: widget.quotationNumber),
    ];

    final billTo = _buildSectionCard(
      title: 'Bill To',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _clientLines()
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: widget.theme.textPrimary,
                    fontWeight: line == widget.clientName
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );

    final invoiceDetails = _buildSectionCard(
      title: 'Invoice Details',
      child: Column(
        children: invoiceMeta
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.theme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: widget.theme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );

    if (compact) {
      return Column(
        children: [billTo, const SizedBox(height: 14), invoiceDetails],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: billTo),
        const SizedBox(width: 16),
        Expanded(child: invoiceDetails),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return _buildSectionCard(
      title: 'Description',
      child: Text(
        widget.description.trim(),
        style: TextStyle(
          fontSize: 12.5,
          height: 1.5,
          color: widget.theme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildItemsTable({required bool compact}) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: widget.theme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.theme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${item.name}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.theme.textPrimary,
                    ),
                  ),
                  if (item.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.description.trim(),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.theme.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _buildMiniRow('Qty', item.quantity.toString()),
                  _buildMiniRow('Unit Price', _formatMoney(item.unitPrice)),
                  _buildMiniRow(
                    'Amount',
                    _formatMoney(item.totalPrice),
                    bold: true,
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }

    return Table(
      border: TableBorder.all(color: widget.theme.border),
      columnWidths: const {
        0: FlexColumnWidth(0.8),
        1: FlexColumnWidth(3.4),
        2: FlexColumnWidth(1.1),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1.6),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: widget.theme.tableHeaderBackground),
          children: const [
            _TableHeader('No.'),
            _TableHeader('Item Description'),
            _TableHeader('Qty'),
            _TableHeader('Unit Price'),
            _TableHeader('Amount'),
          ],
        ),
        ...widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final description = item.description.trim();
          final details = description.isEmpty
              ? item.name
              : '${item.name}\n$description';
          return TableRow(
            children: [
              _TableCell('${index + 1}', align: TextAlign.center),
              _TableCell(details),
              _TableCell('${item.quantity}', align: TextAlign.center),
              _TableCell(_formatMoney(item.unitPrice), align: TextAlign.right),
              _TableCell(_formatMoney(item.totalPrice), align: TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildMiniRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: widget.theme.textMuted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: widget.theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection({required bool compact, required double total}) {
    final amountDue = widget.balance > 0 ? widget.balance : total;
    final summary = Container(
      width: compact ? double.infinity : 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.border),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', _formatMoney(total)),
          _buildSummaryRow('Amount Paid', _formatMoney(widget.amountPaid)),
          _buildSummaryRow('Balance', _formatMoney(widget.balance)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: widget.theme.border, height: 1),
          ),
          _buildSummaryRow(
            'Total Due',
            _formatMoney(amountDue),
            highlight: true,
          ),
        ],
      ),
    );

    if (compact) return summary;

    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [summary]);
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: highlight ? 13 : 12.5,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                color: widget.theme.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 15 : 12.5,
              fontWeight: FontWeight.w700,
              color: highlight ? widget.theme.accent : widget.theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection({required bool compact}) {
    final paymentCard = _buildSectionCard(
      title: 'Payment Information',
      child: Column(
        children: [
          _buildPaymentRow('Bank Name', widget.bankName),
          _buildPaymentRow('Account Name', widget.accountName),
          _buildPaymentRow('Account Number', widget.accountNumber),
          if (widget.bankCode.trim().isNotEmpty && widget.bankCode != "000000")
            _buildPaymentRow('Bank Code', widget.bankCode),
        ],
      ),
    );

    final noteCard = _buildSectionCard(
      title: 'Notes',
      child: Text(
        'Please make payment on or before the due date. Thank you for your business.',
        style: TextStyle(
          fontSize: 12.5,
          height: 1.5,
          color: widget.theme.textPrimary,
        ),
      ),
    );

    if (compact) {
      return Column(
        children: [paymentCard, const SizedBox(height: 14), noteCard],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: paymentCard),
        const SizedBox(width: 16),
        Expanded(child: noteCard),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: widget.theme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                color: widget.theme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter({required bool compact}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: widget.theme.border)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Authorized Signature',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  companyName,
                  style: TextStyle(fontSize: 12, color: widget.theme.textMuted),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Authorized Signature',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.theme.textPrimary,
                  ),
                ),
                Text(
                  companyName,
                  style: TextStyle(fontSize: 12, color: widget.theme.textMuted),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.theme.accent,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoPair {
  final String label;
  final String value;

  const _InfoPair({required this.label, required this.value});
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF20232A),
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final TextAlign align;

  const _TableCell(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF20232A),
          height: 1.45,
        ),
      ),
    );
  }
}
