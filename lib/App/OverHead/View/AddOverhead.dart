import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/OverHead/Api/OCService.dart';
import 'package:wworker/App/OverHead/Model/OCmodel.dart';
import 'package:wworker/App/OverHead/Widget/OCCalculator.dart';
import 'package:wworker/App/OverHead/Widget/OCwidgets.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';



class AddOverheadCostCard extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Color? color;

  const AddOverheadCostCard({
    super.key,
    this.title = "Overhead Cost",
    this.icon,
    this.color,
  });

  @override
  State<AddOverheadCostCard> createState() => _AddOverheadCostCardState();
}

class _AddOverheadCostCardState extends State<AddOverheadCostCard> {
  final OverheadCostService _service = OverheadCostService();

  // Categories
  final List<String> categories = ['Depreciation', 'Others', 'Rent', 'Salaries'];
  String selectedCategory = 'Depreciation';

  // Periods
  final List<String> periods = ['Hourly', 'Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly'];
  String? selectedPeriod = 'Monthly';

  // Duration for viewing totals
  String selectedViewDuration = 'Monthly';

  // Form fields
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController costController = TextEditingController();

  // State
  bool isExpanded = false;
  bool isLoading = false;
  bool isFetchingItems = true;
  List<OverheadCost> items = [];

  // Pricing Settings
  double markupPercentage = 30.0;
  String pricingMethod = 'Method 1';
  int workingDaysPerMonth = 26;

