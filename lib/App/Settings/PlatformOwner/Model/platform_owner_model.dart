// Platform Owner Dashboard Models

class DashboardStats {
  final CompanyStats companies;
  final ProductStats products;
  final int orders;
  final int quotations;
  final int users;

  DashboardStats({
    required this.companies,
    required this.products,
    required this.orders,
    required this.quotations,
    required this.users,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      companies: CompanyStats.fromJson(json['companies'] ?? {}),
      products: ProductStats.fromJson(json['products'] ?? {}),
      orders: json['orders'] ?? 0,
      quotations: json['quotations'] ?? 0,
      users: json['users'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companies': companies.toJson(),
      'products': products.toJson(),
      'orders': orders,
      'quotations': quotations,
      'users': users,
    };
  }
}

class CompanyStats {
  final int total;
  final int active;
  final int inactive;

  CompanyStats({
    required this.total,
    required this.active,
    required this.inactive,
  });

  factory CompanyStats.fromJson(Map<String, dynamic> json) {
    return CompanyStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      inactive: json['inactive'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'active': active,
      'inactive': inactive,
    };
  }
}

class ProductStats {
  final int total;
  final int pending;
  final int global;
  final int companyProducts;

  ProductStats({
    required this.total,
    required this.pending,
    required this.global,
    required this.companyProducts,
  });

  factory ProductStats.fromJson(Map<String, dynamic> json) {
    return ProductStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      global: json['global'] ?? 0,
      companyProducts: json['companyProducts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pending': pending,
      'global': global,
      'companyProducts': companyProducts,
    };
  }
}

class DashboardActivity {
  final List<PendingProduct> pendingProducts;
  final List<CompanyInfo> recentCompanies;

  DashboardActivity({
    required this.pendingProducts,
    required this.recentCompanies,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      pendingProducts: (json['pendingProducts'] as List<dynamic>?)
              ?.map((item) => PendingProduct.fromJson(item))
              .toList() ??
          [],
      recentCompanies: (json['recentCompanies'] as List<dynamic>?)
              ?.map((item) => CompanyInfo.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pendingProducts': pendingProducts.map((p) => p.toJson()).toList(),
      'recentCompanies': recentCompanies.map((c) => c.toJson()).toList(),
    };
  }
}

class PendingProduct {
  final String id;
  final String name;
  final String productId;
  final String category;
  final String? subCategory;
  final String companyName;
  final String status;
  final UserInfo? submittedBy;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final String? image;
  final String? description;
  final List<ApprovalHistory> approvalHistory;
  final String? rejectionReason;
  final int resubmissionCount;

  PendingProduct({
    required this.id,
    required this.name,
    required this.productId,
    required this.category,
    this.subCategory,
    required this.companyName,
    required this.status,
    this.submittedBy,
    this.submittedAt,
    required this.createdAt,
    this.image,
    this.description,
    required this.approvalHistory,
    this.rejectionReason,
    required this.resubmissionCount,
  });

