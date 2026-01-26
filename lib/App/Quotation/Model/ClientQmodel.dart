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
    final dataField = json['data'];
    List<dynamic> rawList = [];
    Map<String, dynamic>? paginationJson;

    if (dataField is List) {
      rawList = dataField;
    } else if (dataField is Map) {
      if (dataField['data'] is List) {
        rawList = dataField['data'];
      } else if (dataField['quotations'] is List) {
        rawList = dataField['quotations'];
      }
      if (dataField['pagination'] is Map<String, dynamic>) {
        paginationJson = Map<String, dynamic>.from(dataField['pagination']);
      }
    }

    final fallbackPagination =
        json['pagination'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['pagination'])
            : null;

    return QuotationResponse(
      success: json['success'] ?? false,
      data: rawList.map((e) => Quotation.fromJson(e)).toList(),
      pagination: (paginationJson ?? fallbackPagination) != null
          ? Pagination.fromJson(paginationJson ?? fallbackPagination!)
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
  final List<QuotationBom> boms;
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
    this.boms = const [],
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
      boms: _parseBoms(json),
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
        'boms': boms.map((e) => e.toJson()).toList(),
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

List<QuotationBom> _parseBoms(Map<String, dynamic> json) {
  final raw = json['boms'];
  List<dynamic> list = [];
  if (raw is List) {
    list = raw;
  } else if (raw is Map) {
    if (raw['data'] is List) {
      list = raw['data'];
    } else if (raw['boms'] is List) {
      list = raw['boms'];
    }
  }
  return list.map((e) => QuotationBom.fromJson(e)).toList();
}

class QuotationBom {
  final String bomId;
  final String bomNumber;
  final String name;
  final String description;
  final String? productId;
  final BomProduct product;
  final List<BomMaterial> materials;
  final List<BomAdditionalCost> additionalCosts;
  final BomPricing? pricing;
  final double materialsCost;
  final double additionalCostsTotal;
  final double totalCost;
  final ExpectedDuration? expectedDuration;
  final DateTime? dueDate;

  QuotationBom({
    required this.bomId,
    required this.bomNumber,
    required this.name,
    required this.description,
    this.productId,
    required this.product,
    required this.materials,
    required this.additionalCosts,
    this.pricing,
    required this.materialsCost,
    required this.additionalCostsTotal,
    required this.totalCost,
    this.expectedDuration,
    this.dueDate,
  });

  factory QuotationBom.fromJson(Map<String, dynamic> json) {
    return QuotationBom(
      bomId: json['bomId'] ?? json['_id'] ?? '',
      bomNumber: json['bomNumber'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      productId: json['productId']?.toString(),
      product: BomProduct.fromJson(json['product'] ?? {}),
      materials: (json['materials'] as List<dynamic>?)
              ?.map((e) => BomMaterial.fromJson(e))
              .toList() ??
          [],
      additionalCosts: (json['additionalCosts'] as List<dynamic>?)
              ?.map((e) => BomAdditionalCost.fromJson(e))
              .toList() ??
          [],
      pricing: json['pricing'] != null
          ? BomPricing.fromJson(json['pricing'])
          : null,
      materialsCost: (json['materialsCost'] ?? 0).toDouble(),
      additionalCostsTotal: (json['additionalCostsTotal'] ?? 0).toDouble(),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      expectedDuration: json['expectedDuration'] != null
          ? ExpectedDuration.fromJson(json['expectedDuration'])
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'bomId': bomId,
        'bomNumber': bomNumber,
        'name': name,
        'description': description,
        if (productId != null) 'productId': productId,
        'product': product.toJson(),
        'materials': materials.map((e) => e.toJson()).toList(),
        'additionalCosts': additionalCosts.map((e) => e.toJson()).toList(),
        if (pricing != null) 'pricing': pricing!.toJson(),
        'materialsCost': materialsCost,
        'additionalCostsTotal': additionalCostsTotal,
        'totalCost': totalCost,
        if (expectedDuration != null) 'expectedDuration': expectedDuration!.toJson(),
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      };
}

class BomProduct {
  final String productId;
  final String name;
  final String description;
  final String image;

  BomProduct({
    required this.productId,
    required this.name,
    required this.description,
    required this.image,
  });

  factory BomProduct.fromJson(Map<String, dynamic> json) {
    return BomProduct(
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

class BomMaterial {
  final String name;
  final String? woodType;
  final String? foamType;
  final String? type;
  final double width;
  final double height;
  final double length;
  final double thickness;
  final String unit;
  final double squareMeter;
  final double price;
  final int quantity;
  final double subtotal;

  BomMaterial({
    required this.name,
    this.woodType,
    this.foamType,
    this.type,
    required this.width,
    required this.height,
    required this.length,
    required this.thickness,
    required this.unit,
    required this.squareMeter,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory BomMaterial.fromJson(Map<String, dynamic> json) {
    return BomMaterial(
      name: json['name'] ?? '',
      woodType: json['woodType'],
      foamType: json['foamType'],
      type: json['type'],
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      length: (json['length'] ?? 0).toDouble(),
      thickness: (json['thickness'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      squareMeter: (json['squareMeter'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toInt(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (woodType != null) 'woodType': woodType,
        if (foamType != null) 'foamType': foamType,
        if (type != null) 'type': type,
        'width': width,
        'height': height,
        'length': length,
        'thickness': thickness,
        'unit': unit,
        'squareMeter': squareMeter,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
      };
}

class BomAdditionalCost {
  final String name;
  final double amount;
  final String description;

  BomAdditionalCost({
    required this.name,
    required this.amount,
    required this.description,
  });

  factory BomAdditionalCost.fromJson(Map<String, dynamic> json) {
    return BomAdditionalCost(
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

class BomPricing {
  final String pricingMethod;
  final double markupPercentage;
  final double materialsTotal;
  final double additionalTotal;
  final double overheadCost;
  final double costPrice;
  final double sellingPrice;

  BomPricing({
    required this.pricingMethod,
    required this.markupPercentage,
    required this.materialsTotal,
    required this.additionalTotal,
    required this.overheadCost,
    required this.costPrice,
    required this.sellingPrice,
  });

  factory BomPricing.fromJson(Map<String, dynamic> json) {
    return BomPricing(
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
