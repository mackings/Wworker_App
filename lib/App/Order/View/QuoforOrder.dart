import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Order/View/Orderpreview.dart';
import 'package:wworker/App/Quotation/Api/ClientQuotation.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';
import 'package:wworker/App/Quotation/Widget/ClientQCard.dart';
import 'package:wworker/Constant/urls.dart';

const _surface = Color(0xFFFAF7F3);
const _primary = Color(0xFFA16438);
const _text = Color(0xFF211D1A);
const _muted = Color(0xFF756A61);
const _border = Color(0xFFE8DED6);

class SelectQuotationForOrder extends ConsumerStatefulWidget {
  final String? clientName; // Made optional

  const SelectQuotationForOrder({
    super.key,
    this.clientName, // Optional parameter
  });

  @override
  ConsumerState<SelectQuotationForOrder> createState() =>
      _SelectQuotationForOrderState();
}

class _SelectQuotationForOrderState
    extends ConsumerState<SelectQuotationForOrder> {
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
          // Filter by client name only if provided
          if (widget.clientName != null) {
            quotations = quotationResponse.data
                .where((q) => q.clientName == widget.clientName)
                .toList();
          } else {
            // Show all quotations if no client name specified
            quotations = quotationResponse.data;
          }
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
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        foregroundColor: _text,
        title: Text(
          widget.clientName != null
              ? "Select Quotation for ${widget.clientName}"
              : "Select Quotation for Order",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.openSans(
            color: _text,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (errorMessage != null) {
      return _StateMessage(
        icon: Icons.error_outline,
        title: 'Failed to load quotations',
        message: errorMessage!,
        actionLabel: 'Retry',
        onAction: _loadQuotations,
      );
    }

    if (quotations.isEmpty) {
      return _StateMessage(
        icon: Icons.receipt_long_outlined,
        title: widget.clientName != null
            ? 'No quotations found for ${widget.clientName}'
            : 'No quotations found',
        message: widget.clientName != null
            ? 'Create a quotation for this client first.'
            : 'Create a quotation to get started.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuotations,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        itemCount: quotations.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _OrderPickerHeader(
              count: quotations.length,
              clientName: widget.clientName,
            );
          }

          final quotation = quotations[index - 1];
          final firstBom = quotation.boms.isNotEmpty
              ? quotation.boms.first
              : null;
          final firstItem = quotation.items.isNotEmpty
              ? quotation.items.first
              : null;

          return GestureDetector(
            onTap: () async {
              setState(() => _selectedQuotationId = quotation.id);
              final navigator = Navigator.of(context);
              await Future<void>.delayed(const Duration(milliseconds: 140));
              if (!mounted) return;
              navigator.push(
                MaterialPageRoute(
                  builder: (context) => OrderPreviewPage(quotation: quotation),
                ),
              );
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
                          'woodType': firstBom.materials.isNotEmpty
                              ? (firstBom.materials.first.woodType ??
                                    firstBom.materials.first.name)
                              : 'N/A',
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
              showSelectionIndicator: true,
              isSelected: _selectedQuotationId == quotation.id,
            ),
          );
        },
      ),
    );
  }
}

class _OrderPickerHeader extends StatelessWidget {
  final int count;
  final String? clientName;

  const _OrderPickerHeader({required this.count, required this.clientName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E211A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.checklist_rtl_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a quotation',
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  clientName == null
                      ? '$count quotations available for order creation.'
                      : '$count quotations available for $clientName.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 38, color: _primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  color: _text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  color: _muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    textStyle: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
