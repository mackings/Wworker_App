import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Order/View/Orderpreview.dart';
import 'package:wworker/App/Quotation/Api/ClientQuotation.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';
import 'package:wworker/App/Quotation/Widget/ClientQCard.dart';
import 'package:wworker/Constant/urls.dart';



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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.clientName != null
              ? "Select Quotation for ${widget.clientName}"
              : "Select Quotation for Order",
          style: const TextStyle(
            color: Color(0xFF302E2E),
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
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFA16438)),
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
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.clientName != null
                  ? 'No quotations found for ${widget.clientName}'
                  : 'No quotations found',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.clientName != null
                  ? 'Create a quotation for this client first'
                  : 'Create a quotation to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
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
              // Navigate to Order Preview
              Navigator.push(
                context,
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
                'items': firstItem != null
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
              onDelete: () {}, // Disable delete for order selection
            ),
          );
        },
      ),
    );
  }
}
