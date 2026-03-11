import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wworker/App/Invoice/Widget/DarkInvoice.dart';
import 'package:wworker/App/Invoice/Widget/elegantInvoice.dart';
import 'package:wworker/App/Invoice/Widget/invoice_bank_prefs.dart';
import 'package:wworker/App/Invoice/Widget/invoice_template_prefs.dart';
import 'package:wworker/App/Invoice/Widget/minimalInvoice.dart';
import 'package:wworker/App/Order/Api/OrderService.dart';
import 'package:wworker/App/Order/Model/orderModel.dart' hide OrderService;

class PaymentReceiptPage extends StatefulWidget {
  final OrderModel order;

  const PaymentReceiptPage({super.key, required this.order});

  @override
  State<PaymentReceiptPage> createState() => _PaymentReceiptPageState();
}

class _PaymentReceiptPageState extends State<PaymentReceiptPage> {
  static const List<String> _templateNames = [
    'Modern Dark',
    'Minimal Clean',
    'Elegant Botanical',
  ];

  late DateTime _receiptDate;
  int _templateIndex = 0;
  bool _isTemplateLoading = true;

  String _bankName = "Your Bank";
  String _accountName = "Account Name";
  String _accountNumber = "0000000000";
  String _bankCode = "000000";

  final OrderService _orderService = OrderService();
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _receiptDate = widget.order.updatedAt;
    _loadReceiptSettings();
  }

  Future<void> _loadReceiptSettings() async {
    await Future.wait([_loadTemplateIndex(), _loadBankDetails()]);
  }

  Future<void> _loadTemplateIndex() async {
    final index = await InvoiceTemplatePrefs.getTemplateIndex();
    if (!mounted) return;
    setState(() {
      _templateIndex = (index >= 0 && index <= 2) ? index : 0;
      _isTemplateLoading = false;
    });
  }

  Future<void> _loadBankDetails() async {
    final details = await InvoiceBankPrefs.getBankDetails();
    if (!mounted) return;
    setState(() {
      _bankName = details["bankName"] ?? _bankName;
      _accountName = details["accountName"] ?? _accountName;
      _accountNumber = details["accountNumber"] ?? _accountNumber;
      _bankCode = details["bankCode"] ?? _bankCode;
    });
  }

  Future<void> _pickReceiptDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receiptDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA16438),
              onPrimary: Colors.white,
              onSurface: Color(0xFF302E2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _receiptDate = picked);
    }
  }

  List<_ReceiptTemplateItem> _receiptItems() {
    return widget.order.items.map(_ReceiptTemplateItem.fromMap).toList();
  }

  String _receiptPaymentStatus() {
    if (widget.order.balance <= 0) return 'Paid';
    if (widget.order.amountPaid > 0) return 'Partially Paid';
    return 'Unpaid';
  }

  Widget _buildTemplateWidget() {
    final items = _receiptItems();
    final safeIndex = (_templateIndex >= 0 && _templateIndex <= 2)
        ? _templateIndex
        : 0;

    final commonArgs = _TemplateArgs(
      clientName: widget.order.clientName,
      clientAddress: widget.order.clientAddress,
      clientBusStop: widget.order.nearestBusStop,
      clientPhone: widget.order.phoneNumber,
      clientEmail: widget.order.email,
      invoiceNumber: 'RCPT-${widget.order.orderNumber}',
      quotationNumber: widget.order.quotationNumber.isNotEmpty
          ? widget.order.quotationNumber
          : widget.order.orderNumber,
      invoiceDate: _receiptDate,
      paymentStatus: _receiptPaymentStatus(),
      description: widget.order.description,
      items: items,
      grandTotal: widget.order.totalAmount,
      amountPaid: widget.order.amountPaid,
      balance: widget.order.balance,
      bankName: _bankName,
      accountName: _accountName,
      accountNumber: _accountNumber,
      bankCode: _bankCode,
    );

    switch (safeIndex) {
      case 1:
        return MinimalInvoiceTemplate(
          key: ValueKey('receipt_template_$safeIndex'),
          clientName: commonArgs.clientName,
          clientAddress: commonArgs.clientAddress,
          clientBusStop: commonArgs.clientBusStop,
          clientPhone: commonArgs.clientPhone,
          clientEmail: commonArgs.clientEmail,
          invoiceNumber: commonArgs.invoiceNumber,
          quotationNumber: commonArgs.quotationNumber,
          invoiceDate: commonArgs.invoiceDate,
          paymentStatus: commonArgs.paymentStatus,
          description: commonArgs.description,
          items: commonArgs.items,
          grandTotal: commonArgs.grandTotal,
          amountPaid: commonArgs.amountPaid,
          balance: commonArgs.balance,
          isExistingInvoice: true,
          bankName: commonArgs.bankName,
          accountName: commonArgs.accountName,
          accountNumber: commonArgs.accountNumber,
          bankCode: commonArgs.bankCode,
        );
      case 2:
        return ElegantInvoiceTemplate(
          key: ValueKey('receipt_template_$safeIndex'),
          clientName: commonArgs.clientName,
          clientAddress: commonArgs.clientAddress,
          clientBusStop: commonArgs.clientBusStop,
          clientPhone: commonArgs.clientPhone,
          clientEmail: commonArgs.clientEmail,
          invoiceNumber: commonArgs.invoiceNumber,
          quotationNumber: commonArgs.quotationNumber,
          invoiceDate: commonArgs.invoiceDate,
          paymentStatus: commonArgs.paymentStatus,
          description: commonArgs.description,
          items: commonArgs.items,
          grandTotal: commonArgs.grandTotal,
          amountPaid: commonArgs.amountPaid,
          balance: commonArgs.balance,
          isExistingInvoice: true,
          bankName: commonArgs.bankName,
          accountName: commonArgs.accountName,
          accountNumber: commonArgs.accountNumber,
          bankCode: commonArgs.bankCode,
        );
      default:
        return ModernInvoiceTemplate(
          key: ValueKey('receipt_template_$safeIndex'),
          clientName: commonArgs.clientName,
          clientAddress: commonArgs.clientAddress,
          clientBusStop: commonArgs.clientBusStop,
          clientPhone: commonArgs.clientPhone,
          clientEmail: commonArgs.clientEmail,
          invoiceNumber: commonArgs.invoiceNumber,
          quotationNumber: commonArgs.quotationNumber,
          invoiceDate: commonArgs.invoiceDate,
          paymentStatus: commonArgs.paymentStatus,
          description: commonArgs.description,
          items: commonArgs.items,
          grandTotal: commonArgs.grandTotal,
          amountPaid: commonArgs.amountPaid,
          balance: commonArgs.balance,
          isExistingInvoice: true,
          bankName: commonArgs.bankName,
          accountName: commonArgs.accountName,
          accountNumber: commonArgs.accountNumber,
          bankCode: commonArgs.bankCode,
        );
    }
  }

  Future<File> _generateTemplatePdf() async {
    final templateWidget = _buildTemplateWidget();
    final imageBytes = await _screenshotController.captureFromWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(1600, 2262),
          devicePixelRatio: 3.0,
        ),
        child: Directionality(
          textDirection: Directionality.of(context),
          child: Material(
            child: SizedBox(width: 1600, height: 2262, child: templateWidget),
          ),
        ),
      ),
      context: context,
      delay: const Duration(milliseconds: 400),
      pixelRatio: 3.0,
    );

    final pdf = pw.Document();
    final image = pw.MemoryImage(imageBytes);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/receipt_${widget.order.orderNumber}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator(color: Color(0xFFA16438))),
      );

      final file = await _generateTemplatePdf();

      if (context.mounted) {
        Navigator.pop(context);
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Receipt #${widget.order.orderNumber}',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendReceipt(BuildContext context) async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = 'cash';
    final reference = _buildPaymentReference();
    bool isSending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Send Receipt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF302E2E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (newValue.text.isEmpty) return newValue;
                          final number = int.parse(newValue.text);
                          final formatted = NumberFormat.decimalPattern()
                              .format(number);
                          return TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                              offset: formatted.length,
                            ),
                          );
                        }),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₦ ',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF7F5F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFA16438),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: paymentMethod,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer'),
                        ),
                        DropdownMenuItem(value: 'pos', child: Text('POS')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => paymentMethod = value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        filled: true,
                        fillColor: const Color(0xFFF7F5F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFA16438),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        prefixIcon: const Icon(Icons.sticky_note_2_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF7F5F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFA16438),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSending
                            ? null
                            : () async {
                                setModalState(() => isSending = true);
                                final amount = double.tryParse(
                                      amountController.text
                                          .replaceAll(',', '')
                                          .trim(),
                                    ) ??
                                    0;
                                final response = await _orderService.addPayment(
                                  orderId: widget.order.id,
                                  amount: amount,
                                  paymentMethod: paymentMethod,
                                  reference: reference,
                                  notes: notesController.text.trim(),
                                  paymentDate: _receiptDate.toIso8601String(),
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response['success'] == true
                                          ? 'Receipt sent successfully'
                                          : (response['message'] ??
                                              'Failed to send receipt'),
                                    ),
                                    backgroundColor: response['success'] == true
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA16438),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isSending
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Send Receipt'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _buildPaymentReference() {
    if (widget.order.boms.isNotEmpty) {
      final name = widget.order.boms.first.name.trim();
      if (name.isNotEmpty) {
        return name;
      }
    }
    if (widget.order.items.isNotEmpty) {
      final itemName = widget.order.items.first['woodType']?.toString() ?? '';
      if (itemName.trim().isNotEmpty) {
        return itemName.trim();
      }
    }
    if (widget.order.quotationNumber.trim().isNotEmpty) {
      return 'Quotation ${widget.order.quotationNumber}';
    }
    return 'Order ${widget.order.orderNumber}';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    final selectedTemplateName = _templateNames[_templateIndex];

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
            icon: const Icon(Icons.share, color: Color(0xFFA16438)),
            onPressed: () => _downloadReceipt(context),
            tooltip: 'Share Receipt',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickReceiptDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event,
                              size: 18,
                              color: Color(0xFFA16438),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateFormat.format(_receiptDate),
                              style: const TextStyle(
                                color: Color(0xFF302E2E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit,
                              size: 16,
                              color: Color(0xFFA16438),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA16438).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFA16438).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      selectedTemplateName,
                      style: const TextStyle(
                        color: Color(0xFFA16438),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isTemplateLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFA16438),
                          ),
                        )
                      : _buildTemplateWidget(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendReceipt(context),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text(
                        'Send Receipt',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA16438),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadReceipt(context),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text(
                        'Share Receipt',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFA16438),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFA16438)),
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
    );
  }
}

