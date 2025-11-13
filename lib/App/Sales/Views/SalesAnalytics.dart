// sales_analytics_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Sales/Api/SalesService.dart';
import 'package:wworker/App/Sales/Model/SalesModel.dart';

class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> {
  final SalesService _salesService = SalesService();
  String selectedPeriod = 'daily';
  bool isLoading = false;

  SalesAnalyticsData? analyticsData;
  List<InventoryItem>? inventoryData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Fetch both analytics and inventory data
      final analytics = await _salesService.getSalesAnalytics(
        period: selectedPeriod,
      );
      final inventory = await _salesService.getInventoryStatus();

      setState(() {
        if (analytics != null && analytics.success) {
          analyticsData = analytics.data;
        } else {
          errorMessage =
              analytics?.message ?? 'Failed to fetch sales analytics';
        }

        if (inventory != null && inventory.success) {
          inventoryData = inventory.data;
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching data';
        isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sales")),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            //  _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? _buildErrorWidget()
                  : analyticsData == null
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPeriodSelector(),
                          const SizedBox(height: 20),
                          _buildMetricsGrid(),
                          const SizedBox(height: 24),
                          _buildSalesPerformance(),
                          const SizedBox(height: 24),
                          _buildProjectTypesDistribution(),
                          const SizedBox(height: 24),
                          _buildPerformanceSummary(),
                          const SizedBox(height: 24),
                          _buildInventoryStatus(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'An error occurred',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Sales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          Text(
            'Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['daily', 'weekly', 'monthly', 'yearly'];
    return Row(
      children: periods.map((period) {
        final isSelected = selectedPeriod == period;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => selectedPeriod = period);
              _fetchData();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF5E6D3)
                    : Colors.transparent,
                border: isSelected
                    ? null
                    : Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 2),
                      ),
              ),
              child: Text(
                period[0].toUpperCase() + period.substring(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF8B4513)
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricsGrid() {
    if (analyticsData == null) return const SizedBox.shrink();

    final metrics = analyticsData!.metrics;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          title: 'Revenue',
          value: _formatCurrency(metrics.revenue.total),
          change:
              '${metrics.revenue.change >= 0 ? '+' : ''}${metrics.revenue.change.toStringAsFixed(1)}%',
          isPositive: metrics.revenue.change >= 0,
          icon: Icons.currency_exchange,
          iconColor: const Color(0xFF8B4513),
        ),
        _buildMetricCard(
          title: 'Projects',
          value: '${metrics.projects.total}',
          change:
              '${metrics.projects.change >= 0 ? '+' : ''}${metrics.projects.change.toStringAsFixed(1)}%',
          isPositive: metrics.projects.change >= 0,
          icon: Icons.inventory_2_outlined,
          iconColor: const Color(0xFFD2691E),
        ),
        _buildMetricCard(
          title: 'Customers',
          value: '${metrics.customers.total}',
          subtitle:
              'Avg: ${_formatCurrency(metrics.customers.avgRevenuePerCustomer)}/customer',
          icon: Icons.people_outline,
          iconColor: const Color(0xFFCD853F),
        ),
        _buildMetricCard(
          title: 'Profit',
          value: _formatCurrency(metrics.profit.total),
          subtitle: '${metrics.profit.margin.toStringAsFixed(1)}% margin',
          icon: Icons.trending_up,
          iconColor: Colors.green[700]!,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? change,
    bool? isPositive,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Icon(icon, color: iconColor, size: 32),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (change != null)
                Row(
                  children: [
                    Icon(
                      isPositive! ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPeriodLabel(String period) {
    try {
      // Try parsing as full date (daily: "2025-11-13")
      if (period.split('-').length == 3) {
        final date = DateTime.parse(period);
        return '${date.day}/${date.month}';
      }

      // Monthly format (e.g., "2025-11")
      if (period.split('-').length == 2) {
        final parts = period.split('-');
        final month = int.parse(parts[1]);
        final monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return monthNames[month - 1];
      }

      // Yearly format (e.g., "2025")
      if (period.length == 4) {
        return period;
      }

      // Weekly format (e.g., "2025-W45") or fallback
      return period;
    } catch (e) {
      return period;
    }
  }

  Widget _buildSalesPerformance() {
    if (analyticsData == null || analyticsData!.salesPerformance.isEmpty) {
      return const SizedBox.shrink();
    }

    final performance = analyticsData!.salesPerformance;
    final maxRevenue = performance
        .map((e) => e.revenue)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxRevenue * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        _formatCurrency(rod.toY),
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < performance.length) {
                          final periodStr = performance[value.toInt()].period;
                          return Text(
                            _formatPeriodLabel(periodStr),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCurrency(value),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: performance.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.revenue,
                        color: const Color(0xFFD2B48C),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectTypesDistribution() {
    if (analyticsData == null || analyticsData!.projectTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    final projectTypes = analyticsData!.projectTypes;
    final colors = [
      const Color(0xFFD2B48C),
      const Color(0xFFDEB887),
      const Color(0xFFE6C9A8),
      const Color(0xFFE0B589),
      const Color(0xFF8B4513),
      const Color(0xFF654321),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Types Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: projectTypes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return PieChartSectionData(
                    value: data.percentage,
                    title: '${data.percentage.toStringAsFixed(0)}%',
                    color: colors[index % colors.length],
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(projectTypes, colors),
        ],
      ),
    );
  }

  Widget _buildLegend(List<ProjectTypeData> projectTypes, List<Color> colors) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: projectTypes.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${data.type}  ${data.percentage.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceSummary() {
    if (analyticsData == null) return const SizedBox.shrink();

    final summary = analyticsData!.performanceSummary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            'Average Project Value',
            _formatCurrency(summary.averageProjectValue),
            Icons.calendar_today_outlined,
          ),
          _buildSummaryItem(
            'Project per customer',
            summary.projectsPerCustomer.toStringAsFixed(1),
            Icons.people_outline,
          ),
          _buildSummaryItem(
            'Revenue per customer',
            _formatCurrency(summary.revenuePerCustomer),
            Icons.currency_exchange,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.grey[400], size: 32),
        ],
      ),
    );
  }

  Widget _buildInventoryStatus() {
    if (inventoryData == null || inventoryData!.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalUsed = inventoryData!.fold<int>(
      0,
      (sum, item) => sum + item.used,
    );
    final colors = [Colors.green[400]!, Colors.orange[400]!, Colors.blue[400]!];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Material Usage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...inventoryData!.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final percentage = totalUsed > 0 ? item.used / totalUsed : 0.0;

            return _buildInventoryBar(
              item.material,
              item.used,
              colors[index % colors.length],
              percentage,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInventoryBar(
    String label,
    int count,
    Color color,
    double percentage,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              Text(
                '$count used',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