  factory PendingProduct.fromJson(Map<String, dynamic> json) {
    return PendingProduct(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      productId: json['productId'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      companyName: json['companyName'] ?? '',
      status: json['status'] ?? 'pending',
      submittedBy: json['submittedBy'] != null
          ? UserInfo.fromJson(json['submittedBy'])
          : null,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      image: json['image'],
      description: json['description'],
      approvalHistory: (json['approvalHistory'] as List<dynamic>?)
              ?.map((item) => ApprovalHistory.fromJson(item))
              .toList() ??
          [],
      rejectionReason: json['rejectionReason'],
      resubmissionCount: json['resubmissionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'productId': productId,
      'category': category,
      'subCategory': subCategory,
      'companyName': companyName,
      'status': status,
      'submittedBy': submittedBy?.toJson(),
      'submittedAt': submittedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'image': image,
      'description': description,
      'approvalHistory': approvalHistory.map((h) => h.toJson()).toList(),
      'rejectionReason': rejectionReason,
      'resubmissionCount': resubmissionCount,
    };
  }
}

class ApprovalHistory {
  final String action;
  final String performedBy;
  final String performedByName;
  final String? reason;
  final DateTime timestamp;

  ApprovalHistory({
    required this.action,
    required this.performedBy,
    required this.performedByName,
    this.reason,
    required this.timestamp,
  });

  factory ApprovalHistory.fromJson(Map<String, dynamic> json) {
    return ApprovalHistory(
      action: json['action'] ?? '',
      performedBy: json['performedBy'] ?? '',
      performedByName: json['performedByName'] ?? '',
      reason: json['reason'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class CompanyInfo {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? address;
  final bool isActive;
  final UserInfo? owner;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CompanyUsageStats? stats;

  CompanyInfo({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.address,
    required this.isActive,
    this.owner,
    required this.createdAt,
    required this.updatedAt,
    this.stats,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      isActive: json['isActive'] ?? true,
      owner: json['owner'] != null ? UserInfo.fromJson(json['owner']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      stats: json['stats'] != null
          ? CompanyUsageStats.fromJson(json['stats'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'isActive': isActive,
      'owner': owner?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'stats': stats?.toJson(),
    };
  }
}

class CompanyUsageStats {
  final int products;
  final int orders;
  final int quotations;
  final int users;

  CompanyUsageStats({
    required this.products,
    required this.orders,
    required this.quotations,
    required this.users,
  });

  factory CompanyUsageStats.fromJson(Map<String, dynamic> json) {
    return CompanyUsageStats(
      products: json['products'] ?? 0,
      orders: json['orders'] ?? 0,
      quotations: json['quotations'] ?? 0,
      users: json['users'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products,
      'orders': orders,
      'quotations': quotations,
      'users': users,
    };
  }
}

class CompanyUsageDetails {
  final CompanyInfo company;
  final DetailedProductStats stats;
  final List<RecentOrder> recentOrders;

  CompanyUsageDetails({
    required this.company,
    required this.stats,
    required this.recentOrders,
  });

  factory CompanyUsageDetails.fromJson(Map<String, dynamic> json) {
    return CompanyUsageDetails(
      company: CompanyInfo.fromJson(json['company'] ?? {}),
      stats: DetailedProductStats.fromJson(json['stats'] ?? {}),
      recentOrders: (json['recentOrders'] as List<dynamic>?)
              ?.map((item) => RecentOrder.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company.toJson(),
      'stats': stats.toJson(),
      'recentOrders': recentOrders.map((o) => o.toJson()).toList(),
    };
  }
}

class DetailedProductStats {
  final ProductBreakdown products;
  final int orders;
  final int quotations;
  final int users;
  final RevenueData? revenue;

  DetailedProductStats({
    required this.products,
    required this.orders,
    required this.quotations,
    required this.users,
    this.revenue,
  });

  factory DetailedProductStats.fromJson(Map<String, dynamic> json) {
    return DetailedProductStats(
      products: ProductBreakdown.fromJson(json['products'] ?? {}),
      orders: json['orders'] ?? 0,
      quotations: json['quotations'] ?? 0,
      users: json['users'] ?? 0,
      revenue: json['revenue'] != null
          ? RevenueData.fromJson(json['revenue'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.toJson(),
      'orders': orders,
      'quotations': quotations,
      'users': users,
      'revenue': revenue?.toJson(),
    };
  }
}

class ProductBreakdown {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  ProductBreakdown({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  factory ProductBreakdown.fromJson(Map<String, dynamic> json) {
    return ProductBreakdown(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }
}

class RevenueData {
  final double totalRevenue;
  final double totalPaid;

  RevenueData({
    required this.totalRevenue,
    required this.totalPaid,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'totalPaid': totalPaid,
    };
  }
}

class RecentOrder {
  final String id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;

  RecentOrder({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      id: json['_id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderNumber': orderNumber,
      'totalAmount': totalAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class UserInfo {
  final String id;
  final String fullname;
  final String email;
  final String? phoneNumber;

  UserInfo({
    required this.id,
    required this.fullname,
    required this.email,
    this.phoneNumber,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullname': fullname,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'pages': pages,
    };
  }
}

// New Models for Updated API

class PlatformOverview {
  final ProductOverview products;
  final OrderOverview orders;
  final UserOverview users;
  final CompanyOverview companies;
  final QuotationOverview quotations;

  PlatformOverview({
    required this.products,
    required this.orders,
    required this.users,
    required this.companies,
    required this.quotations,
  });

  factory PlatformOverview.fromJson(Map<String, dynamic> json) {
    return PlatformOverview(
      products: ProductOverview.fromJson(json['products'] ?? {}),
      orders: OrderOverview.fromJson(json['orders'] ?? {}),
      users: UserOverview.fromJson(json['users'] ?? {}),
      companies: CompanyOverview.fromJson(json['companies'] ?? {}),
      quotations: QuotationOverview.fromJson(json['quotations'] ?? {}),
    );
  }
}

class ProductOverview {
  final List<StatusCount> byStatus;
  final List<CompanyProductCount> byCompany;
  final int global;

  ProductOverview({
    required this.byStatus,
    required this.byCompany,
    required this.global,
  });

  factory ProductOverview.fromJson(Map<String, dynamic> json) {
    return ProductOverview(
      byStatus: (json['byStatus'] as List<dynamic>?)
              ?.map((item) => StatusCount.fromJson(item))
              .toList() ??
          [],
      byCompany: (json['byCompany'] as List<dynamic>?)
              ?.map((item) => CompanyProductCount.fromJson(item))
              .toList() ??
          [],
      global: json['global'] ?? 0,
    );
  }
}

class OrderOverview {
  final List<OrderStatusCount> byStatus;
  final List<CompanyOrderCount> byCompany;

  OrderOverview({
    required this.byStatus,
    required this.byCompany,
  });

  factory OrderOverview.fromJson(Map<String, dynamic> json) {
    return OrderOverview(
      byStatus: (json['byStatus'] as List<dynamic>?)
              ?.map((item) => OrderStatusCount.fromJson(item))
              .toList() ??
          [],
      byCompany: (json['byCompany'] as List<dynamic>?)
              ?.map((item) => CompanyOrderCount.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class UserOverview {
  final int total;
  final int platformOwners;
  final int companyOwners;

  UserOverview({
    required this.total,
    required this.platformOwners,
    required this.companyOwners,
  });

  factory UserOverview.fromJson(Map<String, dynamic> json) {
    return UserOverview(
      total: json['total'] ?? 0,
      platformOwners: json['platformOwners'] ?? 0,
      companyOwners: json['companyOwners'] ?? 0,
    );
  }
}

class CompanyOverview {
  final int total;
  final int active;

  CompanyOverview({
    required this.total,
    required this.active,
  });

  factory CompanyOverview.fromJson(Map<String, dynamic> json) {
    return CompanyOverview(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
    );
  }
}

class QuotationOverview {
  final int total;

  QuotationOverview({required this.total});

  factory QuotationOverview.fromJson(Map<String, dynamic> json) {
    return QuotationOverview(total: json['total'] ?? 0);
  }
}

class StatusCount {
  final String id;
  final int count;

  StatusCount({required this.id, required this.count});

  factory StatusCount.fromJson(Map<String, dynamic> json) {
    return StatusCount(
      id: json['_id'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class CompanyProductCount {
  final String id;
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  CompanyProductCount({
    required this.id,
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  factory CompanyProductCount.fromJson(Map<String, dynamic> json) {
    return CompanyProductCount(
      id: json['_id'] ?? '',
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
    );
  }
}

class OrderStatusCount {
  final String id;
  final int count;
  final double totalAmount;

  OrderStatusCount({
    required this.id,
    required this.count,
    required this.totalAmount,
  });

  factory OrderStatusCount.fromJson(Map<String, dynamic> json) {
    return OrderStatusCount(
      id: json['_id'] ?? '',
      count: json['count'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }
}

class CompanyOrderCount {
  final String id;
  final int totalOrders;
  final double totalRevenue;
  final double totalPaid;

  CompanyOrderCount({
    required this.id,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalPaid,
  });

  factory CompanyOrderCount.fromJson(Map<String, dynamic> json) {
    return CompanyOrderCount(
      id: json['_id'] ?? '',
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
    );
  }
}

class CompanyProfile {
  final CompanyInfo company;
  final List<StaffMember> staff;
  final CompanyStatistics statistics;
  final CompanyRecentActivity recentActivity;

  CompanyProfile({
    required this.company,
    required this.staff,
    required this.statistics,
    required this.recentActivity,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      company: CompanyInfo.fromJson(json['company'] ?? {}),
      staff: (json['staff'] as List<dynamic>?)
              ?.map((item) => StaffMember.fromJson(item))
              .toList() ??
          [],
      statistics: CompanyStatistics.fromJson(json['statistics'] ?? {}),
      recentActivity: CompanyRecentActivity.fromJson(json['recentActivity'] ?? {}),
    );
  }
}

class StaffMember {
  final String id;
  final String fullname;
  final String email;
  final String? phoneNumber;
  final String role;
  final String? position;
  final bool accessGranted;
  final DateTime? joinedAt;
  final StaffPermissions? permissions;

  StaffMember({
    required this.id,
    required this.fullname,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.position,
    required this.accessGranted,
    this.joinedAt,
    this.permissions,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['_id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: json['role'] ?? '',
      position: json['position'],
      accessGranted: json['accessGranted'] ?? false,
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : null,
      permissions: json['permissions'] != null
          ? StaffPermissions.fromJson(json['permissions'])
          : null,
    );
  }
}

class StaffPermissions {
  final bool quotation;
  final bool sales;
  final bool order;
  final bool database;
  final bool receipts;
  final bool invoice;
  final bool products;
  final bool boms;

  StaffPermissions({
    required this.quotation,
    required this.sales,
    required this.order,
    required this.database,
    required this.receipts,
    required this.invoice,
    required this.products,
    required this.boms,
  });

  factory StaffPermissions.fromJson(Map<String, dynamic> json) {
    return StaffPermissions(
      quotation: json['quotation'] ?? false,
      sales: json['sales'] ?? false,
      order: json['order'] ?? false,
      database: json['database'] ?? false,
      receipts: json['receipts'] ?? false,
      invoice: json['invoice'] ?? false,
      products: json['products'] ?? false,
      boms: json['boms'] ?? false,
    );
  }
}

class CompanyStatistics {
  final CompanyProductStats products;
  final CompanyOrderStats orders;
  final int quotations;
  final int staff;
  final RevenueData? revenue;

  CompanyStatistics({
    required this.products,
    required this.orders,
    required this.quotations,
    required this.staff,
    this.revenue,
  });

  factory CompanyStatistics.fromJson(Map<String, dynamic> json) {
    return CompanyStatistics(
      products: CompanyProductStats.fromJson(json['products'] ?? {}),
      orders: CompanyOrderStats.fromJson(json['orders'] ?? {}),
      quotations: json['quotations'] ?? 0,
      staff: json['staff'] ?? 0,
      revenue: json['revenue'] != null ? RevenueData.fromJson(json['revenue']) : null,
    );
  }
}

class CompanyProductStats {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int globalAvailable;

  CompanyProductStats({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.globalAvailable,
  });

  factory CompanyProductStats.fromJson(Map<String, dynamic> json) {
    return CompanyProductStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
      globalAvailable: json['globalAvailable'] ?? 0,
    );
  }
}

class CompanyOrderStats {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;

  CompanyOrderStats({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
  });

  factory CompanyOrderStats.fromJson(Map<String, dynamic> json) {
    return CompanyOrderStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      inProgress: json['inProgress'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
    );
  }
}

class CompanyRecentActivity {
  final List<PendingProduct> products;
  final List<RecentOrder> orders;

  CompanyRecentActivity({
    required this.products,
    required this.orders,
  });

  factory CompanyRecentActivity.fromJson(Map<String, dynamic> json) {
    return CompanyRecentActivity(
      products: (json['products'] as List<dynamic>?)
              ?.map((item) => PendingProduct.fromJson(item))
              .toList() ??
          [],
      orders: (json['orders'] as List<dynamic>?)
              ?.map((item) => RecentOrder.fromJson(item))
              .toList() ??
          [],
    );
  }
}

// Material Models
class PendingMaterial {
  final String id;
  final String name;
  final String category;
  final String? image;
  final String companyName;
  final String status;
  final bool isGlobal;
  final MaterialSubmitter? submittedBy;
  final String? submittedAt;
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;
  final List<ApprovalHistoryItem> approvalHistory;
  final double? standardWidth;
  final double? standardLength;
  final String? standardUnit;
  final double? pricePerSqm;
  final double? pricePerUnit;
  final String? pricingUnit;
  final List<MaterialType>? types;
  final List<MaterialThickness>? commonThicknesses;
  final List<FoamVariant>? foamVariants;
  final double? wasteThreshold;
  final String? notes;
  final String createdAt;

  PendingMaterial({
    required this.id,
    required this.name,
    required this.category,
    this.image,
    required this.companyName,
    required this.status,
    required this.isGlobal,
    this.submittedBy,
    this.submittedAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.approvalHistory,
    this.standardWidth,
    this.standardLength,
    this.standardUnit,
    this.pricePerSqm,
    this.pricePerUnit,
    this.pricingUnit,
    this.types,
    this.commonThicknesses,
    this.foamVariants,
    this.wasteThreshold,
    this.notes,
    required this.createdAt,
  });

  factory PendingMaterial.fromJson(Map<String, dynamic> json) {
    return PendingMaterial(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      image: json['image'],
      companyName: json['companyName'] ?? '',
      status: json['status'] ?? 'pending',
      isGlobal: json['isGlobal'] ?? false,
      submittedBy: json['submittedBy'] != null
          ? MaterialSubmitter.fromJson(json['submittedBy'])
          : null,
      submittedAt: json['submittedAt'],
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'],
      rejectionReason: json['rejectionReason'],
      approvalHistory: (json['approvalHistory'] as List<dynamic>?)
              ?.map((item) => ApprovalHistoryItem.fromJson(item))
              .toList() ??
          [],
      standardWidth: json['standardWidth']?.toDouble(),
      standardLength: json['standardLength']?.toDouble(),
      standardUnit: json['standardUnit'],
      pricePerSqm: json['pricePerSqm']?.toDouble(),
      pricePerUnit: json['pricePerUnit']?.toDouble(),
      pricingUnit: json['pricingUnit'],
      types: (json['types'] as List<dynamic>?)
          ?.map((item) => MaterialType.fromJson(item))
          .toList(),
      commonThicknesses: (json['commonThicknesses'] as List<dynamic>?)
          ?.map((item) => MaterialThickness.fromJson(item))
          .toList(),
      foamVariants: (json['foamVariants'] as List<dynamic>?)
          ?.map((item) => FoamVariant.fromJson(item))
          .toList(),
      wasteThreshold: json['wasteThreshold']?.toDouble(),
      notes: json['notes'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class MaterialSubmitter {
  final String id;
  final String fullname;
  final String email;

  MaterialSubmitter({
    required this.id,
    required this.fullname,
    required this.email,
  });

  factory MaterialSubmitter.fromJson(Map<String, dynamic> json) {
    return MaterialSubmitter(
      id: json['_id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class ApprovalHistoryItem {
  final String action;
  final String? performedBy;
  final String performedByName;
  final String? reason;
  final String timestamp;

  ApprovalHistoryItem({
    required this.action,
    this.performedBy,
    required this.performedByName,
    this.reason,
    required this.timestamp,
  });

  factory ApprovalHistoryItem.fromJson(Map<String, dynamic> json) {
    return ApprovalHistoryItem(
      action: json['action'] ?? '',
      performedBy: json['performedBy'],
      performedByName: json['performedByName'] ?? '',
      reason: json['reason'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class MaterialType {
  final String name;
  final double pricePerSqm;

  MaterialType({
    required this.name,
    required this.pricePerSqm,
  });

  factory MaterialType.fromJson(Map<String, dynamic> json) {
    return MaterialType(
      name: json['name'] ?? '',
      pricePerSqm: (json['pricePerSqm'] ?? 0).toDouble(),
    );
  }
}

class MaterialThickness {
  final double thickness;
  final String unit;

  MaterialThickness({
    required this.thickness,
    required this.unit,
  });

  factory MaterialThickness.fromJson(Map<String, dynamic> json) {
    return MaterialThickness(
      thickness: (json['thickness'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'mm',
    );
  }
}

class FoamVariant {
  final double thickness;
  final String thicknessUnit;
  final String density;
  final double pricePerSqm;

  FoamVariant({
    required this.thickness,
    required this.thicknessUnit,
    required this.density,
    required this.pricePerSqm,
  });

  factory FoamVariant.fromJson(Map<String, dynamic> json) {
    return FoamVariant(
      thickness: (json['thickness'] ?? 0).toDouble(),
      thicknessUnit: json['thicknessUnit'] ?? 'inches',
      density: json['density'] ?? '',
      pricePerSqm: (json['pricePerSqm'] ?? 0).toDouble(),
    );
  }
}

class MaterialPaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  MaterialPaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory MaterialPaginationInfo.fromJson(Map<String, dynamic> json) {
    return MaterialPaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
    );
  }
}
