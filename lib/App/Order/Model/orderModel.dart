import 'package:wworker/App/Order/Api/OrderService.dart';

class OrderModel {
  final String id;
  final String userId;
  final String? quotationId; // Might be an object or string
  final String orderNumber;
  final String quotationNumber;
  final String clientName;
  final String clientAddress;
  final String nearestBusStop;
  final String phoneNumber;
  final String email;
  final String description;
  final List<Map<String, dynamic>> items; // ← just store them as a list of maps
  final OrderService? service;
  final double discount;
  final double totalCost;
  final double totalSellingPrice;
  final double discountAmount;
  final double totalAmount;
  final double amountPaid;
  final double balance;
  final String currency;
  final String paymentStatus;
  final String status;
  final DateTime orderDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    this.quotationId,
    required this.orderNumber,
    required this.quotationNumber,
    required this.clientName,
    required this.clientAddress,
    required this.nearestBusStop,
    required this.phoneNumber,
    required this.email,
    required this.description,
    required this.items,
    this.service,
    required this.discount,
    required this.totalCost,
    required this.totalSellingPrice,
    required this.discountAmount,
    required this.totalAmount,
    required this.amountPaid,
    required this.balance,
    required this.currency,
    required this.paymentStatus,
    required this.status,
    required this.orderDate,
    this.startDate,
    this.endDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final quotationIdData = json['quotationId'];
    String? quotationId;

    // Handle case where quotationId might be an object
    if (quotationIdData is Map) {
      quotationId = quotationIdData['_id'];
    } else if (quotationIdData is String) {
      quotationId = quotationIdData;
    }

    return OrderModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      quotationId: quotationId,
      orderNumber: json['orderNumber'] ?? '',
      quotationNumber: json['quotationNumber'] ?? '',
      clientName: json['clientName'] ?? '',
      clientAddress: json['clientAddress'] ?? '',
      nearestBusStop: json['nearestBusStop'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      description: json['description'] ?? '',
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      service: json['service'] != null
          ? OrderService.fromJson(json['service'])
          : null,
      discount: (json['discount'] ?? 0).toDouble(),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      totalSellingPrice: (json['totalSellingPrice'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'NGN',
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      status: json['status'] ?? 'pending',
      orderDate: DateTime.parse(json['orderDate']),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'quotationId': quotationId,
      'orderNumber': orderNumber,
      'quotationNumber': quotationNumber,
      'clientName': clientName,
      'clientAddress': clientAddress,
      'nearestBusStop': nearestBusStop,
      'phoneNumber': phoneNumber,
      'email': email,
      'description': description,
      'items': items,
      'service': service?.toJson(),
      'discount': discount,
      'totalCost': totalCost,
      'totalSellingPrice': totalSellingPrice,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'balance': balance,
      'currency': currency,
      'paymentStatus': paymentStatus,
      'status': status,
      'orderDate': orderDate.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class OrderService {
  final String product;
  final int quantity;
  final double discount;
  final double totalPrice;

  OrderService({
    required this.product,
    required this.quantity,
    required this.discount,
    required this.totalPrice,
  });

  factory OrderService.fromJson(Map<String, dynamic> json) {
    return OrderService(
      product: json['product'] ?? '',
      quantity: json['quantity'] ?? 0,
      discount: (json['discount'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product,
      'quantity': quantity,
      'discount': discount,
      'totalPrice': totalPrice,
    };
  }
}
