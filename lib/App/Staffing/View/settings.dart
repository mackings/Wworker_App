import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/OverHead/View/AddOverhead.dart';
import 'package:wworker/App/Settings/MaterialUpload/Widgets/selectCategory.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/platform_dashboard_new.dart';
import 'package:wworker/App/Staffing/Widgets/database.dart';
import 'package:wworker/App/Staffing/Widgets/notification.dart';
import 'package:wworker/App/Staffing/Widgets/staffaccess.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  final PlatformOwnerService _platformService = PlatformOwnerService();
  bool isPlatformOwner = false;
  bool isLoadingPlatformStatus = true;

  @override
  void initState() {
    super.initState();
    _checkPlatformOwnerStatus();
  }

  Future<void> _checkPlatformOwnerStatus() async {
    final status = await _platformService.isPlatformOwner();
    setState(() {
      isPlatformOwner = status;
      isLoadingPlatformStatus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorsApp.bgColor,
        elevation: 0,
        title: CustomText(
          title: "Settings",
          titleFontSize: 24,
          titleFontWeight: FontWeight.bold,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Management Section
                _buildSectionTitle('Company Management'),
                const SizedBox(height: 12),

                DatabaseWidget(),

                const SizedBox(height: 12),

                NotificationsWidget(),

                const SizedBox(height: 12),

                StaffAccessWidget(),

                const SizedBox(height: 24),

                // Business Settings Section
                _buildSectionTitle('Business Settings'),
                const SizedBox(height: 12),

                _buildModernSettingCard(
                  title: 'Overhead Cost',
                  subtitle: 'Manage your overhead costs',
                  icon: Icons.account_balance_wallet,
                  iconColor: Colors.green,
                  onTap: () => Nav.push(AddOverheadCostCard()),
                ),

                const SizedBox(height: 12),

                _buildModernSettingCard(
                  title: 'System Settings',
                  subtitle: 'Configure materials and categories',
                  icon: Icons.settings_applications,
                  iconColor: Colors.blue,
                  onTap: () => Nav.push(SelectMaterialCategoryPage()),
                ),

                // Platform Owner Dashboard (only shown for platform owners)
                if (isLoadingPlatformStatus)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (isPlatformOwner) ...[
                  const SizedBox(height: 12),
                  _buildModernSettingCard(
                    title: 'Platform Dashboard',
                    subtitle: 'Manage companies, products & approvals',
                    icon: Icons.admin_panel_settings,
                    iconColor: ColorsApp.btnColor,
                    onTap: () => Nav.push(const PlatformDashboardNew()),
                  ),
                ],

                 const SizedBox(height: 12),



                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.openSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: ColorsApp.textColor.withOpacity(0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildModernSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorsApp.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
