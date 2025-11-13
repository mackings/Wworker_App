class InvoiceModel {
  final String id;
  final String userId;
  final String quotationId;
  final String clientName;
  final String clientAddress;
  final String nearestBusStop;
  final String phoneNumber;
  final String email;
  final String description;
  final String invoiceNumber;
  final String quotationNumber;
  final List<InvoiceItem> items;
  final InvoiceService service;
  final double discount;
  final double totalCost;
  final double totalSellingPrice;
  final double discountAmount;
  final double finalTotal;
  final double amountPaid;
  final double balance;
  final String paymentStatus;
  final String status;
  final String? notes;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvoiceModel({
    required this.id,
    required this.userId,
    required this.quotationId,
    required this.clientName,
    required this.clientAddress,
    required this.nearestBusStop,
    required this.phoneNumber,
    required this.email,
    required this.description,
    required this.invoiceNumber,
    required this.quotationNumber,
    required this.items,
    required this.service,
    required this.discount,
    required this.totalCost,
    required this.totalSellingPrice,
    required this.discountAmount,
    required this.finalTotal,
    required this.amountPaid,
    required this.balance,
    required this.paymentStatus,
    required this.status,
    this.notes,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    // Handle quotationId which can be either String or Map
    String quotationId;
    if (json["quotationId"] is String) {
      quotationId = json["quotationId"] ?? "";
    } else if (json["quotationId"] is Map<String, dynamic>) {
      quotationId = json["quotationId"]["_id"] ?? "";
    } else {
      quotationId = "";
    }

    return InvoiceModel(
      id: json["_id"] ?? "",
      userId: json["userId"] ?? "",
      quotationId: quotationId,
      clientName: json["clientName"] ?? "",
      clientAddress: json["clientAddress"] ?? "",
      nearestBusStop: json["nearestBusStop"] ?? "",
      phoneNumber: json["phoneNumber"] ?? "",
      email: json["email"] ?? "",
      description: json["description"] ?? "",
      invoiceNumber: json["invoiceNumber"] ?? "",
      quotationNumber: json["quotationNumber"] ?? "",
      items:
          (json["items"] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromJson(item))
              .toList() ??
          [],
      service: InvoiceService.fromJson(json["service"] ?? {}),
      discount: (json["discount"] ?? 0).toDouble(),
      totalCost: (json["totalCost"] ?? 0).toDouble(),
      totalSellingPrice: (json["totalSellingPrice"] ?? 0).toDouble(),
      discountAmount: (json["discountAmount"] ?? 0).toDouble(),
      finalTotal: (json["finalTotal"] ?? 0).toDouble(),
      amountPaid: (json["amountPaid"] ?? 0).toDouble(),
      balance: (json["balance"] ?? 0).toDouble(),
      paymentStatus: json["paymentStatus"] ?? "",
      status: json["status"] ?? "",
      notes: json["notes"],
      dueDate: json["dueDate"] != null ? DateTime.parse(json["dueDate"]) : null,
      createdAt: DateTime.parse(json["createdAt"]),
      updatedAt: DateTime.parse(json["updatedAt"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "userId": userId,
      "quotationId": quotationId,
      "clientName": clientName,
      "clientAddress": clientAddress,
      "nearestBusStop": nearestBusStop,
      "phoneNumber": phoneNumber,
      "email": email,
      "description": description,
      "invoiceNumber": invoiceNumber,
      "quotationNumber": quotationNumber,
      "items": items.map((item) => item.toJson()).toList(),
      "service": service.toJson(),
      "discount": discount,
      "totalCost": totalCost,
      "totalSellingPrice": totalSellingPrice,
      "discountAmount": discountAmount,
      "finalTotal": finalTotal,
      "amountPaid": amountPaid,
      "balance": balance,
      "paymentStatus": paymentStatus,
      "status": status,
      "notes": notes,
      "dueDate": dueDate?.toIso8601String(),
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };
  }
}

class InvoiceItem {
  final String? woodType;
  final String? foamType;
  final double width;
  final double height;
  final double length;
  final double thickness;
  final String unit;
  final double squareMeter;
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final String description;
  final String image;
  final String id;

  InvoiceItem({
    this.woodType,
    this.foamType,
    required this.width,
    required this.height,
    required this.length,
    required this.thickness,
    required this.unit,
    required this.squareMeter,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.description,
    required this.image,
    required this.id,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      woodType: json["woodType"],
      foamType: json["foamType"],
      width: (json["width"] ?? 0).toDouble(),
      height: (json["height"] ?? 0).toDouble(),
      length: (json["length"] ?? 0).toDouble(),
      thickness: (json["thickness"] ?? 0).toDouble(),
      unit: json["unit"] ?? "",
      squareMeter: (json["squareMeter"] ?? 0).toDouble(),
      quantity: json["quantity"] ?? 0,
      costPrice: (json["costPrice"] ?? 0).toDouble(),
      sellingPrice: (json["sellingPrice"] ?? 0).toDouble(),
      description: json["description"] ?? "",
      image: json["image"] ?? "",
      id: json["_id"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "woodType": woodType,
      "foamType": foamType,
      "width": width,
      "height": height,
      "length": length,
      "thickness": thickness,
      "unit": unit,
      "squareMeter": squareMeter,
      "quantity": quantity,
      "costPrice": costPrice,
      "sellingPrice": sellingPrice,
      "description": description,
      "image": image,
      "_id": id,
    };
  }
}

class InvoiceService {
  final String product;
  final int quantity;
  final double discount;
  final double totalPrice;

  InvoiceService({
    required this.product,
    required this.quantity,
    required this.discount,
    required this.totalPrice,
  });

  factory InvoiceService.fromJson(Map<String, dynamic> json) {
    return InvoiceService(
      product: json["product"] ?? "",
      quantity: json["quantity"] ?? 0,
      discount: (json["discount"] ?? 0).toDouble(),
      totalPrice: (json["totalPrice"] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "product": product,
      "quantity": quantity,
      "discount": discount,
      "totalPrice": totalPrice,
    };
  }
}