  // ✅ Track if data needs syncing
  bool hasUnsyncedData = false;
  bool isStaff = false;
  int localItemCount = 0;
  int serverItemCount = 0;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _fetchOverheadCosts();
    _loadPricingSettings();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    costController.dispose();
    super.dispose();
  }

  // ✅ Check if user is staff (not owner/admin)
  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole');
    setState(() {
      isStaff = role != 'owner' && role != 'admin';
    });
    debugPrint("👤 User role: $role (isStaff: $isStaff)");
  }

  // ✅ Enhanced sync status check - compares local vs server data
  Future<void> _checkSyncStatus() async {
    if (!isStaff) return; // Only check for staff members

    try {
      debugPrint("🔍 Checking sync status...");
      
      // Get cached data from local device
      final cachedItems = await _loadOverheadCostsFromPrefs();
      localItemCount = cachedItems.length;
      
      // Get server data
      final serverItems = await _service.getOverheadCosts();
      serverItemCount = serverItems.length;
      
      debugPrint("📊 Local: $localItemCount items | Server: $serverItemCount items");
      
      // Check for differences
      bool needsSync = false;
      
      // Different counts = needs sync
      if (localItemCount != serverItemCount) {
        needsSync = true;
        debugPrint("⚠️ Count mismatch detected");
      } else if (localItemCount > 0) {
        // Same count, but check if IDs match
        final localIds = cachedItems.map((e) => e.id).toSet();
        final serverIds = serverItems.map((e) => e.id).toSet();
        
        if (!localIds.containsAll(serverIds) || !serverIds.containsAll(localIds)) {
          needsSync = true;
          debugPrint("⚠️ Item mismatch detected");
        }
        
        // Also check for different costs/descriptions
        if (!needsSync) {
          for (var cachedItem in cachedItems) {
            final serverItem = serverItems.firstWhere(
              (item) => item.id == cachedItem.id,
              orElse: () => cachedItem,
            );
            
            if (serverItem.id != cachedItem.id ||
                serverItem.cost != cachedItem.cost ||
                serverItem.description != cachedItem.description) {
              needsSync = true;
              debugPrint("⚠️ Item content mismatch detected");
              break;
            }
          }
        }
      }
      
      if (mounted && needsSync) {
        setState(() => hasUnsyncedData = true);
        _showSyncPrompt();
      } else {
        debugPrint("✅ Data is in sync");
      }
    } catch (e) {
      debugPrint("⚠️ Error checking sync status: $e");
    }
  }

  // ✅ Show enhanced sync prompt with details
  void _showSyncPrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.sync_problem,
                color: Color(0xFFA16438),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sync Required',
                  style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your local data is out of sync with the server.',
                style: GoogleFonts.openSans(fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              // ✅ Show comparison
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Local Device:',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$localItemCount items',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Server:',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$serverItemCount items',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA16438).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFA16438),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        localItemCount > serverItemCount
                            ? 'You have ${localItemCount - serverItemCount} more item(s) locally. Sync to update server.'
                            : serverItemCount > localItemCount
                            ? 'Server has ${serverItemCount - localItemCount} more item(s). Sync to update local data.'
                            : 'Items are different. Sync to match server data.',
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: const Color(0xFFA16438),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => hasUnsyncedData = false);
              },
              child: Text(
                'Later',
                style: GoogleFonts.openSans(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _handleSaveAndSync();
              },
              icon: const Icon(Icons.sync, size: 18),
              label: Text(
                'Sync Now',
                style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA16438),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ✅ Enhanced save and sync with better feedback
  Future<void> _handleSaveAndSync() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to sync'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading with details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFFA16438),
                ),
                const SizedBox(height: 16),
                Text(
                  'Syncing overhead costs...',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait',
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Save current data to local storage
      await _saveOverheadCostsToPrefs(items);
      
      // Refresh from server to get latest data
      final serverItems = await _service.getOverheadCosts();
      
      // Update local state with server data
      if (mounted) {
        setState(() {
          items = serverItems;
          hasUnsyncedData = false;
          serverItemCount = serverItems.length;
          localItemCount = serverItems.length;
        });
        
        // Save synced data to local storage
        await _saveOverheadCostsToPrefs(serverItems);
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "✅ Synced successfully! ${serverItems.length} overhead cost items. Total ($selectedViewDuration): ₦${_calculateTotalForDuration().toStringAsFixed(2)}",
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Sync failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Load pricing settings
  Future<void> _loadPricingSettings() async {
    final markup = await PricingSettingsManager.getMarkup();
    final method = await PricingSettingsManager.getPricingMethod();
    final workingDays = await PricingSettingsManager.getWorkingDays();

    setState(() {
      markupPercentage = markup;
      pricingMethod = method;
      workingDaysPerMonth = workingDays;
    });
  }

  // Show settings dialog
  Future<void> _showSettingsDialog() async {
    final markupController = TextEditingController(text: markupPercentage.toString());
    final workingDaysController = TextEditingController(text: workingDaysPerMonth.toString());
    String tempMethod = pricingMethod;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Pricing Settings',
            style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pricing Method
                Text(
                  'Pricing Method',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7B7B7B),
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Method 1'),
                  subtitle: const Text('Direct Markup (No MOC in cost price)'),
                  value: 'Method 1',
                  groupValue: tempMethod,
                  onChanged: (value) {
                    setDialogState(() => tempMethod = value!);
                  },
                  activeColor: const Color(0xFFA16438),
                ),
                RadioListTile<String>(
                  title: const Text('Method 2'),
                  subtitle: const Text('Include Manufacturing Overhead Cost'),
                  value: 'Method 2',
                  groupValue: tempMethod,
                  onChanged: (value) {
                    setDialogState(() => tempMethod = value!);
                  },
                  activeColor: const Color(0xFFA16438),
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Markup Percentage
                Text(
                  'Markup Percentage',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7B7B7B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: markupController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    suffixText: '%',
                    hintText: '30',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Working Days
                Text(
                  'Factory Working Days per Month',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7B7B7B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: workingDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    suffixText: 'days',
                    hintText: '26',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.openSans(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final markup = double.tryParse(markupController.text) ?? 30.0;
                final workingDays = int.tryParse(workingDaysController.text) ?? 26;

                // Validate
                if (markup <= 0 || markup > 1000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid markup percentage (1-1000)'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                if (workingDays <= 0 || workingDays > 31) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid working days (1-31)'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                // Save settings
                await PricingSettingsManager.saveMarkup(markup);
                await PricingSettingsManager.savePricingMethod(tempMethod);
                await PricingSettingsManager.saveWorkingDays(workingDays);

                // Update local state
                setState(() {
                  markupPercentage = markup;
                  pricingMethod = tempMethod;
                  workingDaysPerMonth = workingDays;
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Settings saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA16438),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.openSans(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveOverheadCostsToPrefs(List<OverheadCost> costs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final costsJson = costs
          .map((cost) => {
                "id": cost.id,
                "category": cost.category,
                "description": cost.description,
                "period": cost.period,
                "cost": cost.cost,
                "user": cost.user,
                "createdAt": cost.createdAt.toIso8601String(),
              })
          .toList();
      await prefs.setString('overhead_costs', jsonEncode(costsJson));
      debugPrint("💾 Saved ${costs.length} overhead costs to prefs");
    } catch (e) {
      debugPrint("⚠️ Error saving to prefs: $e");
    }
  }

  Future<List<OverheadCost>> _loadOverheadCostsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final costsString = prefs.getString('overhead_costs');

      if (costsString == null || costsString.isEmpty) {
        return [];
      }

      final List<dynamic> costsJson = jsonDecode(costsString);
      final costs = costsJson.map((json) => OverheadCost.fromJson(json)).toList();

      debugPrint("📖 Loaded ${costs.length} overhead costs from prefs");
      return costs;
    } catch (e) {
      debugPrint("⚠️ Error loading from prefs: $e");
      return [];
    }
  }

  Future<void> _fetchOverheadCosts() async {
    setState(() => isFetchingItems = true);

    try {
      final fetchedItems = await _service.getOverheadCosts();

      if (mounted) {
        setState(() {
          items = fetchedItems;
          isFetchingItems = false;
          serverItemCount = fetchedItems.length;
        });
        await _saveOverheadCostsToPrefs(fetchedItems);
        
        // ✅ Check sync status after fetching
        await _checkSyncStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isFetchingItems = false);
        final cachedItems = await _loadOverheadCostsFromPrefs();
        setState(() {
          items = cachedItems;
          localItemCount = cachedItems.length;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cachedItems.isNotEmpty
                  ? "⚠️ Loaded ${cachedItems.length} cached overhead costs (offline mode)"
                  : "Error fetching overhead costs: ${e.toString()}",
            ),
            backgroundColor: cachedItems.isNotEmpty ? Colors.orange : Colors.redAccent,
          ),
        );
        
        // ✅ Check sync status even with cached data
        if (cachedItems.isNotEmpty && isStaff) {
          // Staff member with cached data but no server connection
          setState(() {
            hasUnsyncedData = true;
            serverItemCount = 0; // Unknown server count
          });
        }
      }
    }
  }

  Future<void> _handleAddItem() async {
    if (descriptionController.text.trim().isEmpty ||
        costController.text.trim().isEmpty ||
        selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final cost = double.tryParse(costController.text.trim());
    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid cost"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await _service.createOverheadCost(
        category: selectedCategory,
        description: descriptionController.text.trim(),
        period: selectedPeriod!,
        cost: cost,
      );

      if (mounted) {
        setState(() => isLoading = false);

        if (response["success"] == true) {
          descriptionController.clear();
          costController.clear();
          setState(() => isExpanded = false);
          await _fetchOverheadCosts();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Overhead cost added successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response["message"] ?? "Failed to add overhead cost"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Item",
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Are you sure you want to delete this overhead cost?",
          style: GoogleFonts.openSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancel",
              style: GoogleFonts.openSans(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Delete",
              style: GoogleFonts.openSans(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _service.deleteOverheadCost(id);

      if (mounted) {
        if (response["success"] == true) {
          await _fetchOverheadCosts();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Item deleted successfully"),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response["message"] ?? "Failed to delete item"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  double _calculateTotalForDuration() {
    return OverheadCostCalculator.calculateTotalForDuration(
      items,
      selectedViewDuration,
    );
  }

  // ✅ Enhanced sync warning banner
  Widget _buildSyncWarningBanner() {
    if (!isStaff || !hasUnsyncedData) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade100,
              Colors.orange.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.sync_problem,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Out of Sync',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Local: $localItemCount items • Server: $serverItemCount items',
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _handleSaveAndSync,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'Sync Now',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.openSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFA16438),
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) => const GuideHelpIcon(
              title: "Overhead Costs",
              message:
                  "Step 1: add overhead items like rent, salaries, or utilities. "
                  "Step 2: choose a period and markup method. "
                  "Step 3: review totals to see how overhead affects pricing. "
                  "The goal is to keep overhead accurate for quotations.",
            ),
          ),
          // ✅ Enhanced sync indicator for staff
          if (isStaff && hasUnsyncedData)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.sync_problem, color: Colors.orange),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: _showSyncPrompt,
                tooltip: "Sync Required - $localItemCount local vs $serverItemCount server",
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: "Pricing Settings",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isFetchingItems ? null : _fetchOverheadCosts,
            tooltip: "Refresh",
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),

            // ✅ Enhanced sync warning banner
            _buildSyncWarningBanner(),

            if (isStaff && hasUnsyncedData) const SizedBox(height: 15),

            // Settings Summary Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA16438)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFA16438), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "$pricingMethod • ${markupPercentage.toStringAsFixed(1)}% Markup • $workingDaysPerMonth working days/month",
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: const Color(0xFFA16438),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Add Cost Form Widget
                    AddCostFormWidget(
                      isExpanded: isExpanded,
                      onToggleExpand: () {
                        setState(() => isExpanded = !isExpanded);
                      },
                      selectedCategory: selectedCategory,
                      categories: categories,
                      onCategoryChanged: (category) {
                        setState(() => selectedCategory = category);
                      },
                      descriptionController: descriptionController,
                      selectedPeriod: selectedPeriod,
                      periods: periods,
                      onPeriodChanged: (period) {
                        setState(() => selectedPeriod = period);
                      },
                      costController: costController,
                      isLoading: isLoading,
                      onAddItem: _handleAddItem,
                    ),

                    const SizedBox(height: 20),

                    // Duration Selector
                    if (items.isNotEmpty)
                      DurationSelectorWidget(
                        selectedDuration: selectedViewDuration,
                        onDurationChanged: (duration) {
                          setState(() => selectedViewDuration = duration);
                        },
                      ),

                    const SizedBox(height: 20),

                    // Items List
                    if (isFetchingItems)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFFA16438),
                          ),
                        ),
                      )
                    else if (items.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            "No overhead costs added yet",
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      // Total Display
                      TotalDisplayWidget(
                        itemCount: items.length,
                        total: _calculateTotalForDuration(),
                        duration: selectedViewDuration,
                      ),

                      const SizedBox(height: 12),

                      // Items List
                      ...items.map((item) => OverheadCostItemCard(
                            item: item,
                            onDelete: () => _handleDeleteItem(item.id),
                          )),
                    ],

                    const SizedBox(height: 20),

                    // ✅ Updated Save Button with sync info
                    if (items.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isStaff ? _handleSaveAndSync : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Saved ${items.length} overhead cost items. Total ($selectedViewDuration): ₦${_calculateTotalForDuration().toStringAsFixed(2)}",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: Icon(
                            isStaff ? Icons.sync : Icons.save,
                            color: Colors.white,
                          ),
                          label: Text(
                            isStaff 
                                ? (hasUnsyncedData ? "Save & Sync ($localItemCount ⇄ $serverItemCount)" : "Save & Sync")
                                : "Save",
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasUnsyncedData && isStaff 
                                ? Colors.orange 
                                : const Color(0xFFA16438),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
