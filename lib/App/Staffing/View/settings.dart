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
import 'package:wworker/App/Staffing/Widgets/staffaccess.dart';
import 'package:wworker/App/Invoice/View/invoice_template_settings.dart';
import 'package:wworker/App/Auth/Api/AuthService.dart';
import 'package:wworker/App/Auth/View/Signin.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  static const Color _pageBg = Color(0xFFFAF7F3);
  static const Color _ink = Color(0xFF211D1A);
  static const Color _muted = Color(0xFF756A61);
  static const Color _brand = Color(0xFF8B4513);
  static const Color _border = Color(0xFFE8DED6);

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
      backgroundColor: _pageBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _pageBg,
        surfaceTintColor: _pageBg,
        elevation: 0,
        title: Text(
          "Settings",
          style: GoogleFonts.openSans(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: GuideHelpIcon(
              title: "Settings Help",
              message:
                  "Use Settings to configure your company, staff access, and system tools. "
                  "Turn on Guided Help here to reveal step-by-step tips in key sections "
                  "(Quotations, Orders, BOMs, Sales). Turn it off to hide the icons.",
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingsHero(),
                const SizedBox(height: 16),

                // Company Management Section
                _buildSectionTitle('Company Management'),
                const SizedBox(height: 12),

                _buildFramedChild(child: StaffAccessWidget()),

                const SizedBox(height: 20),

                // Business Settings Section
                _buildSectionTitle('Business Settings'),
                const SizedBox(height: 12),

                _buildModernSettingCard(
                  title: 'Overhead Cost',
                  subtitle: 'Manage your overhead costs',
                  icon: Icons.account_balance_wallet,
                  iconColor: const Color(0xFF2E7D32),
                  onTap: () => Nav.push(AddOverheadCostCard()),
                ),

                const SizedBox(height: 12),

                _buildModernSettingCard(
                  title: 'Material Upload',
                  subtitle: 'Configure materials and categories',
                  icon: Icons.settings_applications,
                  iconColor: const Color(0xFF1565C0),
                  onTap: () => Nav.push(SelectMaterialCategoryPage()),
                ),

                const SizedBox(height: 12),

                _buildModernSettingCard(
                  title: 'Invoice Template',
                  subtitle: 'Choose your default invoice layout',
                  icon: Icons.receipt_long,
                  iconColor: const Color(0xFFB55423),
                  onTap: () => Nav.push(const InvoiceTemplateSettings()),
                ),

                const SizedBox(height: 12),

                _buildModernSettingCard(
                  title: 'Live Chat Support',
                  subtitle: 'Chat with support',
                  icon: Icons.support_agent,
                  iconColor: const Color(0xFF4E5BA6),
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
                    iconColor: _brand,
                    onTap: () => Nav.push(const PlatformDashboardNew()),
                  ),
                ],

                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.tune_rounded, color: _brand, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Workspace controls",
                  style: GoogleFonts.openSans(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage company access, materials, invoices, and system preferences.",
                  style: GoogleFonts.openSans(
                    color: _muted,
                    fontSize: 12,
                    height: 1.35,
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

  Widget _buildFramedChild({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.help_outline, color: _brand),
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
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Show or hide help icons across the app",
                  style: GoogleFonts.openSans(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: onChanged,
            activeThumbColor: _brand,
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
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _ink,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      height: 1.3,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanySettingsSection() {
    if (isLoadingSettings) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: const Center(child: CircularProgressIndicator(color: _brand)),
      );
    }

    if (companySettings == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
            onChanged: (value) =>
                _updateSetting(current: settings, cloudSyncEnabled: value),
          ),
          _buildSwitchRow(
            title: "Auto Backup",
            value: settings.autoBackupEnabled,
            onChanged: (value) =>
                _updateSetting(current: settings, autoBackupEnabled: value),
          ),
          const Divider(height: 24),
          Text(
            "Notifications",
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _ink,
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
              style: GoogleFonts.openSans(fontSize: 12, color: _muted),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: _ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: canEditSettings ? onChanged : null,
            activeThumbColor: _brand,
          ),
        ],
      ),
    );
  }
}
