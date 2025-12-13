class QuotationResponse {
  final bool success;
  final List<Quotation> data;
  final Pagination? pagination;

  QuotationResponse({
    required this.success,
    required this.data,
    this.pagination,
  });


  factory QuotationResponse.fromJson(Map<String, dynamic> json) {
    return QuotationResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => Quotation.fromJson(e))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'data': data.map((e) => e.toJson()).toList(),
        'pagination': pagination?.toJson(),
      };
}

class Quotation {
  final String id;
  final String userId;
  final String clientName;
  final String clientAddress;
  final String nearestBusStop;
  final String phoneNumber;
  final String email;
  final String description;
  final List<QuotationItem> items;
  final Service service;
  final ExpectedDuration? expectedDuration;
  final double costPrice;
  final double overheadCost;
  final double discount;
  final double totalCost;
  final double totalSellingPrice;
  final double discountAmount;
  final double finalTotal;
  final String status;
  final String quotationNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quotation({
    required this.id,
    required this.userId,
    required this.clientName,
    required this.clientAddress,
    required this.nearestBusStop,
    required this.phoneNumber,
    required this.email,
    required this.description,
    required this.items,
    required this.service,
    this.expectedDuration,
    required this.costPrice,
    required this.overheadCost,
    required this.discount,
    required this.totalCost,
    required this.totalSellingPrice,
    required this.discountAmount,
    required this.finalTotal,
    required this.status,
    required this.quotationNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      clientName: json['clientName'] ?? '',
      clientAddress: json['clientAddress'] ?? '',
      nearestBusStop: json['nearestBusStop'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      description: json['description'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => QuotationItem.fromJson(e))
              .toList() ??
          [],
      service: Service.fromJson(json['service'] ?? {}),
      expectedDuration: json['expectedDuration'] != null
          ? ExpectedDuration.fromJson(json['expectedDuration'])
          : null,
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      overheadCost: (json['overheadCost'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      totalSellingPrice: (json['totalSellingPrice'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalTotal: (json['finalTotal'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      quotationNumber: json['quotationNumber'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'clientName': clientName,
        'clientAddress': clientAddress,
        'nearestBusStop': nearestBusStop,
        'phoneNumber': phoneNumber,
        'email': email,
        'description': description,
        'items': items.map((e) => e.toJson()).toList(),
        'service': service.toJson(),
        'expectedDuration': expectedDuration?.toJson(),
        'costPrice': costPrice,
        'overheadCost': overheadCost,
        'discount': discount,
        'totalCost': totalCost,
        'totalSellingPrice': totalSellingPrice,
        'discountAmount': discountAmount,
        'finalTotal': finalTotal,
        'status': status,
        'quotationNumber': quotationNumber,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class ExpectedDuration {
  final int? value;
  final String unit; // "Day", "Week", "Month"

  ExpectedDuration({
    this.value,
    required this.unit,
  });

  factory ExpectedDuration.fromJson(Map<String, dynamic> json) {
    return ExpectedDuration(
      value: json['value'],
      unit: json['unit'] ?? 'Day',
    );
  }

  Map<String, dynamic> toJson() => {
        if (value != null) 'value': value,
        'unit': unit,
      };

  @override
  String toString() {
    if (value != null) {
      return '$value $unit${value! > 1 ? 's' : ''}';
    }
    return unit;
  }
}

class Service {
  final String product;
  final int quantity;
  final double discount;
  final double totalPrice;

  Service({
    required this.product,
    required this.quantity,
    required this.discount,
    required this.totalPrice,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      product: json['product'] ?? '',
      quantity: json['quantity'] ?? 0,
      discount: (json['discount'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product,
        'quantity': quantity,
        'discount': discount,
        'totalPrice': totalPrice,
      };
}

class QuotationItem {
  final String id;
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

  QuotationItem({
    required this.id,
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
  });

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      id: json['_id'] ?? '',
      woodType: json['woodType'],
      foamType: json['foamType'],
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      length: (json['length'] ?? 0).toDouble(),
      thickness: (json['thickness'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      squareMeter: (json['squareMeter'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'woodType': woodType,
        'foamType': foamType,
        'width': width,
        'height': height,
        'length': length,
        'thickness': thickness,
        'unit': unit,
        'squareMeter': squareMeter,
        'quantity': quantity,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'description': description,
        'image': image,
      };
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total': total,
        'pages': pages,
      };
}
