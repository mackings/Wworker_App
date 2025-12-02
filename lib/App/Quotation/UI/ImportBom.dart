import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Api/ClientQuotation.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';




class ImportQuotationsPage extends ConsumerStatefulWidget {
  const ImportQuotationsPage({super.key});

  @override
  ConsumerState<ImportQuotationsPage> createState() =>
      _ImportQuotationsPageState();
}

class _ImportQuotationsPageState extends ConsumerState<ImportQuotationsPage> {
  final ClientQuotationService _service = ClientQuotationService();

  List<Quotation> apiQuotations = [];
  Set<String> selectedQuotationIds = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAPIQuotations();
  }

  /// Load quotations from API
  Future<void> _loadAPIQuotations() async {
    setState(() => isLoading = true);

    final response = await _service.getAllQuotations();

    if (response['success'] == true) {
      final quotationResponse = QuotationResponse.fromJson(response);

      setState(() {
        apiQuotations = quotationResponse.data;
        isLoading = false;
      });

      debugPrint("✅ Loaded ${apiQuotations.length} API quotations");
    } else {
      setState(() {
        apiQuotations = [];
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load quotations'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Toggle quotation selection
  void _toggleSelection(String quotationId) {
    setState(() {
      if (selectedQuotationIds.contains(quotationId)) {
        selectedQuotationIds.remove(quotationId);
      } else {
        selectedQuotationIds.add(quotationId);
      }
    });
  }

  /// Import selected quotations as complete BOMs
  Future<void> _importSelectedQuotations() async {
    if (selectedQuotationIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select at least one quotation to import'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final quotationNotifier = ref.read(quotationSummaryProvider.notifier);
      int importedCount = 0;

      for (var apiQuotation in apiQuotations) {
        if (!selectedQuotationIds.contains(apiQuotation.id)) continue;

        // Convert API quotation items to materials format
        List<Map<String, dynamic>> materials = apiQuotation.items.map((item) {
          return {
            "Product": item.woodType ?? item.foamType ?? "Material",
            "Materialname": item.description.isNotEmpty
                ? item.description
                : "Imported Item",
            "Width": item.width,
            "Length": item.length,
            "Thickness": item.thickness,
            "Unit": item.unit,
            "Sqm": item.squareMeter,
            "quantity": item.quantity,
            "Price": item.costPrice.toString(),
          };
        }).toList();

        // Additional costs from overhead
        List<Map<String, dynamic>> additionalCosts = [];
        
        if (apiQuotation.overheadCost > 0) {
          additionalCosts.add({
            "type": "Overhead",
            "description": "Manufacturing overhead",
            "amount": apiQuotation.overheadCost.toString(),
          });
        }

        // Service as additional cost
        if (apiQuotation.service.product.isNotEmpty) {
          additionalCosts.add({
            "type": "Service",
            "description": apiQuotation.service.product,
            "amount": apiQuotation.service.totalPrice.toString(),
          });
        }

        // Create product info from API quotation
        Map<String, dynamic> product = {
          "name": apiQuotation.service.product.isNotEmpty
              ? apiQuotation.service.product
              : "Imported BOM",
          "productId": apiQuotation.quotationNumber,
          "description": apiQuotation.description,
          "image": apiQuotation.items.isNotEmpty &&
                  apiQuotation.items.first.image.isNotEmpty
              ? apiQuotation.items.first.image
              : "",
        };

        // Create new quotation in local storage
        final newQuotation = {
          "product": product,
          "materials": materials,
          "additionalCosts": additionalCosts,
          "costPrice": apiQuotation.costPrice,
          "overheadCost": apiQuotation.overheadCost,
          "sellingPrice": apiQuotation.totalSellingPrice,
          "markupPercentage": apiQuotation.discount,
          "pricingMethod": "Imported",
          "expectedDuration": apiQuotation.expectedDuration?.value?.toString(),
          "expectedPeriod": apiQuotation.expectedDuration?.unit ?? "Day",
          "importedFrom": apiQuotation.id,
          "clientName": apiQuotation.clientName,
        };

        await quotationNotifier.addNewQuotation(newQuotation);
        importedCount++;

        debugPrint("✅ Imported: ${apiQuotation.quotationNumber}");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Successfully imported $importedCount BOM(s)'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to AllQuotations
        Nav.pop();
      }
    } catch (e) {
      debugPrint("⚠️ Error importing quotations: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error importing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const CustomText(title: "Import BOMs"),
        actions: [
          if (selectedQuotationIds.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => selectedQuotationIds.clear());
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Color(0xFFA16438)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : apiQuotations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No Quotations Available",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Create quotations to import them here",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAPIQuotations,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            itemCount: apiQuotations.length,
                            itemBuilder: (context, index) {
                              final quotation = apiQuotations[index];
                              final isSelected = selectedQuotationIds
                                  .contains(quotation.id);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildQuotationCard(
                                  quotation,
                                  isSelected,
                                ),
                              );
                            },
                          ),
                        ),
            ),

            // Bottom action bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedQuotationIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "${selectedQuotationIds.length} quotation(s) selected",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA16438),
                        ),
                      ),
                    ),
                  CustomButton(
                    text: "Import Selected BOMs",
                    icon: Icons.download,
                    onPressed: selectedQuotationIds.isEmpty
                        ? null
                        : _importSelectedQuotations,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationCard(Quotation quotation, bool isSelected) {
    final firstItem = quotation.items.isNotEmpty ? quotation.items.first : null;
    final imageUrl = firstItem?.image ?? '';
    
    return GestureDetector(
      onTap: () => _toggleSelection(quotation.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E0) : const Color(0xFFF5F8F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFA16438) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with checkbox, image, and status
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(quotation.id),
                  activeColor: const Color(0xFFA16438),
                ),
                const SizedBox(width: 8),
                // Circle Avatar with item count badge
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl.isEmpty
                          ? Icon(
                              Icons.inventory_2_outlined,
                              size: 28,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                    // Item count badge
                    if (quotation.items.isNotEmpty)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA16438),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '${quotation.items.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quotation.clientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Quote #${quotation.quotationNumber}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(quotation.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quotation.status,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quotation Details
            _buildDetailRow(
              icon: Icons.inventory_2_outlined,
              label: "Items",
              value: "${quotation.items.length}",
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.description_outlined,
              label: "Description",
              value: quotation.description.isNotEmpty
                  ? quotation.description
                  : "No description",
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: "Created",
              value: _formatDate(quotation.createdAt),
            ),
            const SizedBox(height: 12),

            // Price details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cost Price',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7B7B7B),
                        ),
                      ),
                      Text(
                        "₦${quotation.costPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selling Price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "₦${quotation.totalSellingPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA16438),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF302E2E),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}