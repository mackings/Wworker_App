import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/App/Settings/PlatformOwner/Model/platform_owner_model.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/all_companies.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/all_products_view.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/pending_products.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/pending_materials.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/platform_analytics.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/create_global_product.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/create_global_material.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:intl/intl.dart';




class PlatformDashboardNew extends ConsumerStatefulWidget {
  const PlatformDashboardNew({super.key});

  @override
  ConsumerState<PlatformDashboardNew> createState() => _PlatformDashboardNewState();
}


class _PlatformDashboardNewState extends ConsumerState<PlatformDashboardNew>
    with SingleTickerProviderStateMixin {
  final PlatformOwnerService _service = PlatformOwnerService();

  DashboardStats? stats;
  DashboardActivity? activity;
  bool isLoading = true;
  String? error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }



  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await _service.getDashboardStats();

      if (result['success'] == true) {
        setState(() {
          stats = DashboardStats.fromJson(result['data']['stats']);
          activity = DashboardActivity.fromJson(result['data']['recentActivity']);
          isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          error = result['message'] ?? 'Failed to load dashboard';
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

  int _statsCrossAxisCount(double width) {
    if (width >= 1000) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  double _statsAspectRatio(double width) {
    if (width >= 1000) return 1.6;
    if (width >= 700) return 1.35;
    if (width >= 400) return 1.2;
    return 1.05;
  }

  int _actionsCrossAxisCount(double width) {
    if (width >= 1000) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  double _actionsAspectRatio(double width, int columns) {
    final spacing = 12.0;
    final tileWidth = (width - (columns - 1) * spacing) / columns;
    final tileHeight = width < 360 ? 56.0 : width < 700 ? 62.0 : 70.0;
    return tileWidth / tileHeight;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar
          _buildSliverAppBar(),

          // Content
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: isLoading
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : error != null
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: _buildErrorView(),
                        )
                      : _buildDashboardContent(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: ColorsApp.btnColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColorsApp.btnColor,
                ColorsApp.btnColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Platform Dashboard',
                              style: GoogleFonts.openSans(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your platform',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsApp.btnColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (stats == null) return const SizedBox();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Overview Cards
              _buildStatsOverview(),

              const SizedBox(height: 0),

              // Quick Actions Grid
              _buildQuickActionsGrid(),

            //  const SizedBox(height: 6),

              // Pending Products Section
              if (activity != null && activity!.pendingProducts.isNotEmpty) ...[
                _buildSectionHeader(
                  'Pending Approvals',
                  stats!.products.pending,
                  icon: Icons.pending_actions,
                  onSeeAll: () => Nav.push(const PendingProductsPage()),
                ),
                const SizedBox(height: 2),
                _buildPendingProductsList(),
              const SizedBox(height: 0),
              ],

              // Recent Companies
              if (activity != null && activity!.recentCompanies.isNotEmpty) ...[
                _buildSectionHeader(
                  'Recent Companies',
                  activity!.recentCompanies.length,
                  icon: Icons.business,
                  onSeeAll: () => Nav.push(const AllCompaniesPage()),
                ),
                const SizedBox(height: 2),
                _buildRecentCompaniesList(),
              ],

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final numberFormat = NumberFormat.compact();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _statsCrossAxisCount(width);
        final cardAspectRatio = _statsAspectRatio(width);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   'Platform Overview',
            //   style: GoogleFonts.openSans(
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //     color: ColorsApp.textColor,
            //   ),
            // ),
            // const SizedBox(height: 0),
            GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: cardAspectRatio,
              children: [
                _buildAnimatedStatCard(
                  'Companies',
                  numberFormat.format(stats!.companies.total),
                  '${stats!.companies.active} active',
                  Icons.business_center,
                  const Color(0xFF667EEA),
                  0,
                ),
                _buildAnimatedStatCard(
                  'Products',
                  numberFormat.format(stats!.products.total),
                  '${stats!.products.pending} pending',
                  Icons.inventory_2_outlined,
                  const Color(0xFFF59E0B),
                  100,
                ),
                _buildAnimatedStatCard(
                  'Orders',
                  numberFormat.format(stats!.orders),
                  'Total orders',
                  Icons.shopping_cart_outlined,
                  const Color(0xFF10B981),
                  200,
                ),
                _buildAnimatedStatCard(
                  'Users',
                  numberFormat.format(stats!.users),
                  'Platform users',
                  Icons.people_outline,
                  const Color(0xFF8B5CF6),
                  300,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 24, color: color),
                    ),
                    Icon(
                      Icons.trending_up,
                      color: Colors.grey.shade300,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.openSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ColorsApp.textColor,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _actionsCrossAxisCount(width);
        final aspectRatio = _actionsAspectRatio(width, columns);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.openSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorsApp.textColor,
              ),
            ),
           // const SizedBox(height: 0),
            GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspectRatio,
              children: [
                _buildActionCard(
                  'Review Products',
                  Icons.approval,
                  const Color(0xFFF59E0B),
                  () => Nav.push(const PendingProductsPage()),
                  badge:
                      stats!.products.pending > 0 ? stats!.products.pending : null,
                ),
                _buildActionCard(
                  'All Products',
                  Icons.grid_view,
                  const Color(0xFF667EEA),
                  () => Nav.push(const AllProductsView()),
                ),
                _buildActionCard(
                  'Companies',
                  Icons.business,
                  const Color(0xFF10B981),
                  () => Nav.push(const AllCompaniesPage()),
                ),
                _buildActionCard(
                  'Analytics',
                  Icons.analytics,
                  const Color(0xFF8B5CF6),
                  () => Nav.push(const PlatformAnalytics()),
                ),
                _buildActionCard(
                  'Review Materials',
                  Icons.science,
                  const Color(0xFFEC4899),
                  () => Nav.push(const PendingMaterialsPage()),
                ),
                _buildActionCard(
                  'Create Material',
                  Icons.add_circle,
                  const Color(0xFFEC4899),
                  () => Nav.push(const CreateGlobalMaterial()),
                ),
                _buildActionCard(
                  'Create Product',
                  Icons.add_box,
                  const Color(0xFF06B6D4),
                  () => Nav.push(const CreateGlobalProduct()),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorsApp.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge.toString(),
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count, {
    required IconData icon,
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorsApp.btnColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: ColorsApp.btnColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorsApp.textColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ColorsApp.btnColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ColorsApp.btnColor,
                ),
              ),
            ),
          ],
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Row(
              children: [
                Text(
                  'See All',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorsApp.btnColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 12, color: ColorsApp.btnColor),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPendingProductsList() {
    final products = activity!.pendingProducts.take(3).toList();

    return Column(
      children: products
          .asMap()
          .entries
          .map((entry) => _buildPendingProductCard(entry.value, entry.key))
          .toList(),
    );
  }

  Widget _buildPendingProductCard(PendingProduct product, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => Nav.push(PendingProductsPage(initialProductId: product.id)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.image != null
                    ? Image.network(
                        product.image!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey.shade400),
                          );
                        },
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image, color: Colors.grey.shade400),
                      ),
              ),
              const SizedBox(width: 16),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.openSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ColorsApp.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.business,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.companyName,
                            style: GoogleFonts.openSans(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.category,
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCompaniesList() {
    final companies = activity!.recentCompanies.take(3).toList();

    return Column(
      children: companies
          .asMap()
          .entries
          .map((entry) => _buildCompanyCard(entry.value, entry.key))
          .toList(),
    );
  }

  Widget _buildCompanyCard(CompanyInfo company, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorsApp.btnColor.withOpacity(0.8),
                    ColorsApp.btnColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.business, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: GoogleFonts.openSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ColorsApp.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (company.stats != null) ...[
                        _buildMiniStat(
                            company.stats!.products, Icons.inventory_2),
                        const SizedBox(width: 8),
                        _buildMiniStat(
                            company.stats!.orders, Icons.shopping_cart),
                        const SizedBox(width: 8),
                        _buildMiniStat(company.stats!.users, Icons.people),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: company.isActive
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                company.isActive ? 'Active' : 'Inactive',
                style: GoogleFonts.openSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: company.isActive
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(int value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: GoogleFonts.openSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
