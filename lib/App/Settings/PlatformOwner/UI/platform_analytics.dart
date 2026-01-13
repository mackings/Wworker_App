import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/App/Settings/PlatformOwner/Model/platform_owner_model.dart';
import 'package:wworker/Constant/colors.dart';

class PlatformAnalytics extends ConsumerStatefulWidget {
  const PlatformAnalytics({super.key});

  @override
  ConsumerState<PlatformAnalytics> createState() => _PlatformAnalyticsState();
}

class _PlatformAnalyticsState extends ConsumerState<PlatformAnalytics> {
  final PlatformOwnerService _service = PlatformOwnerService();

  PlatformOverview? overview;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await _service.getPlatformOverview();

      if (result['success'] == true) {
        setState(() {
          overview = PlatformOverview.fromJson(result['data']);
          isLoading = false;
        });
      } else {
        setState(() {
          error = result['message'] ?? 'Failed to load analytics';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        elevation: 0,
        title: Text(
          'Platform Analytics',
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? _buildErrorView()
                : _buildAnalyticsContent(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    if (overview == null) return const SizedBox();

    final numberFormat = NumberFormat.compact();

    // Calculate totals
    int totalProducts = overview!.products.byStatus.fold(0, (sum, item) => sum + item.count) + overview!.products.global;
    int totalOrders = overview!.orders.byStatus.fold(0, (sum, item) => sum + item.count);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Grid
          _buildMetricsGrid(numberFormat, totalProducts, totalOrders),
          const SizedBox(height: 24),

          // Company Stats
          _buildSectionHeader('Company Analytics'),
          const SizedBox(height: 12),
          _buildCompanyStats(),
          const SizedBox(height: 24),

          // Product Stats
          _buildSectionHeader('Product Analytics'),
          const SizedBox(height: 12),
          _buildProductStats(),
          const SizedBox(height: 24),

          // User Stats
          _buildSectionHeader('User Analytics'),
          const SizedBox(height: 12),
          _buildUserStats(),
          const SizedBox(height: 24),

          // Order Stats
          _buildSectionHeader('Order Analytics'),
          const SizedBox(height: 12),
          _buildOrderStats(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(NumberFormat numberFormat, int totalProducts, int totalOrders) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardAspectRatio = screenWidth < 360 ? 1.0 : 1.2;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: cardAspectRatio,
      children: [
        _buildMetricCard(
          'Companies',
          numberFormat.format(overview!.companies.total),
          Icons.business,
          Colors.blue,
        ),
        _buildMetricCard(
          'Products',
          numberFormat.format(totalProducts),
          Icons.inventory_2,
          Colors.orange,
        ),
        _buildMetricCard(
          'Orders',
          numberFormat.format(totalOrders),
          Icons.shopping_cart,
          Colors.green,
        ),
        _buildMetricCard(
          'Users',
          numberFormat.format(overview!.users.total),
          Icons.people,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColorsApp.textColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.openSans(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: ColorsApp.textColor,
      ),
    );
  }

  Widget _buildCompanyStats() {
    int inactive = overview!.companies.total - overview!.companies.active;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Active Companies',
            overview!.companies.active.toString(),
            Colors.green,
            Icons.check_circle,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Inactive Companies',
            inactive.toString(),
            Colors.grey,
            Icons.circle_outlined,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Total Companies',
            overview!.companies.total.toString(),
            Colors.blue,
            Icons.business,
          ),
        ],
      ),
    );
  }

  Widget _buildProductStats() {
    // Get status counts
    int approved = 0;
    int pending = 0;
    int rejected = 0;

    for (var status in overview!.products.byStatus) {
      if (status.id.toLowerCase() == 'approved') {
        approved = status.count;
      } else if (status.id.toLowerCase() == 'pending') {
        pending = status.count;
      } else if (status.id.toLowerCase() == 'rejected') {
        rejected = status.count;
      }
    }

    int total = approved + pending + rejected + overview!.products.global;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Approved Products',
            approved.toString(),
            Colors.green,
            Icons.verified,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Pending Products',
            pending.toString(),
            Colors.orange,
            Icons.pending,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Rejected Products',
            rejected.toString(),
            Colors.red,
            Icons.cancel,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Global Products',
            overview!.products.global.toString(),
            Colors.purple,
            Icons.public,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Total Products',
            total.toString(),
            Colors.blue,
            Icons.inventory_2,
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Platform Owners',
            overview!.users.platformOwners.toString(),
            Colors.purple,
            Icons.admin_panel_settings,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Company Owners',
            overview!.users.companyOwners.toString(),
            Colors.blue,
            Icons.business_center,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Total Users',
            overview!.users.total.toString(),
            Colors.green,
            Icons.people,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: overview!.orders.byStatus.map((status) {
          return Column(
            children: [
              _buildStatRow(
                '${status.id} Orders',
                status.count.toString(),
                _getStatusColor(status.id),
                _getStatusIcon(status.id),
              ),
              if (status != overview!.orders.byStatus.last)
                const Divider(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_cart;
    }
  }

  Widget _buildStatRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: ColorsApp.textColor,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.openSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
