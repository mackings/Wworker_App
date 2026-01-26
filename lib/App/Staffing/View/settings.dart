import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/OverHead/View/AddOverhead.dart';
import 'package:wworker/App/Settings/MaterialUpload/Widgets/selectCategory.dart';
import 'package:wworker/App/Settings/Api/company_settings_service.dart';
import 'package:wworker/App/Settings/Model/company_settings_model.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/platform_dashboard_new.dart';
import 'package:wworker/App/Settings/View/tawk_live_chat.dart';
import 'package:wworker/App/Staffing/Widgets/database.dart';
import 'package:wworker/App/Staffing/Widgets/notification.dart';
import 'package:wworker/App/Staffing/Widgets/staffaccess.dart';
import 'package:wworker/App/Invoice/View/invoice_template_settings.dart';
import 'package:wworker/App/Auth/Api/AuthService.dart';
import 'package:wworker/App/Auth/View/Signin.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  final PlatformOwnerService _platformService = PlatformOwnerService();
  final CompanySettingsService _settingsService = CompanySettingsService();
  final AuthService _authService = AuthService();
  bool isPlatformOwner = false;
  bool isLoadingPlatformStatus = true;
  bool isLoadingSettings = true;
  bool canEditSettings = false;
  CompanySettings? companySettings;
  String? settingsError;

  @override
  void initState() {
    super.initState();
    _checkPlatformOwnerStatus();
    _loadCompanySettings();
  }

  Future<void> _checkPlatformOwnerStatus() async {
    final status = await _platformService.isPlatformOwner();
    setState(() {
      isPlatformOwner = status;
      isLoadingPlatformStatus = false;
    });
  }

  Future<void> _loadCompanySettings() async {
    setState(() {
      isLoadingSettings = true;
      settingsError = null;
    });

    debugPrint("🔄 Loading company settings...");
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? '';
    canEditSettings = role == 'owner' || role == 'admin';

    final settings = await _settingsService.getSettings();
    if (!mounted) return;

    setState(() {
      companySettings = settings;
      isLoadingSettings = false;
      if (settings == null) {
        settingsError = "Failed to load company settings";
      }
    });
    debugPrint(
      settings == null
          ? "⚠️ Company settings load failed"
          : "✅ Company settings loaded",
    );
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Nav.pushReplacement(const Signin());
  }

  Future<void> _updateSetting({
    required CompanySettings current,
    bool? cloudSyncEnabled,
    bool? autoBackupEnabled,
    NotificationSettings? notifications,
  }) async {
    if (!canEditSettings) return;

    final updatedNotifications = notifications ?? current.notifications;
    final updates = {
      if (cloudSyncEnabled != null) "cloudSyncEnabled": cloudSyncEnabled,
      if (autoBackupEnabled != null) "autoBackupEnabled": autoBackupEnabled,
      if (notifications != null) "notifications": notifications.toJson(),
    };

    setState(() {
      companySettings = CompanySettings(
        id: current.id,
        companyName: current.companyName,
        cloudSyncEnabled: cloudSyncEnabled ?? current.cloudSyncEnabled,
        autoBackupEnabled: autoBackupEnabled ?? current.autoBackupEnabled,
        notifications: updatedNotifications,
      );
    });

    debugPrint("🔄 Updating company settings: $updates");
    final success = await _settingsService.updateSettings(updates);
    if (!mounted) return;

    if (!success) {
      setState(() {
        companySettings = current;
      });
      debugPrint("❌ Settings update failed");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update settings"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      debugPrint("✅ Settings update succeeded");
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideEnabled = ref.watch(guideProvider);
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
        actions: const [
          GuideHelpIcon(
            title: "Settings Help",
            message:
                "Use Settings to configure your company, staff access, and system tools. "
                "Turn on Guided Help here to reveal step-by-step tips in key sections "
                "(Quotations, Orders, BOMs, Sales). Turn it off to hide the icons.",
          ),
        ],
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

               // DatabaseWidget(),

                const SizedBox(height: 12),

                //NotificationsWidget(),

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
                  title: 'Material Upload',
                  subtitle: 'Configure materials and categories',
                  icon: Icons.settings_applications,
                  iconColor: Colors.blue,
                  onTap: () => Nav.push(SelectMaterialCategoryPage()),
                ),

                const SizedBox(height: 12),

                _buildModernSettingCard(
                  title: 'Invoice Template',
                  subtitle: 'Choose your default invoice layout',
                  icon: Icons.receipt_long,
                  iconColor: Colors.deepOrange,
                  onTap: () => Nav.push(const InvoiceTemplateSettings()),
                ),

                const SizedBox(height: 12),

                _buildModernSettingCard(
                  title: 'Live Chat Support',
                  subtitle: 'Chat with support',
                  icon: Icons.support_agent,
                  iconColor: Colors.indigo,
                  onTap: () => Nav.push(const TawkLiveChatPage()),
                ),

                const SizedBox(height: 12),

                _buildCompanySettingsSection(),

                const SizedBox(height: 12),

                _buildGuideToggleCard(
                  isEnabled: guideEnabled,
                  onChanged: (value) =>
                      ref.read(guideProvider.notifier).setEnabled(value),
                ),

                const SizedBox(height: 12),

                _buildModernSettingCard(
                  title: 'Log Out',
                  subtitle: 'Sign out of your account',
                  icon: Icons.logout,
                  iconColor: Colors.redAccent,
                  onTap: _handleLogout,
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

  Widget _buildGuideToggleCard({
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorsApp.btnColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.help_outline,
              color: ColorsApp.btnColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Guided Help",
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorsApp.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Show or hide help icons across the app",
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: ColorsApp.textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: ColorsApp.btnColor,
          ),
        ],
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

  Widget _buildCompanySettingsSection() {
    if (isLoadingSettings) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (companySettings == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                settingsError ?? "Company settings unavailable",
                style: GoogleFonts.openSans(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _loadCompanySettings,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final settings = companySettings!;
    final notifications = settings.notifications;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Company Settings"),
          const SizedBox(height: 12),
          _buildSwitchRow(
            title: "Cloud Sync",
            value: settings.cloudSyncEnabled,
            onChanged: (value) => _updateSetting(
              current: settings,
              cloudSyncEnabled: value,
            ),
          ),
          _buildSwitchRow(
            title: "Auto Backup",
            value: settings.autoBackupEnabled,
            onChanged: (value) => _updateSetting(
              current: settings,
              autoBackupEnabled: value,
            ),
          ),
          const Divider(height: 24),
          Text(
            "Notifications",
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorsApp.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          _buildSwitchRow(
            title: "Push Notification",
            value: notifications.pushNotification,
            onChanged: (value) => _updateSetting(
              current: settings,
              notifications: NotificationSettings(
                pushNotification: value,
                emailNotification: notifications.emailNotification,
                quotationReminders: notifications.quotationReminders,
                projectDeadlines: notifications.projectDeadlines,
                backupAlerts: notifications.backupAlerts,
              ),
            ),
          ),
          _buildSwitchRow(
            title: "Email Notification",
            value: notifications.emailNotification,
            onChanged: (value) => _updateSetting(
              current: settings,
              notifications: NotificationSettings(
                pushNotification: notifications.pushNotification,
                emailNotification: value,
                quotationReminders: notifications.quotationReminders,
                projectDeadlines: notifications.projectDeadlines,
                backupAlerts: notifications.backupAlerts,
              ),
            ),
          ),
          _buildSwitchRow(
            title: "Quotation Reminders",
            value: notifications.quotationReminders,
            onChanged: (value) => _updateSetting(
              current: settings,
              notifications: NotificationSettings(
                pushNotification: notifications.pushNotification,
                emailNotification: notifications.emailNotification,
                quotationReminders: value,
                projectDeadlines: notifications.projectDeadlines,
                backupAlerts: notifications.backupAlerts,
              ),
            ),
          ),
          _buildSwitchRow(
            title: "Project Deadlines",
            value: notifications.projectDeadlines,
            onChanged: (value) => _updateSetting(
              current: settings,
              notifications: NotificationSettings(
                pushNotification: notifications.pushNotification,
                emailNotification: notifications.emailNotification,
                quotationReminders: notifications.quotationReminders,
                projectDeadlines: value,
                backupAlerts: notifications.backupAlerts,
              ),
            ),
          ),
          _buildSwitchRow(
            title: "Backup Alerts",
            value: notifications.backupAlerts,
            onChanged: (value) => _updateSetting(
              current: settings,
              notifications: NotificationSettings(
                pushNotification: notifications.pushNotification,
                emailNotification: notifications.emailNotification,
                quotationReminders: notifications.quotationReminders,
                projectDeadlines: notifications.projectDeadlines,
                backupAlerts: value,
              ),
            ),
          ),
          if (!canEditSettings) ...[
            const SizedBox(height: 8),
            Text(
              "Only owners or admins can change these settings.",
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: ColorsApp.textColor.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: ColorsApp.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: canEditSettings ? onChanged : null,
          activeColor: ColorsApp.btnColor,
        ),
      ],
    );
  }
}
