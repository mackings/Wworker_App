// Complete Sales Analytics Response Model
class SalesAnalyticsResponse {
  final bool success;
  final String message;
  final SalesAnalyticsData data;

  SalesAnalyticsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SalesAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return SalesAnalyticsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: SalesAnalyticsData.fromJson(json['data'] ?? {}),
    );
  }
}

class SalesAnalyticsData {
  final String period;
  final SalesMetrics metrics;
  final List<SalesPerformanceData> salesPerformance;
  final List<ProjectTypeData> projectTypes;
  final PerformanceSummary performanceSummary;
  final List<PaymentDistribution> paymentDistribution;
  final List<TopCustomer> topCustomers;

  SalesAnalyticsData({
    required this.period,
    required this.metrics,
    required this.salesPerformance,
    required this.projectTypes,
    required this.performanceSummary,
    required this.paymentDistribution,
    required this.topCustomers,
  });

  factory SalesAnalyticsData.fromJson(Map<String, dynamic> json) {
    return SalesAnalyticsData(
      period: json['period'] ?? '',
      metrics: SalesMetrics.fromJson(json['metrics'] ?? {}),
      salesPerformance:
          (json['salesPerformance'] as List<dynamic>?)
              ?.map((e) => SalesPerformanceData.fromJson(e))
              .toList() ??
          [],
      projectTypes:
          (json['projectTypes'] as List<dynamic>?)
              ?.map((e) => ProjectTypeData.fromJson(e))
              .toList() ??
          [],
      performanceSummary: PerformanceSummary.fromJson(
        json['performanceSummary'] ?? {},
      ),
      paymentDistribution:
          (json['paymentDistribution'] as List<dynamic>?)
              ?.map((e) => PaymentDistribution.fromJson(e))
              .toList() ??
          [],
      topCustomers:
          (json['topCustomers'] as List<dynamic>?)
              ?.map((e) => TopCustomer.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SalesMetrics {
  final RevenueMetric revenue;
  final ProjectsMetric projects;
  final CustomersMetric customers;
  final ProfitMetric profit;

  SalesMetrics({
    required this.revenue,
    required this.projects,
    required this.customers,
    required this.profit,
  });

  factory SalesMetrics.fromJson(Map<String, dynamic> json) {
    return SalesMetrics(
      revenue: RevenueMetric.fromJson(json['revenue'] ?? {}),
      projects: ProjectsMetric.fromJson(json['projects'] ?? {}),
      customers: CustomersMetric.fromJson(json['customers'] ?? {}),
      profit: ProfitMetric.fromJson(json['profit'] ?? {}),
    );
  }
}

class RevenueMetric {
  final double total;
  final double change;

  RevenueMetric({required this.total, required this.change});

  factory RevenueMetric.fromJson(Map<String, dynamic> json) {
    return RevenueMetric(
      total: (json['total'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
    );
  }
}

class ProjectsMetric {
  final int total;
  final double change;

  ProjectsMetric({required this.total, required this.change});

  factory ProjectsMetric.fromJson(Map<String, dynamic> json) {
    return ProjectsMetric(
      total: json['total'] ?? 0,
      change: (json['change'] ?? 0).toDouble(),
    );
  }
}

class CustomersMetric {
  final int total;
  final double avgRevenuePerCustomer;

  CustomersMetric({required this.total, required this.avgRevenuePerCustomer});

  factory CustomersMetric.fromJson(Map<String, dynamic> json) {
    return CustomersMetric(
      total: json['total'] ?? 0,
      avgRevenuePerCustomer: (json['avgRevenuePerCustomer'] ?? 0).toDouble(),
    );
  }
}

class ProfitMetric {
  final double total;
  final double margin;

  ProfitMetric({required this.total, required this.margin});

  factory ProfitMetric.fromJson(Map<String, dynamic> json) {
    return ProfitMetric(
      total: (json['total'] ?? 0).toDouble(),
      margin: (json['margin'] ?? 0).toDouble(),
    );
  }
}

class SalesPerformanceData {
  final String period;
  final double revenue;
  final int orders;

  SalesPerformanceData({
    required this.period,
    required this.revenue,
    required this.orders,
  });

  factory SalesPerformanceData.fromJson(Map<String, dynamic> json) {
    return SalesPerformanceData(
      period: json['period']?.toString() ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      orders: json['orders'] ?? 0,
    );
  }
}

class ProjectTypeData {
  final String type;
  final int count;
  final double revenue;
  final double percentage;

  ProjectTypeData({
    required this.type,
    required this.count,
    required this.revenue,
    required this.percentage,
  });

  factory ProjectTypeData.fromJson(Map<String, dynamic> json) {
    return ProjectTypeData(
      type: json['type'] ?? 'Unknown',
      count: json['count'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class PerformanceSummary {
  final double averageProjectValue;
  final double projectsPerCustomer;
  final double revenuePerCustomer;

  PerformanceSummary({
    required this.averageProjectValue,
    required this.projectsPerCustomer,
    required this.revenuePerCustomer,
  });

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      averageProjectValue: (json['averageProjectValue'] ?? 0).toDouble(),
      projectsPerCustomer: (json['projectsPerCustomer'] ?? 0).toDouble(),
      revenuePerCustomer: (json['revenuePerCustomer'] ?? 0).toDouble(),
    );
  }
}

class PaymentDistribution {
  final String status;
  final int count;
  final double totalAmount;
  final double paidAmount;

  PaymentDistribution({
    required this.status,
    required this.count,
    required this.totalAmount,
    required this.paidAmount,
  });

  factory PaymentDistribution.fromJson(Map<String, dynamic> json) {
    return PaymentDistribution(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
    );
  }
}

class TopCustomer {
  final String name;
  final String email;
  final String phone;
  final double totalRevenue;
  final int totalOrders;

  TopCustomer({
    required this.name,
    required this.email,
    required this.phone,
    required this.totalRevenue,
    required this.totalOrders,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
    );
  }
}

// Inventory Models
class InventoryResponse {
  final bool success;
  final String message;
  final List<InventoryItem> data;

  InventoryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory InventoryResponse.fromJson(Map<String, dynamic> json) {
    return InventoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => InventoryItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class InventoryItem {
  final String material;
  final int used;

  InventoryItem({required this.material, required this.used});

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      material: json['material'] ?? '',
      used: json['used'] ?? 0,
    );
  }
}
