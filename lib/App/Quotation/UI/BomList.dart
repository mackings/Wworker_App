import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Dashboad/Widget/itemCard.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/UI/AddMaterial.dart';
import 'package:wworker/App/Quotation/UI/BomSummary.dart';
import 'package:wworker/App/Quotation/Widget/AddListedBom.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';

class BOMList extends ConsumerStatefulWidget {
  const BOMList({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BOMListState();
}

class _BOMListState extends ConsumerState<BOMList> {
  final NumberFormat _money = NumberFormat.decimalPattern();

  double _lineTotal(Map<String, dynamic> item) {
    final calculation = item["calculation"];
    if (calculation is Map) {
      final total = double.tryParse(
        (calculation["totalMaterialCost"] ?? "").toString(),
      );
      if (total != null) return total;
    }
    final lineTotal = double.tryParse(
      (item["LineTotal"] ?? item["subtotal"] ?? "").toString(),
    );
    if (lineTotal != null) return lineTotal;
    final price = double.tryParse((item["Price"] ?? "0").toString()) ?? 0;
    final qty = int.tryParse((item["quantity"] ?? "1").toString()) ?? 1;
    return price * qty;
  }

  double _materialsTotal(List<Map<String, dynamic>> materials) {
    return materials.fold<double>(0, (sum, item) => sum + _lineTotal(item));
  }

  double _additionalTotal(List<Map<String, dynamic>> costs) {
    return costs.fold<double>(
      0,
      (sum, item) =>
          sum + (double.tryParse((item["amount"] ?? "0").toString()) ?? 0),
    );
  }

  String _formatMoney(double value) => "₦${_money.format(value.round())}";

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(materialProvider);
    final notifier = ref.read(materialProvider.notifier);

    final materials = List<Map<String, dynamic>>.from(data["materials"] ?? []);
    final additionalCosts = List<Map<String, dynamic>>.from(
      data["additionalCosts"] ?? [],
    );
    final materialTotal = _materialsTotal(materials);
    final extraTotal = _additionalTotal(additionalCosts);

    if (data["isLoaded"] != true) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F3),
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "BOM Review",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [
          GuideHelpIcon(
            title: "BOM List",
            message:
                "Review the material and cost lines that make up this BOM. "
                "You can add more items, import saved BOM lines, or continue "
                "to pricing when the list is complete.",
          ),
        ],
      ),
      body: SafeArea(
        child: materials.isEmpty && additionalCosts.isEmpty
            ? _buildEmptyState(context)
            : RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    _buildHero(
                      materialsCount: materials.length,
                      costsCount: additionalCosts.length,
                      materialTotal: materialTotal,
                      extraTotal: extraTotal,
                    ),
                    const SizedBox(height: 18),
                    if (materials.isNotEmpty) ...[
                      _buildSectionTitle(
                        icon: Icons.layers_outlined,
                        title: "Materials",
                        count: materials.length,
                      ),
                      const SizedBox(height: 10),
                      ...materials.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return ItemsCard(
                          item: {
                            ...item,
                            "Total": _money.format(_lineTotal(item).round()),
                          },
                          useBomStyle: true,
                          onDelete: () async {
                            await notifier.deleteMaterial(index);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Material deleted")),
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 18),
                    ],
                    if (additionalCosts.isNotEmpty) ...[
                      _buildSectionTitle(
                        icon: Icons.payments_outlined,
                        title: "Other Costs",
                        count: additionalCosts.length,
                      ),
                      const SizedBox(height: 10),
                      ...additionalCosts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final cost = entry.value;
                        return ItemsCard(
                          item: cost,
                          useBomStyle: true,
                          onDelete: () async {
                            await notifier.deleteAdditionalCost(index);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Additional cost deleted"),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomBar(materials, additionalCosts),
    );
  }

  Widget _buildHero({
    required int materialsCount,
    required int costsCount,
    required double materialTotal,
    required double extraTotal,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D241E),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bill of Materials",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "$materialsCount material${materialsCount == 1 ? '' : 's'} • "
                      "$costsCount extra cost${costsCount == 1 ? '' : 's'}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BomMetric(
                  label: "Materials",
                  value: _formatMoney(materialTotal),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BomMetric(
                  label: "Extras",
                  value: _formatMoney(extraTotal),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BomMetric(
                  label: "Total",
                  value: _formatMoney(materialTotal + extraTotal),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF8B4513)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF211D1A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE8DED6)),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Color(0xFF8B4513),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE8DED6)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 42,
                color: Color(0xFF8B4513),
              ),
              const SizedBox(height: 12),
              const Text(
                "No BOM lines yet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                "Add materials or import saved BOM lines to begin.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF756A61)),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: "Add Material",
                icon: Icons.add,
                onPressed: () => Nav.push(const AddMaterial()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "Add Material",
                    outlined: true,
                    icon: Icons.add,
                    onPressed: () => Nav.push(const AddMaterial()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    text: "Import",
                    outlined: true,
                    icon: Icons.playlist_add,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (context) => const AddFromBOMSheet(),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: "Review Pricing",
              icon: Icons.arrow_forward,
              onPressed: (materials.isEmpty && additionalCosts.isEmpty)
                  ? null
                  : () => Nav.push(const BOMSummary()),
            ),
          ],
        ),
      ),
    );
  }
}

class _BomMetric extends StatelessWidget {
  final String label;
  final String value;

  const _BomMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
