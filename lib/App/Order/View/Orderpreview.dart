import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Order/Api/OrderService.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/DashConfig.dart';

class OrderPreviewPage extends StatefulWidget {
  final Quotation quotation;

  const OrderPreviewPage({super.key, required this.quotation});

  @override
  State<OrderPreviewPage> createState() => _OrderPreviewPageState();
}

class _OrderPreviewPageState extends State<OrderPreviewPage> {
  bool isLoading = false;
  final OrderService _orderService = OrderService();
  final TextEditingController _amountPaidController = TextEditingController();
  final Map<String, DateTime?> _startDates = {};
  final Map<String, DateTime?> _endDates = {};
  final Set<String> _selectedItemIds = {};
  bool _selectAllItems = false;

  double get grandTotal {
    if (_selectAllItems) {
      return _sumBomTotals(widget.quotation.boms);
    }
    if (_selectedItemIds.isEmpty) return 0;
    double total = 0;
    for (final bom in widget.quotation.boms) {
      final key = bom.bomId.isNotEmpty ? bom.bomId : bom.bomNumber;
      if (_selectedItemIds.contains(key)) {
        total += _bomSellingPrice(bom);
      }
    }
    return total;
  }

  double _bomSellingPrice(QuotationBom bom) {
    if (bom.pricing != null && bom.pricing!.sellingPrice > 0) {
      return bom.pricing!.sellingPrice;
    }
    if (bom.totalCost > 0) return bom.totalCost;
    return 0;
  }

  double _sumBomTotals(List<QuotationBom> boms) {
    if (boms.isEmpty) {
      return widget.quotation.finalTotal.toDouble();
    }
    double total = 0;
    for (final bom in boms) {
      total += _bomSellingPrice(bom);
    }
    return total;
  }

  double get balance {
    final raw = _amountPaidController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amountPaid = raw.isEmpty ? 0 : double.parse(raw);
    return grandTotal - amountPaid;
  }

  String _formatMoney(double value) {
    return NumberFormat.decimalPattern().format(value.round());
  }

  String get quotationImage {
    if (widget.quotation.boms.isNotEmpty &&
        widget.quotation.boms.first.product.image.isNotEmpty) {
      return widget.quotation.boms.first.product.image;
    }
    return Urls.woodImg;
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    super.dispose();
  }

  /// Calculate end date based on expected duration
  DateTime _calculateEndDate(DateTime start, ExpectedDuration? duration) {
    final effectiveDuration =
        duration ?? widget.quotation.expectedDuration;

    if (effectiveDuration == null || effectiveDuration.value == null) {
      // Default to 1 day if no duration specified
      return start.add(const Duration(days: 1));
    }

    final value = effectiveDuration.value!;
    final unit = effectiveDuration.unit.toLowerCase();

    switch (unit) {
      case 'day':
      case 'days':
        return start.add(Duration(days: value));

      case 'week':
      case 'weeks':
        return start.add(Duration(days: value * 7));

      case 'month':
      case 'months':
        // Approximate month as 30 days
        return start.add(Duration(days: value * 30));

      default:
        return start.add(Duration(days: value));
    }
  }