class _TemplateArgs {
  final String clientName;
  final String clientAddress;
  final String clientBusStop;
  final String clientPhone;
  final String clientEmail;
  final String invoiceNumber;
  final String quotationNumber;
  final DateTime invoiceDate;
  final String paymentStatus;
  final String description;
  final List<_ReceiptTemplateItem> items;
  final double grandTotal;
  final double amountPaid;
  final double balance;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String bankCode;

  const _TemplateArgs({
    required this.clientName,
    required this.clientAddress,
    required this.clientBusStop,
    required this.clientPhone,
    required this.clientEmail,
    required this.invoiceNumber,
    required this.quotationNumber,
    required this.invoiceDate,
    required this.paymentStatus,
    required this.description,
    required this.items,
    required this.grandTotal,
    required this.amountPaid,
    required this.balance,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.bankCode,
  });
}

class _ReceiptTemplateItem {
  final String? woodType;
  final String? foamType;
  final String? description;
  final double sellingPrice;
  final double quantity;
  final double? width;
  final double? length;
  final double? thickness;
  final String? unit;

  const _ReceiptTemplateItem({
    this.woodType,
    this.foamType,
    this.description,
    required this.sellingPrice,
    required this.quantity,
    this.width,
    this.length,
    this.thickness,
    this.unit,
  });

  factory _ReceiptTemplateItem.fromMap(Map<String, dynamic> item) {
    double? parseNum(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '');
    }

    return _ReceiptTemplateItem(
      woodType: item['woodType']?.toString(),
      foamType: item['foamType']?.toString(),
      description: item['description']?.toString(),
      sellingPrice: parseNum(item['sellingPrice']) ?? 0,
      quantity: parseNum(item['quantity']) ?? 0,
      width: parseNum(item['width']),
      length: parseNum(item['length']),
      thickness: parseNum(item['thickness']),
      unit: item['unit']?.toString(),
    );
  }
}
