class InvoiceModel {
  final String id;
  final String clientName;
  final String clientAddress;
  final String phoneNumber;
  final String email;
  final String invoiceNumber;
  final String quotationNumber;
  final double finalTotal;
  final double amountPaid;
  final double balance;
  final String paymentStatus;
  final String status;
  final String? notes;
  final DateTime? dueDate;
  final DateTime createdAt;

  InvoiceModel({
    required this.id,
    required this.clientName,
    required this.clientAddress,
    required this.phoneNumber,
    required this.email,
    required this.invoiceNumber,
    required this.quotationNumber,
    required this.finalTotal,
    required this.amountPaid,
    required this.balance,
    required this.paymentStatus,
    required this.status,
    this.notes,
    this.dueDate,
    required this.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json["_id"] ?? "",
      clientName: json["clientName"] ?? "",
      clientAddress: json["clientAddress"] ?? "",
      phoneNumber: json["phoneNumber"] ?? "",
      email: json["email"] ?? "",
      invoiceNumber: json["invoiceNumber"] ?? "",
      quotationNumber: json["quotationNumber"] ?? "",
      finalTotal: (json["finalTotal"] ?? 0).toDouble(),
      amountPaid: (json["amountPaid"] ?? 0).toDouble(),
      balance: (json["balance"] ?? 0).toDouble(),
      paymentStatus: json["paymentStatus"] ?? "",
      status: json["status"] ?? "",
      notes: json["notes"],
      dueDate: json["dueDate"] != null ? DateTime.parse(json["dueDate"]) : null,
      createdAt: DateTime.parse(json["createdAt"]),
    );
  }
}
