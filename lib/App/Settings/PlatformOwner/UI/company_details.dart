import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/App/Settings/PlatformOwner/Model/platform_owner_model.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class CompanyDetailsPage extends ConsumerStatefulWidget {
  final String companyId;
  final CompanyInfo? initialCompany;

  const CompanyDetailsPage({
    super.key,
    required this.companyId,
    this.initialCompany,
  });

  @override
  ConsumerState<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends ConsumerState<CompanyDetailsPage> {
  final PlatformOwnerService _service = PlatformOwnerService();

  CompanyUsageDetails? companyDetails;
  bool isLoading = true;
  String? error;
  bool usingEmbeddedFallback = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyDetails();
  }

  Future<void> _loadCompanyDetails() async {
    setState(() {
      isLoading = true;
      error = null;
      usingEmbeddedFallback = false;
    });

    try {
      final result = await _service.getCompanyUsage(widget.companyId);

      if (result['success'] == true) {
        setState(() {
          companyDetails = CompanyUsageDetails.fromJson(result['data']);
          isLoading = false;
        });
      } else {
        if (widget.initialCompany?.isEmbeddedLegacy == true) {
          setState(() {
            companyDetails = null;
            usingEmbeddedFallback = true;
            isLoading = false;
          });
          return;
        }
        setState(() {
          error = result['message'] ?? 'Failed to load company details';
          isLoading = false;
        });
      }
    } catch (e) {
      if (widget.initialCompany?.isEmbeddedLegacy == true) {
        setState(() {
          companyDetails = null;
          usingEmbeddedFallback = true;
          isLoading = false;
        });
        return;
      }
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
        backgroundColor: ColorsApp.bgColor,
        elevation: 0,
        title: const CustomText(title: "Company Details"),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCompanyDetails,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? _buildErrorView()
            : usingEmbeddedFallback && widget.initialCompany != null
            ? _buildEmbeddedDetailsContent(widget.initialCompany!)
            : _buildDetailsContent(),
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
              onPressed: _loadCompanyDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsContent() {
    if (companyDetails == null) return const SizedBox();

    final company = companyDetails!.company;
    final stats = companyDetails!.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Header Card
          _buildCompanyHeader(company),

          const SizedBox(height: 20),

          // Stats Overview
          _buildStatsOverview(stats),

          const SizedBox(height: 20),

          // Revenue Section
          if (stats.revenue != null) ...[
            _buildRevenueSection(stats.revenue!),
            const SizedBox(height: 20),
          ],

          // Recent Orders
          if (companyDetails!.recentOrders.isNotEmpty) ...[
            _buildSectionTitle('Recent Orders'),
            const SizedBox(height: 12),
            _buildRecentOrders(companyDetails!.recentOrders),
          ],
        ],
      ),
    );
  }

  Widget _buildEmbeddedDetailsContent(CompanyInfo company) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompanyHeader(company),
          const SizedBox(height: 20),
          _buildEmbeddedStatsOverview(company.stats),
          const SizedBox(height: 20),
          _buildEmbeddedOrdersOverview(company.stats),
          const SizedBox(height: 20),
          _buildRevenueUnavailableSection(),
          const SizedBox(height: 20),
          _buildSectionTitle('Recent Orders'),
          const SizedBox(height: 12),
          _buildEmptyRecentOrders(),
        ],
      ),
    );
  }

  Widget _buildCompanyHeader(CompanyInfo company) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Company Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ColorsApp.btnColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.business, size: 40, color: ColorsApp.btnColor),
          ),
          const SizedBox(height: 16),

          // Company Name
          Text(
            company.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColorsApp.textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: company.isActive
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              company.isActive ? 'Active' : 'Inactive',
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: company.isActive
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          ),
          if (company.isEmbeddedLegacy) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Legacy embedded company',
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Contact Information
          _buildInfoRow(Icons.email, company.email),
          if (company.phoneNumber != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, company.phoneNumber!),
          ],
          // if (company.address != null) ...[
          //   const SizedBox(height: 8),
          //   _buildInfoRow(Icons.location_on, company.address!),
          // ],

          // Owner Info
          if (company.owner != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Owner: ${company.owner!.fullname}'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview(DetailedProductStats stats) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardAspectRatio = screenWidth < 360 ? 1.0 : 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Statistics Overview'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: cardAspectRatio,
          children: [
            _buildStatCard(
              'Total Products',
              stats.products.total.toString(),
              Icons.inventory_2,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Orders',
              stats.orders.toString(),
              Icons.shopping_cart,
              Colors.green,
            ),
            _buildStatCard(
              'Quotations',
              stats.quotations.toString(),
              Icons.description,
              Colors.orange,
            ),
            _buildStatCard(
              'Users',
              stats.users.toString(),
              Icons.people,
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Product Breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Breakdown',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorsApp.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildProductStat(
                    'Pending',
                    stats.products.pending,
                    Colors.orange,
                  ),
                  _buildProductStat(
                    'Approved',
                    stats.products.approved,
                    Colors.green,
                  ),
                  _buildProductStat(
                    'Rejected',
                    stats.products.rejected,
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmbeddedStatsOverview(CompanyUsageStats? stats) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardAspectRatio = screenWidth < 360 ? 1.0 : 1.2;
    final safeStats =
        stats ??
        CompanyUsageStats(products: 0, orders: 0, quotations: 0, users: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Statistics Overview'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: cardAspectRatio,
          children: [
            _buildStatCard(
              'Total Products',
              safeStats.products.toString(),
              Icons.inventory_2,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Orders',
              safeStats.orders.toString(),
              Icons.shopping_cart,
              Colors.green,
            ),
            _buildStatCard(
              'Quotations',
              safeStats.quotations.toString(),
              Icons.description,
              Colors.orange,
            ),
            _buildStatCard(
              'Users',
              safeStats.users.toString(),
              Icons.people,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmbeddedOrdersOverview(CompanyUsageStats? stats) {
    final totalOrders = stats?.orders ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders Breakdown',
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorsApp.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderBreakdownStat(
                'Total',
                totalOrders.toString(),
                Colors.green,
              ),
              _buildOrderBreakdownStat('Pending', '-', Colors.orange),
              _buildOrderBreakdownStat('Completed', '-', Colors.blue),
              _buildOrderBreakdownStat('Cancelled', '-', Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Only total orders are available for this legacy company until the backend supports embedded company usage details.',
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBreakdownStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.openSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(10),
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
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.openSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueSection(RevenueData revenue) {
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorsApp.btnColor, ColorsApp.btnColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorsApp.btnColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue',
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRevenueItem(
                'Total Revenue',
                currencyFormat.format(revenue.totalRevenue),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildRevenueItem(
                'Total Paid',
                currencyFormat.format(revenue.totalPaid),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueUnavailableSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorsApp.btnColor, ColorsApp.btnColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorsApp.btnColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Revenue data is not available yet for this legacy company.',
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.openSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.openSans(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: ColorsApp.textColor,
      ),
    );
  }

  Widget _buildRecentOrders(List<RecentOrder> orders) {
    return Column(
      children: orders.map((order) => _buildOrderCard(order)).toList(),
    );
  }

  Widget _buildEmptyRecentOrders() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Text(
        'Recent orders are not available yet for this legacy company.',
        style: GoogleFonts.openSans(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildOrderCard(RecentOrder order) {
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy');

    Color statusColor;
    switch (order.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt, color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorsApp.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(order.createdAt),
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(order.totalAmount),
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorsApp.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
