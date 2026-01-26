class DatabaseQuotation {
  final String id;
  final String quotationNumber;
  final String clientName;
  final String clientAddress;
  final String nearestBusStop;
  final String phoneNumber;
  final String email;
  final String description;
  final List<DatabaseQuotationItem> items;
  final DatabaseQuotationService? service;
  final double discount;
  final double costPrice;
  final double overheadCost;
  final double totalCost;
  final double totalSellingPrice;
  final double discountAmount;
  final double finalTotal;
  final String status;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final String? imageUrl;

  DatabaseQuotation({
    required this.id,
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
    required this.costPrice,
    required this.overheadCost,
    required this.totalCost,
    required this.totalSellingPrice,
    required this.discountAmount,
    required this.finalTotal,
    required this.status,
    this.dueDate,
    this.createdAt,
    this.imageUrl,
  });

  factory DatabaseQuotation.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    final items = json['items'];
    if (items is List && items.isNotEmpty) {
      final firstItem = items.first;
      if (firstItem is Map && firstItem['image'] is String) {
        imageUrl = firstItem['image'];
      }
    }

    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((item) => DatabaseQuotationItem.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();

    return DatabaseQuotation(
      id: json['_id'] ?? '',
      quotationNumber: json['quotationNumber'] ?? '',
      clientName: json['clientName'] ?? '',
      clientAddress: json['clientAddress'] ?? '',
      nearestBusStop: json['nearestBusStop'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      description: json['description'] ?? '',
      items: itemsList,
      service: json['service'] is Map<String, dynamic>
          ? DatabaseQuotationService.fromJson(
              json['service'] as Map<String, dynamic>,
            )
          : null,
      discount: (json['discount'] ?? 0).toDouble(),
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      overheadCost: (json['overheadCost'] ?? 0).toDouble(),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      totalSellingPrice: (json['totalSellingPrice'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalTotal: (json['finalTotal'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      imageUrl: imageUrl,
    );
  }
}

class DatabaseBom {
  final String id;
  final String bomNumber;
  final String name;
  final String description;
  final String? productName;
  final String? productImage;
  final List<DatabaseBomMaterial> materials;
  final List<DatabaseBomAdditionalCost> additionalCosts;
  final double materialsCost;
  final double additionalCostsTotal;
  final double totalCost;
  final DateTime? dueDate;
  final DateTime? createdAt;

  DatabaseBom({
    required this.id,
    required this.bomNumber,
    required this.name,
    required this.description,
    this.productName,
    this.productImage,
    required this.materials,
    required this.additionalCosts,
    required this.materialsCost,
    required this.additionalCostsTotal,
    required this.totalCost,
    this.dueDate,
    this.createdAt,
  });

  factory DatabaseBom.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final materials = (json['materials'] as List<dynamic>? ?? [])
        .map((item) => DatabaseBomMaterial.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
    final additionalCosts = (json['additionalCosts'] as List<dynamic>? ?? [])
        .map((item) => DatabaseBomAdditionalCost.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();

    return DatabaseBom(
      id: json['_id'] ?? '',
      bomNumber: json['bomNumber'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      productName: product?['name'],
      productImage: product?['image'],
      materials: materials,
      additionalCosts: additionalCosts,
      materialsCost: (json['materialsCost'] ?? 0).toDouble(),
      additionalCostsTotal: (json['additionalCostsTotal'] ?? 0).toDouble(),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class DatabaseQuotationItem {
  final String woodType;
  final String foamType;
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

  DatabaseQuotationItem({
    required this.woodType,
    required this.foamType,
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

  factory DatabaseQuotationItem.fromJson(Map<String, dynamic> json) {
    return DatabaseQuotationItem(
      woodType: json['woodType'] ?? '',
      foamType: json['foamType'] ?? '',
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      length: (json['length'] ?? 0).toDouble(),
      thickness: (json['thickness'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      squareMeter: (json['squareMeter'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toInt(),
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      image: json['image'] ?? '',
    );
  }
}

class DatabaseQuotationService {
  final String product;
  final int quantity;
  final double discount;
  final double totalPrice;

  DatabaseQuotationService({
    required this.product,
    required this.quantity,
    required this.discount,
    required this.totalPrice,
  });

  factory DatabaseQuotationService.fromJson(Map<String, dynamic> json) {
    return DatabaseQuotationService(
      product: json['product'] ?? '',
      quantity: (json['quantity'] ?? 0).toInt(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
    );
  }
}

class DatabaseBomMaterial {
  final String name;
  final String type;
  final double width;
  final double length;
  final double thickness;
  final String unit;
  final double squareMeter;
  final double price;
  final int quantity;
  final String description;
  final double subtotal;

  DatabaseBomMaterial({
    required this.name,
    required this.type,
    required this.width,
    required this.length,
    required this.thickness,
    required this.unit,
    required this.squareMeter,
    required this.price,
    required this.quantity,
    required this.description,
    required this.subtotal,
  });

  factory DatabaseBomMaterial.fromJson(Map<String, dynamic> json) {
    return DatabaseBomMaterial(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      width: (json['width'] ?? 0).toDouble(),
      length: (json['length'] ?? 0).toDouble(),
      thickness: (json['thickness'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      squareMeter: (json['squareMeter'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toInt(),
      description: json['description'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

class DatabaseBomAdditionalCost {
  final String name;
  final double amount;
  final String description;

  DatabaseBomAdditionalCost({
    required this.name,
    required this.amount,
    required this.description,
  });

  factory DatabaseBomAdditionalCost.fromJson(Map<String, dynamic> json) {
    return DatabaseBomAdditionalCost(
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }
}

class DatabaseClient {
  final String clientName;
  final String phoneNumber;
  final String email;
  final String clientAddress;
  final String nearestBusStop;

  DatabaseClient({
    required this.clientName,
    required this.phoneNumber,
    required this.email,
    required this.clientAddress,
    required this.nearestBusStop,
  });

  factory DatabaseClient.fromJson(Map<String, dynamic> json) {
    return DatabaseClient(
      clientName: json['clientName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      clientAddress: json['clientAddress'] ?? '',
      nearestBusStop: json['nearestBusStop'] ?? '',
    );
  }
}

class DatabaseStaffPermissions {
  final bool quotation;
  final bool sales;
  final bool order;
  final bool invoice;
  final bool products;
  final bool boms;
  final bool database;

  const DatabaseStaffPermissions({
    required this.quotation,
    required this.sales,
    required this.order,
    required this.invoice,
    required this.products,
    required this.boms,
    required this.database,
  });

  factory DatabaseStaffPermissions.fromJson(Map<String, dynamic> json) {
    return DatabaseStaffPermissions(
      quotation: json['quotation'] ?? false,
      sales: json['sales'] ?? false,
      order: json['order'] ?? false,
      invoice: json['invoice'] ?? false,
      products: json['products'] ?? false,
      boms: json['boms'] ?? false,
      database: json['database'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quotation': quotation,
      'sales': sales,
      'order': order,
      'invoice': invoice,
      'products': products,
      'boms': boms,
      'database': database,
    };
  }
}

class DatabaseStaff {
  final String id;
  final String fullname;
  final String email;
  final String phoneNumber;
  final String role;
  final String position;
  final bool accessGranted;
  final DatabaseStaffPermissions permissions;
  final DateTime? joinedAt;

  DatabaseStaff({
    required this.id,
    required this.fullname,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.position,
    required this.accessGranted,
    required this.permissions,
    this.joinedAt,
  });

  factory DatabaseStaff.fromJson(Map<String, dynamic> json) {
    return DatabaseStaff(
      id: json['id'] ?? json['_id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'staff',
      position: json['position'] ?? '',
      accessGranted: json['accessGranted'] ?? true,
      permissions: DatabaseStaffPermissions.fromJson(
        (json['permissions'] as Map<String, dynamic>? ?? {}),
      ),
      joinedAt:
          json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt']) : null,
    );
  }
}

class DatabaseProduct {
  final String id;
  final String productId;
  final String name;
  final String category;
  final String subCategory;
  final String description;
  final String image;
  final String status;

  DatabaseProduct({
    required this.id,
    required this.productId,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.description,
    required this.image,
    required this.status,
  });

  factory DatabaseProduct.fromJson(Map<String, dynamic> json) {
    return DatabaseProduct(
      id: json['_id'] ?? '',
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class DatabaseMaterial {
  final String id;
  final String name;
  final String category;
  final double pricePerSqm;
  final String pricingUnit;
  final String status;
  final bool isGlobal;
  final double? standardWidth;
  final double? standardLength;
  final String? standardUnit;

  DatabaseMaterial({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerSqm,
    required this.pricingUnit,
    required this.status,
    required this.isGlobal,
    this.standardWidth,
    this.standardLength,
    this.standardUnit,
  });

  factory DatabaseMaterial.fromJson(Map<String, dynamic> json) {
    return DatabaseMaterial(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      pricePerSqm: (json['pricePerSqm'] ?? 0).toDouble(),
      pricingUnit: json['pricingUnit'] ?? '',
      status: json['status'] ?? '',
      isGlobal: json['isGlobal'] ?? false,
      standardWidth: json['standardWidth'] != null
          ? (json['standardWidth'] ?? 0).toDouble()
          : null,
      standardLength: json['standardLength'] != null
          ? (json['standardLength'] ?? 0).toDouble()
          : null,
      standardUnit: json['standardUnit'],
    );
  }
}

class DatabaseInvoice {
  final String id;
  final String invoiceNumber;
  final String quotationId;
  final String quotationNumber;
  final String clientName;
  final String email;
  final List<DatabaseQuotationItem> items;
  final double finalTotal;
  final double amountPaid;
  final double balance;
  final String paymentStatus;
  final String status;
  final DateTime? dueDate;
  final DateTime? createdAt;

  DatabaseInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.quotationId,
    required this.quotationNumber,
    required this.clientName,
    required this.email,
    required this.items,
    required this.finalTotal,
    required this.amountPaid,
    required this.balance,
    required this.paymentStatus,
    required this.status,
    this.dueDate,
    this.createdAt,
  });

  factory DatabaseInvoice.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((item) => DatabaseQuotationItem.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();

    return DatabaseInvoice(
      id: json['_id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      quotationId: json['quotationId'] ?? '',
      quotationNumber: json['quotationNumber'] ?? '',
      clientName: json['clientName'] ?? '',
      email: json['email'] ?? '',
      items: items,
      finalTotal: (json['finalTotal'] ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? '',
      status: json['status'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class DatabaseReceipt {
  final String id;
  final String receiptNumber;
  final String orderId;
  final String orderNumber;
  final String clientName;
  final DateTime? receiptDate;
  final double totalAmount;
  final double amountPaid;
  final double balance;
  final String paymentMethod;
  final String? notes;
  final String? reference;
  final DateTime? createdAt;

  DatabaseReceipt({
    required this.id,
    required this.receiptNumber,
    required this.orderId,
    required this.orderNumber,
    required this.clientName,
    this.receiptDate,
    required this.totalAmount,
    required this.amountPaid,
    required this.balance,
    required this.paymentMethod,
    this.notes,
    this.reference,
    this.createdAt,
  });

  factory DatabaseReceipt.fromJson(Map<String, dynamic> json) {
    return DatabaseReceipt(
      id: json['_id'] ?? '',
      receiptNumber: json['receiptNumber'] ?? '',
      orderId: json['orderId'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      clientName: json['clientName'] ?? '',
      receiptDate:
          json['receiptDate'] != null ? DateTime.tryParse(json['receiptDate']) : null,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      notes: json['notes'],
      reference: json['reference'],
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
