import 'package:flutter/material.dart';
import 'package:wworker/App/Invoice/Model/invoiceModel.dart';

class InvoiceDetailPage extends StatelessWidget {
  final InvoiceModel invoice;
  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(invoice.invoiceNumber)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Client: ${invoice.clientName}"),
            Text("Email: ${invoice.email}"),
            Text("Phone: ${invoice.phoneNumber}"),
            Text("Amount Paid: ₦${invoice.amountPaid}"),
            Text("Balance: ₦${invoice.balance}"),
            Text("Status: ${invoice.paymentStatus}"),
            Text("Due Date: ${invoice.dueDate != null ? invoice.dueDate.toString() : 'N/A'}"),
            const SizedBox(height: 20),
            Text(invoice.notes ?? ''),
          ],
        ),
      ),
    );
  }
}
