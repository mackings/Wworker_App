import 'package:flutter/material.dart';
import 'package:wworker/App/Invoice/Model/invoiceModel.dart';
import 'package:wworker/App/Invoice/Widget/standard_invoice_template.dart';

class MinimalInvoiceTemplate extends StatelessWidget {
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

  const MinimalInvoiceTemplate({
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
  });

  @override
  Widget build(BuildContext context) {
    return StandardInvoiceTemplate(
      clientName: clientName,
      clientAddress: clientAddress,
      clientBusStop: clientBusStop,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
      invoiceNumber: invoiceNumber,
      quotationNumber: quotationNumber,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      paymentStatus: paymentStatus,
      description: description,
      items: items,
      grandTotal: grandTotal,
      amountPaid: amountPaid,
      balance: balance,
      isExistingInvoice: isExistingInvoice,
      bankName: bankName,
      accountName: accountName,
      accountNumber: accountNumber,
      bankCode: bankCode,
      theme: const StandardInvoiceTheme(
        accent: Color(0xFF374151),
        accentSoft: Color(0xFFF3F4F6),
        pageBackground: Color(0xFFF8FAFC),
        panelBackground: Colors.white,
        tableHeaderBackground: Color(0xFFF3F4F6),
        textPrimary: Color(0xFF111827),
        textMuted: Color(0xFF6B7280),
        border: Color(0xFFE5E7EB),
      ),
    );
  }
}
