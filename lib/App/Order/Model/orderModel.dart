import 'package:wworker/App/Order/Api/OrderService.dart';
import 'package:wworker/App/Order/Model/StaffModel.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';

class OrderModel {
  final String id;
  final String userId;
  final String? quotationId;
  final String orderNumber;
  final String quotationNumber;
  final String clientName;
  final String clientAddress;
  final String nearestBusStop;
  final String phoneNumber;
  final String email;
  final String description;
  final List<Map<String, dynamic>> items;
  final List<OrderBom> boms;
  final List<String> bomIds;
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
  
  // NEW: Staff Assignment Fields
  final StaffModel? assignedTo;
  final StaffModel? assignedBy;
  final DateTime? assignedAt;
  final String? assignmentNotes;

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
    this.boms = const [],
    this.bomIds = const [],
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
    // NEW fields
    this.assignedTo,
    this.assignedBy,
    this.assignedAt,
    this.assignmentNotes,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final quotationIdData = json['quotationId'];
    String? quotationId;

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
      boms: (json['boms'] as List<dynamic>?)
              ?.map((e) => OrderBom.fromJson(e))
              .toList() ??
          [],
      bomIds: (json['bomIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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
      // NEW: Parse assignment fields
      assignedTo: json['assignedTo'] != null
          ? StaffModel.fromJson(json['assignedTo'])
          : null,
      assignedBy: json['assignedBy'] != null
          ? StaffModel.fromJson(json['assignedBy'])
          : null,
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'])
          : null,
      assignmentNotes: json['assignmentNotes'],
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
      'boms': boms.map((e) => e.toJson()).toList(),
      'bomIds': bomIds,
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
      // NEW fields
      'assignedTo': assignedTo?.toJson(),
      'assignedBy': assignedBy?.toJson(),
      'assignedAt': assignedAt?.toIso8601String(),
      'assignmentNotes': assignmentNotes,
    };
  }
  
  // Helper to check if order is assigned
  bool get isAssigned => assignedTo != null;
}

class OrderBom {
  final String bomId;
  final String bomNumber;
  final String name;
  final String description;
  final OrderBomProduct product;
  final List<OrderBomMaterial> materials;
  final List<OrderBomAdditionalCost> additionalCosts;
  final OrderBomPricing? pricing;
  final double materialsCost;
  final double additionalCostsTotal;
  final double totalCost;
  final ExpectedDuration? expectedDuration;

  OrderBom({
    required this.bomId,
    required this.bomNumber,
    required this.name,
    required this.description,
    required this.product,
    required this.materials,
    required this.additionalCosts,
    this.pricing,
    required this.materialsCost,
    required this.additionalCostsTotal,
    required this.totalCost,
    this.expectedDuration,
  });

  factory OrderBom.fromJson(Map<String, dynamic> json) {
    return OrderBom(
      bomId: json['bomId'] ?? json['_id'] ?? '',
      bomNumber: json['bomNumber'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      product: OrderBomProduct.fromJson(json['product'] ?? {}),
      materials: (json['materials'] as List<dynamic>?)
              ?.map((e) => OrderBomMaterial.fromJson(e))
              .toList() ??
          [],
      additionalCosts: (json['additionalCosts'] as List<dynamic>?)
              ?.map((e) => OrderBomAdditionalCost.fromJson(e))
              .toList() ??
          [],
      pricing: json['pricing'] != null
          ? OrderBomPricing.fromJson(json['pricing'])
          : null,
      materialsCost: (json['materialsCost'] ?? 0).toDouble(),
      additionalCostsTotal: (json['additionalCostsTotal'] ?? 0).toDouble(),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      expectedDuration: json['expectedDuration'] != null
          ? ExpectedDuration.fromJson(json['expectedDuration'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'bomId': bomId,
        'bomNumber': bomNumber,
        'name': name,
        'description': description,
        'product': product.toJson(),
        'materials': materials.map((e) => e.toJson()).toList(),
        'additionalCosts': additionalCosts.map((e) => e.toJson()).toList(),
        if (pricing != null) 'pricing': pricing!.toJson(),
        'materialsCost': materialsCost,
        'additionalCostsTotal': additionalCostsTotal,
        'totalCost': totalCost,
        if (expectedDuration != null) 'expectedDuration': expectedDuration!.toJson(),
      };
}

class OrderBomProduct {
  final String productId;
  final String name;
  final String description;
  final String image;

  OrderBomProduct({
    required this.productId,
    required this.name,
    required this.description,
    required this.image,
  });

  factory OrderBomProduct.fromJson(Map<String, dynamic> json) {
    return OrderBomProduct(
      productId: json['productId']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'description': description,
        'image': image,
      };
}

class OrderBomMaterial {
  final String name;
  final double squareMeter;
  final double price;
  final int quantity;
  final double subtotal;

  OrderBomMaterial({
    required this.name,
    required this.squareMeter,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderBomMaterial.fromJson(Map<String, dynamic> json) {
    return OrderBomMaterial(
      name: json['name'] ?? '',
      squareMeter: (json['squareMeter'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toInt(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'squareMeter': squareMeter,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
      };
}

class OrderBomAdditionalCost {
  final String name;
  final double amount;
  final String description;

  OrderBomAdditionalCost({
    required this.name,
    required this.amount,
    required this.description,
  });

  factory OrderBomAdditionalCost.fromJson(Map<String, dynamic> json) {
    return OrderBomAdditionalCost(
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'description': description,
      };
}

class OrderBomPricing {
  final String pricingMethod;
  final double markupPercentage;
  final double materialsTotal;
  final double additionalTotal;
  final double overheadCost;
  final double costPrice;
  final double sellingPrice;

  OrderBomPricing({
    required this.pricingMethod,
    required this.markupPercentage,
    required this.materialsTotal,
    required this.additionalTotal,
    required this.overheadCost,
    required this.costPrice,
    required this.sellingPrice,
  });

  factory OrderBomPricing.fromJson(Map<String, dynamic> json) {
    return OrderBomPricing(
      pricingMethod: json['pricingMethod'] ?? '',
      markupPercentage: (json['markupPercentage'] ?? 0).toDouble(),
      materialsTotal: (json['materialsTotal'] ?? 0).toDouble(),
      additionalTotal: (json['additionalTotal'] ?? 0).toDouble(),
      overheadCost: (json['overheadCost'] ?? 0).toDouble(),
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'pricingMethod': pricingMethod,
        'markupPercentage': markupPercentage,
        'materialsTotal': materialsTotal,
        'additionalTotal': additionalTotal,
        'overheadCost': overheadCost,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
      };
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
