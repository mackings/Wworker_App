import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Invoice/View/invoice_preview.dart';
import 'package:wworker/App/Quotation/Api/ClientQuotation.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/UI/BomSummary.dart';
import 'package:wworker/App/Quotation/Widget/ClientQCard.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';






class AllClientQuotations extends ConsumerStatefulWidget {
  final bool isForInvoice;
  final String? clientName;
  
  const AllClientQuotations({
    super.key,
    this.isForInvoice = false,
    this.clientName,
  });

  @override
  ConsumerState<AllClientQuotations> createState() => _AllClientQuotationsState();
}

class _AllClientQuotationsState extends ConsumerState<AllClientQuotations> {
  final ClientQuotationService _quotationService = ClientQuotationService();
  List<Quotation> quotations = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _quotationService.getAllQuotations();

      if (result['success'] == true) {
        final quotationResponse = QuotationResponse.fromJson(result);
        setState(() {
          // Filter by client name if in invoice mode
          quotations = widget.isForInvoice && widget.clientName != null
              ? quotationResponse.data
                  .where((q) => q.clientName == widget.clientName)
                  .toList()
              : quotationResponse.data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = result['message'] ?? 'Failed to load quotations';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: CustomText(
          title: widget.isForInvoice 
              ? "Select Quotation for Invoice" 
              : "Quotations",
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFA16438),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load quotations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                errorMessage!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadQuotations,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA16438),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (quotations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.isForInvoice 
                  ? 'No quotations found for ${widget.clientName}'
                  : 'No quotations found.',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isForInvoice
                  ? 'Create a quotation for this client first'
                  : 'Create a quotation to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuotations,
      color: const Color(0xFFA16438),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: quotations.length,
        itemBuilder: (context, index) {
          final quotation = quotations[index];
          final firstItem = quotation.items.isNotEmpty
              ? quotation.items.first
              : null;

          return GestureDetector(
            onTap: () {
              if (widget.isForInvoice) {
                // Navigate to invoice preview
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoicePreview(
                      quotation: quotation,
                    ),
                  ),
                );
              } else {
                // Show normal bottom sheet
                _showQuotationItemsBottomSheet(quotation);
              }
            },
            child: ClientQuotationCard(
              quotation: {
                'clientName': quotation.clientName,
                'phoneNumber': quotation.phoneNumber,
                'description': quotation.description,
                'finalTotal': quotation.finalTotal,
                'status': quotation.status,
                'createdAt': quotation.createdAt.toIso8601String(),
                'quotationNumber': quotation.quotationNumber,
                'items': firstItem != null
                    ? [
                        {
                          'productName': quotation.service.product,
                          'woodType': firstItem.woodType ?? 'N/A',
                          'image': firstItem.image.isNotEmpty
                              ? firstItem.image
                              : Urls.woodImg,
                        }
                      ]
                    : [],
              },
              onDelete: () => _deleteQuotation(quotation.id),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteQuotation(String quotationId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: const Text(
          'Are you sure you want to delete this quotation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Implement delete functionality here
      // await _quotationService.deleteQuotation(quotationId);
      _loadQuotations();
    }
  }

  void _showQuotationItemsBottomSheet(Quotation quotation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuotationItemsBottomSheet(
        quotation: quotation,
        onAddItem: (item) => _addSingleItem(item),
        onAddAllItems: () => _addAllQuotationItems(quotation),
      ),
    );
  }

  Future<void> _addSingleItem(QuotationItem item) async {
    final materialNotifier = ref.read(materialProvider.notifier);

    final material = {
      "Product": item.woodType ?? item.foamType ?? "Other materials",
      "Materialname": item.description,
      "Width": item.width.toString(),
      "Length": item.length.toString(),
      "Thickness": item.thickness.toString(),
      "Unit": item.unit,
      "Sqm": item.squareMeter.toString(),
      "Price": item.sellingPrice.toString(),
      "quantity": item.quantity.toString(),
    };

    await materialNotifier.addMaterial(material);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text("Item added successfully"),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Navigate to BOM Summary
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BOMSummary()),
      );
    }
  }

  Future<void> _addAllQuotationItems(Quotation quotation) async {
    // Close bottom sheet first
    Navigator.pop(context);

    final materialNotifier = ref.read(materialProvider.notifier);

    for (final item in quotation.items) {
      final material = {
        "Product": item.woodType ?? item.foamType ?? "Other materials",
        "Materialname": item.description,
        "Width": item.width.toString(),
        "Length": item.length.toString(),
        "Thickness": item.thickness.toString(),
        "Unit": item.unit,
        "Sqm": item.squareMeter.toString(),
        "Price": item.sellingPrice.toString(),
        "quantity": item.quantity.toString(),
      };

      await materialNotifier.addMaterial(material);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Added ${quotation.items.length} item(s) from quotation",
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Navigate to BOM Summary
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BOMSummary()),
      );
    }
  }
}

// ✨ Modern Bottom Sheet Widget
class _QuotationItemsBottomSheet extends StatelessWidget {
  final Quotation quotation;
  final Function(QuotationItem) onAddItem;
  final VoidCallback onAddAllItems;

  const _QuotationItemsBottomSheet({
    required this.quotation,
    required this.onAddItem,
    required this.onAddAllItems,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = quotation.items.length;
    final totalPrice = quotation.finalTotal;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFFA16438),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quotation.quotationNumber,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF302E2E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                quotation.clientName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.inventory_2_outlined,
                          label: "$itemCount item${itemCount > 1 ? 's' : ''}",
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.account_balance_wallet,
                          label: "₦${totalPrice.toStringAsFixed(2)}",
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Items list
              Expanded(
                child: quotation.items.isEmpty
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
                            Text(
                              "No items in this quotation",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: quotation.items.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 24,
                        ),
                        itemBuilder: (context, index) {
                          final item = quotation.items[index];
                          return _buildItemCard(context, item);
                        },
                      ),
              ),

              // Bottom action buttons
              if (quotation.items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAddAllItems,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA16438),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline),
                            const SizedBox(width: 8),
                            Text(
                              "Add All $itemCount Item${itemCount > 1 ? 's' : ''} to BOM",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF302E2E)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF302E2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, QuotationItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.description.isNotEmpty
                      ? item.description
                      : "Material Item",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF302E2E),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFA16438),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Qty: ${item.quantity}",
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
          _buildItemDetail(
            icon: Icons.category_outlined,
            label: "Type",
            value: item.woodType ?? item.foamType ?? "N/A",
          ),
          const SizedBox(height: 8),
          _buildItemDetail(
            icon: Icons.straighten,
            label: "Dimensions",
            value:
                "${item.width} × ${item.length} × ${item.thickness} ${item.unit}",
          ),
          const SizedBox(height: 8),
          _buildItemDetail(
            icon: Icons.square_foot,
            label: "Area",
            value: "${item.squareMeter.toStringAsFixed(2)} sqm",
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Price",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7B7B7B),
                  ),
                ),
                Text(
                  "₦${item.sellingPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA16438),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Add single item button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet
                onAddItem(item);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add This Item"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA16438),
                side: const BorderSide(color: Color(0xFFA16438)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail({
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
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF302E2E),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}