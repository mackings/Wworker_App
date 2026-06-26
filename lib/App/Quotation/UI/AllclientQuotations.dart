import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Invoice/View/invoice_preview.dart';
import 'package:wworker/App/Quotation/Api/ClientQuotation.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/UI/BomSummary.dart';
import 'package:wworker/App/Quotation/Widget/ClientQCard.dart';
import 'package:wworker/Constant/urls.dart';

const Color _quoteBg = Color(0xFFFAF7F3);
const Color _quoteInk = Color(0xFF211D1A);
const Color _quoteMuted = Color(0xFF756A61);
const Color _quoteBrand = Color(0xFF8B4513);
const Color _quoteBorder = Color(0xFFE8DED6);

class AllClientQuotations extends ConsumerStatefulWidget {
  final bool isForInvoice;
  final String? clientName;
  final bool isImportMode;

  const AllClientQuotations({
    super.key,
    this.isForInvoice = false,
    this.clientName,
    this.isImportMode = false,
  });

  @override
  ConsumerState<AllClientQuotations> createState() =>
      _AllClientQuotationsState();
}

class _AllClientQuotationsState extends ConsumerState<AllClientQuotations> {
  final ClientQuotationService _quotationService = ClientQuotationService();
  List<Quotation> quotations = [];
  bool isLoading = true;
  String? errorMessage;
  String? _selectedQuotationId;

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
      backgroundColor: _quoteBg,
      appBar: AppBar(
        backgroundColor: _quoteBg,
        surfaceTintColor: _quoteBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.isForInvoice
              ? "Select Quotation for Invoice"
              : widget.isImportMode
              ? "Import BOMs"
              : "Quotations",
          style: GoogleFonts.openSans(
            color: _quoteInk,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _quoteBrand));
    }

    if (errorMessage != null) {
      return _QuotationStateMessage(
        icon: Icons.error_outline,
        title: 'Failed to load quotations',
        message: errorMessage!,
        action: ElevatedButton.icon(
          onPressed: _loadQuotations,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _quoteBrand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (quotations.isEmpty) {
      return _QuotationStateMessage(
        icon: Icons.receipt_long_outlined,
        title: widget.isForInvoice
            ? 'No quotations for ${widget.clientName}'
            : widget.isImportMode
            ? 'No quotations available'
            : 'No quotations found',
        message: widget.isForInvoice
            ? 'Create a quotation for this client first.'
            : widget.isImportMode
            ? 'Create quotations to import them here.'
            : 'Create a quotation to get started.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuotations,
      color: _quoteBrand,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        itemCount: quotations.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeader();

          final quotation = quotations[index - 1];
          final firstBom = quotation.boms.isNotEmpty
              ? quotation.boms.first
              : null;
          final firstItem = quotation.items.isNotEmpty
              ? quotation.items.first
              : null;

          return GestureDetector(
            onTap: () async {
              if (widget.isForInvoice) {
                final navigator = Navigator.of(context);
                setState(() => _selectedQuotationId = quotation.id);
                await Future.delayed(const Duration(milliseconds: 140));
                if (!mounted) return;
                // Navigate to invoice preview
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => InvoicePreview(quotation: quotation),
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
                'items': firstBom != null
                    ? [
                        {
                          'productName': firstBom.name.isNotEmpty
                              ? firstBom.name
                              : firstBom.product.name,
                          'woodType':
                              '${firstBom.materials.length} material(s)',
                          'image': firstBom.product.image.isNotEmpty
                              ? firstBom.product.image
                              : Urls.woodImg,
                        },
                      ]
                    : firstItem != null
                    ? [
                        {
                          'productName': quotation.service.product,
                          'woodType': firstItem.woodType ?? 'N/A',
                          'image': firstItem.image.isNotEmpty
                              ? firstItem.image
                              : Urls.woodImg,
                        },
                      ]
                    : [],
              },
              showSelectionIndicator: widget.isForInvoice,
              isSelected: _selectedQuotationId == quotation.id,
              onDelete: widget.isForInvoice
                  ? null
                  : () => _deleteQuotation(quotation.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final title = widget.isForInvoice
        ? 'Choose quotation'
        : widget.isImportMode
        ? 'Import quotation BOMs'
        : 'Client quotations';
    final subtitle = widget.isForInvoice
        ? '${widget.clientName ?? 'Client'} has ${quotations.length} quotation${quotations.length == 1 ? '' : 's'} available for invoice generation.'
        : '${quotations.length} quotation${quotations.length == 1 ? '' : 's'} available.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _quoteBorder),
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
                color: _quoteBrand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: _quoteBrand,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      color: _quoteInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.openSans(
                      color: _quoteMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
              const Expanded(child: Text("Item added successfully")),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

class _QuotationStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _QuotationStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _quoteBrand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: _quoteBrand, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                color: _quoteInk,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                color: _quoteMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
                        separatorBuilder: (context, index) =>
                            const Divider(height: 24),
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
                        color: Colors.black.withValues(alpha: 0.05),
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
                    fontWeight: FontWeight.w600,
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
