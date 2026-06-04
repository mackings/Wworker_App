import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/App/Settings/PlatformOwner/Model/platform_owner_model.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/all_companies.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/all_products_view.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/pending_materials.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/platform_analytics.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/create_global_product.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/create_global_material.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/material_updates.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:intl/intl.dart';

class PlatformDashboardNew extends ConsumerStatefulWidget {
  const PlatformDashboardNew({super.key});

  @override
  ConsumerState<PlatformDashboardNew> createState() =>
      _PlatformDashboardNewState();
}

class _PlatformDashboardNewState extends ConsumerState<PlatformDashboardNew>
    with SingleTickerProviderStateMixin {
  final PlatformOwnerService _service = PlatformOwnerService();

  DashboardStats? stats;
  DashboardActivity? activity;
  int? companiesTotalOverride;
  int? companiesActiveOverride;
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
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
      final result = await _service.getDashboardStats(recentLimit: 5);
      final companiesResult = await _service.getAllCompanies(limit: 1);

      if (result['success'] == true) {
        final loadedCompanies = companiesResult['success'] == true
            ? (companiesResult['data'] as List?)
                  ?.map((item) => CompanyInfo.fromJson(item))
                  .toList()
            : null;
        final pagination = companiesResult['pagination'];
        final totalCompanies = pagination is Map
            ? pagination['total'] as int?
            : null;

        setState(() {
          stats = DashboardStats.fromJson(result['data']['stats']);
          activity = DashboardActivity.fromJson(
            result['data']['recentActivity'],
          );
          companiesTotalOverride = totalCompanies;
          companiesActiveOverride = loadedCompanies
              ?.where((company) => company.isActive)
              .length;
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
    final tileHeight = width < 360
        ? 56.0
        : width < 700
        ? 62.0
        : 70.0;
    return tileWidth / tileHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: isLoading
              ? SizedBox(
                  height: MediaQuery.of(context).size.height - 120,
                  child: const Center(child: CircularProgressIndicator()),
                )
              : error != null
              ? SizedBox(
                  height: MediaQuery.of(context).size.height - 120,
                  child: _buildErrorView(),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: _buildDashboardContent(),
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8DED6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: Nav.pop,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8DED6)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF211D1A),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ColorsApp.btnColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: ColorsApp.btnColor,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform Dashboard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 19,
                    height: 1.16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF211D1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage approvals, companies, and catalog data.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    height: 1.3,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 14),

            _buildStatsOverview(),

            const SizedBox(height: 14),

            _buildQuickActionsGrid(),

            const SizedBox(height: 14),

            _buildMaterialUpdateSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final numberFormat = NumberFormat.compact();
    final companiesTotal = companiesTotalOverride ?? stats!.companies.total;
    final companiesActive = companiesActiveOverride ?? stats!.companies.active;

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
                  numberFormat.format(companiesTotal),
                  '$companiesActive active',
                  Icons.business_center,
                  const Color(0xFF667EEA),
                  0,
                  onTap: () => Nav.push(const AllCompaniesPage()),
                ),
                _buildAnimatedStatCard(
                  'Products',
                  numberFormat.format(stats!.products.total),
                  '${stats!.products.pending} pending',
                  Icons.inventory_2_outlined,
                  const Color(0xFFF59E0B),
                  100,
                  onTap: () => Nav.push(const AllProductsView()),
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
    int delay, {
    VoidCallback? onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
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
                          onTap == null
                              ? Icons.trending_up
                              : Icons.arrow_forward_ios_rounded,
                          color: Colors.grey.shade300,
                          size: onTap == null ? 20 : 16,
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
                  'Analytics',
                  Icons.analytics,
                  const Color(0xFF8B5CF6),
                  () => Nav.push(const PlatformAnalytics()),
                ),
                _buildActionCard(
                  'Materials',
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

  Widget _buildMaterialUpdateSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0F172A), const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Material Update',
                  style: GoogleFonts.openSans(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Browse materials company by company and update any company\'s material price directly from the platform dashboard.',
            style: GoogleFonts.openSans(
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Nav.push(const MaterialUpdatesPage()),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Open Material Updates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
}