  /// Handle start date selection
  Future<void> _selectStartDate(QuotationBom bom) async {
    final key = bom.bomId.isNotEmpty ? bom.bomId : bom.bomNumber;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDates[key] ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA16438),
              onPrimary: Colors.white,
              onSurface: Color(0xFF302E2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedItemIds.add(key);
        _startDates[key] = picked;
        _endDates[key] = _calculateEndDate(picked, bom.expectedDuration);
      });
    }
  }

  /// Handle end date selection (user can override auto-calculated date)
  Future<void> _selectEndDate(QuotationBom bom) async {
    final key = bom.bomId.isNotEmpty ? bom.bomId : bom.bomNumber;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDates[key] ?? _startDates[key] ?? DateTime.now(),
      firstDate: _startDates[key] ?? DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA16438),
              onPrimary: Colors.white,
              onSurface: Color(0xFF302E2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedItemIds.add(key);
        _endDates[key] = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Order Preview"),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Client Information
              _buildInfoSection(
                title: "Client Information",
                content: ContactInfo(
                  name: widget.quotation.clientName,
                  address: widget.quotation.clientAddress,
                  nearestBusStop: widget.quotation.nearestBusStop,
                  phone: widget.quotation.phoneNumber,
                  email: widget.quotation.email,
                ),
              ),
              const SizedBox(height: 24),

              // Quotation Card
              _buildQuotationCard(),

              const SizedBox(height: 24),

              // Financial Summary
              _buildFinancialSummary(),
              const SizedBox(height: 32),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _createOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA16438),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Create Order",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required ContactInfo content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("Name", content.name),
          _buildInfoRow("Phone No", content.phone),
          _buildInfoRow("Email", content.email),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF302E2E),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  quotationImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.quotation.description.isNotEmpty
                          ? widget.quotation.description
                          : "Quotation",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      "Quotation #${widget.quotation.quotationNumber}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF302E2E),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "BOMs: ${widget.quotation.boms.length}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (widget.quotation.expectedDuration != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.quotation.expectedDuration.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFA16438),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Total:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    "₦${_formatMoney(grandTotal)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF302E2E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildItemSchedules(),
        ],
      ),
    );
  }

  Widget _buildItemSchedules() {
    final boms = widget.quotation.boms;
    if (boms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Row(
              children: [
            const Expanded(
              child: Text(
                "BOM Items Schedule",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF302E2E),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _selectAllItems,
                      activeColor: const Color(0xFFA16438),
                      onChanged: (value) {
                        setState(() {
                          _selectAllItems = value ?? false;
                          if (_selectAllItems) {
                            _selectedItemIds
                              ..clear()
                              ..addAll(
                                boms
                                    .map((e) => e.bomId.isNotEmpty
                                        ? e.bomId
                                        : e.bomNumber)
                                    .toList(),
                              );
                          } else {
                            _selectedItemIds.clear();
                          }
                        });
                      },
                    ),
                const Text(
                  "All items",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF302E2E),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...boms.map((bom) {
          final key = bom.bomId.isNotEmpty ? bom.bomId : bom.bomNumber;
          final startDate = _startDates[key];
          final endDate = _endDates[key];
          final isSelected =
              _selectedItemIds.contains(key) && !_selectAllItems;
          final title = bom.name.isNotEmpty
              ? bom.name
              : bom.bomNumber.isNotEmpty
                  ? bom.bomNumber
                  : "BOM";
          final subtitle = bom.product.name.isNotEmpty
              ? bom.product.name
              : bom.description;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFF5F8F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFA16438)
                    : Colors.grey[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _selectedItemIds.contains(key),
                      activeColor: const Color(0xFFA16438),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedItemIds.add(key);
                          } else {
                            _selectedItemIds.remove(key);
                            _selectAllItems = false;
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF302E2E),
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        label: "Start Date",
                        date: startDate,
                        onTap: () => _selectStartDate(bom),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDatePicker(
                        label: "End Date",
                        date: endDate,
                        onTap: () => _selectEndDate(bom),
                        isAutoCalculated:
                            startDate != null && endDate != null,
                      ),
                    ),
                  ],
                ),
                if (startDate != null && endDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "End date auto-calculated based on expected duration. Tap to edit.",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool isAutoCalculated = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isAutoCalculated) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  "Auto",
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFFA16438),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAutoCalculated
                    ? const Color(0xFFA16438).withOpacity(0.3)
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}"
                        : "Select Date",
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null
                          ? const Color(0xFF302E2E)
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            "Total:",
            "₦${_formatMoney(grandTotal)}",
            isBold: true,
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Amount Paid",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountPaidController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final raw = value.replaceAll(RegExp(r'[^0-9]'), '');
                  final parsed = raw.isEmpty ? 0 : int.parse(raw);
                  final formatted = NumberFormat.decimalPattern().format(parsed);
                  _amountPaidController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: formatted.length,
                    ),
                  );
                  setState(() {}); // Recalculate balance
                },
                decoration: InputDecoration(
                  hintText: "15,000",
                  suffixText: "NGN",
                  filled: true,
                  fillColor: const Color(0xFFF5F8F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFA16438),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Balance",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₦${_formatMoney(balance)}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF302E2E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildSummaryRow("Order NO:", widget.quotation.quotationNumber),
          const SizedBox(height: 8),
          _buildSummaryRow("Date issued:", _formatDate(DateTime.now())),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: const Color(0xFF302E2E),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: const Color(0xFF302E2E),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Future<void> _createOrder() async {
    if (!_selectAllItems && _selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one BOM item"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    DateTime? selectedStart;
    DateTime? selectedEnd;

    if (_selectAllItems) {
      final starts = widget.quotation.boms
          .map((bom) => _startDates[bom.bomId.isNotEmpty ? bom.bomId : bom.bomNumber])
          .whereType<DateTime>()
          .toList();
      final ends = widget.quotation.boms
          .map((bom) => _endDates[bom.bomId.isNotEmpty ? bom.bomId : bom.bomNumber])
          .whereType<DateTime>()
          .toList();
      if (starts.length != widget.quotation.boms.length ||
          ends.length != widget.quotation.boms.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select dates for all items"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      starts.sort();
      ends.sort();
      selectedStart = starts.first;
      selectedEnd = ends.last;
    } else {
      final starts = _selectedItemIds
          .map((id) => _startDates[id])
          .whereType<DateTime>()
          .toList();
      final ends = _selectedItemIds
          .map((id) => _endDates[id])
          .whereType<DateTime>()
          .toList();
      if (starts.length != _selectedItemIds.length ||
          ends.length != _selectedItemIds.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select dates for all selected items"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      starts.sort();
      ends.sort();
      selectedStart = starts.first;
      selectedEnd = ends.last;
    }

    // Validate dates
    if (selectedStart == null || selectedEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both start and end dates"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (selectedEnd.isBefore(selectedStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("End date must be after start date"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final rawPaid =
          _amountPaidController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final double amountPaid = rawPaid.isEmpty ? 0.0 : double.parse(rawPaid);
      final allBomIds = widget.quotation.boms
          .map((bom) => bom.bomId.isNotEmpty ? bom.bomId : bom.bomNumber)
          .toList();
      final selectedBomIds = _selectAllItems
          ? allBomIds
          : _selectedItemIds.toList();

      final response = await _orderService.createOrderFromQuotation(
        quotationId: widget.quotation.id,
        startDate: selectedStart.toIso8601String(),
        endDate: selectedEnd.toIso8601String(),
        bomIds: selectedBomIds,
        notes: _selectAllItems
            ? "Order created from quotation ${widget.quotation.quotationNumber} (all items)"
            : "Order created from quotation ${widget.quotation.quotationNumber} (items ${selectedBomIds.join(', ')})",
        amountPaid: amountPaid,
      );

      setState(() => isLoading = false);

      if (response["success"] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text("Order created successfully")),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Nav.offAll(const DashboardScreen(initialIndex: 2));

      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ ${response["message"] ?? "Failed to create order"}",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ContactInfo model
class ContactInfo {
  final String name;
  final String address;
  final String nearestBusStop;
  final String phone;
  final String email;

  ContactInfo({
    required this.name,
    required this.address,
    required this.nearestBusStop,
    required this.phone,
    required this.email,
  });
}
