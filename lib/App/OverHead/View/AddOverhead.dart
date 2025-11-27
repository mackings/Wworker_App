import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/OverHead/Api/OCService.dart';
import 'package:wworker/App/OverHead/Model/OCmodel.dart';


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

  // Tabs/Categories
  final List<String> categories = ['Depreciation', 'Others', 'Rent', 'Salaries'];
  String selectedCategory = 'Depreciation';

  // Periods
  final List<String> periods = ['Hourly','Daily','Monthly', 'Quarterly', 'Yearly'];
  String? selectedPeriod = 'Monthly';

  // Form fields
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController costController = TextEditingController();

  // State
  bool isExpanded = false;
  bool isLoading = false;
  bool isFetchingItems = true;
  List<OverheadCost> items = [];

  @override
  void initState() {
    super.initState();
    _fetchOverheadCosts();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    costController.dispose();
    super.dispose();
  }

  // 💾 SAVE OVERHEAD COSTS TO SHARED PREFERENCES
  Future<void> _saveOverheadCostsToPrefs(List<OverheadCost> costs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert list to JSON
      final costsJson = costs.map((cost) => {
        "id": cost.id,
        "category": cost.category,
        "description": cost.description,
        "period": cost.period,
        "cost": cost.cost,
        "user": cost.user,
        "createdAt": cost.createdAt.toIso8601String(),
      }).toList();
      
      await prefs.setString('overhead_costs', jsonEncode(costsJson));
      debugPrint("💾 Saved ${costs.length} overhead costs to prefs");
    } catch (e) {
      debugPrint("⚠️ Error saving to prefs: $e");
    }
  }

  // 📖 READ OVERHEAD COSTS FROM SHARED PREFERENCES
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

  // 🗑️ CLEAR OVERHEAD COSTS FROM SHARED PREFERENCES
  Future<void> _clearOverheadCostsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('overhead_costs');
      debugPrint("🗑️ Cleared overhead costs from prefs");
    } catch (e) {
      debugPrint("⚠️ Error clearing prefs: $e");
    }
  }

  // 🟢 FETCH OVERHEAD COSTS FROM API
  Future<void> _fetchOverheadCosts() async {
    setState(() => isFetchingItems = true);

    try {
      final fetchedItems = await _service.getOverheadCosts();

      if (mounted) {
        setState(() {
          items = fetchedItems;
          isFetchingItems = false;
        });
        
        // Save to SharedPreferences
        await _saveOverheadCostsToPrefs(fetchedItems);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isFetchingItems = false);
        
        // Try loading from prefs if API fails
        final cachedItems = await _loadOverheadCostsFromPrefs();
        setState(() => items = cachedItems);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cachedItems.isNotEmpty
                  ? "Loaded ${cachedItems.length} cached overhead costs"
                  : "Error fetching overhead costs: ${e.toString()}",
            ),
            backgroundColor: cachedItems.isNotEmpty ? Colors.orange : Colors.redAccent,
          ),
        );
      }
    }
  }

  // 🟢 CREATE OVERHEAD COST VIA API
  Future<void> _handleAddItem() async {
    // Validate
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
          // Reset form
          descriptionController.clear();
          costController.clear();
          
          // Collapse the form
          setState(() => isExpanded = false);

          // Refresh the list (will also save to prefs)
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

  // 🔴 DELETE OVERHEAD COST VIA API
  Future<void> _handleDeleteItem(String id, int index) async {
    // Show confirmation dialog
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
          // Refresh the list (will also update prefs)
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

  double _calculateTotal() {
    return items.fold(0.0, (sum, item) => sum + item.cost);
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

            SizedBox(height: 15,),
            // Header


            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Add Cost Card (Expandable)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD3D3D3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with expand/collapse
                          InkWell(
                            onTap: () {
                              setState(() {
                                isExpanded = !isExpanded;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.add,
                                      color: Color(0xFFA16438),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Add Cost",
                                      style: GoogleFonts.openSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF302E2E),
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: const Color(0xFFA16438),
                                ),
                              ],
                            ),
                          ),

                          // Expandable Form
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            crossFadeState: isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),

                                // Category Tabs
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: categories.map((category) {
                                      final selected = selectedCategory == category;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedCategory = category;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: selected
                                                    ? const Color(0xFFA16438)
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            category,
                                            style: GoogleFonts.openSans(
                                              fontSize: 14,
                                              color: selected
                                                  ? const Color(0xFFA16438)
                                                  : const Color(0xFF9E9E9E),
                                              fontWeight: selected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Description Field
                                Text(
                                  "Description",
                                  style: GoogleFonts.openSans(
                                    fontSize: 14,
                                    color: const Color(0xFF7B7B7B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: descriptionController,
                                  decoration: InputDecoration(
                                    hintText: "e.g., Melina",
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Period Dropdown
                                Text(
                                  "Period",
                                  style: GoogleFonts.openSans(
                                    fontSize: 14,
                                    color: const Color(0xFF7B7B7B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: selectedPeriod,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                  ),
                                  items: periods
                                      .map((period) => DropdownMenuItem(
                                            value: period,
                                            child: Text(period),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPeriod = value;
                                    });
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Cost Field
                                Text(
                                  "Cost",
                                  style: GoogleFonts.openSans(
                                    fontSize: 14,
                                    color: const Color(0xFF7B7B7B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: costController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "15,000",
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 13,
                                    ),
                                    suffixText: "NGN",
                                    suffixStyle: GoogleFonts.openSans(
                                      fontSize: 14,
                                      color: const Color(0xFF7B7B7B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Add Item Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _handleAddItem,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFA16438),
                                      disabledBackgroundColor: const Color(0xFFCCA183),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.add, size: 20, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Add item",
                                                style: GoogleFonts.openSans(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Items (${items.length})",
                                  style: GoogleFonts.openSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF302E2E),
                                  ),
                                ),
                                Text(
                                  "Total: ₦${_calculateTotal().toStringAsFixed(2)}",
                                  style: GoogleFonts.openSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFA16438),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return _buildItemCard(index, item);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Save Button
                    if (items.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Saved ${items.length} overhead cost items. Total: ₦${_calculateTotal().toStringAsFixed(2)}",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFFA16438),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Save",
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFA16438),
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

  Widget _buildItemCard(int index, OverheadCost item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          _buildItemRow("Category", item.category),
          _buildItemRow("Description", item.description),
          _buildItemRow("Period", item.period),
          _buildItemRow("Cost", "₦${item.cost.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleDeleteItem(item.id, index),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(
                "Delete Item",
                style: GoogleFonts.openSans(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA16438),
                side: const BorderSide(color: Color(0xFFA16438)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: const Color(0xFF7B7B7B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF302E2E),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔧 HELPER CLASS: Overhead Cost Manager
// Use this in your BOMSummary to get overhead costs
class OverheadCostManager {
  static Future<List<Map<String, dynamic>>> getOverheadCosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final costsString = prefs.getString('overhead_costs');
      
      if (costsString == null || costsString.isEmpty) {
        return [];
      }
      
      final List<dynamic> costsJson = jsonDecode(costsString);
      return costsJson.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint("⚠️ Error loading overhead costs: $e");
      return [];
    }
  }
  
  static Future<double> getTotalOverheadCost() async {
    final costs = await getOverheadCosts();
    return costs.fold<double>(0.0, (sum, cost) => sum + (cost['cost'] as num).toDouble());
  }
}