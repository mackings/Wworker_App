import 'package:flutter/material.dart';
import 'package:wworker/App/Order/Api/OrderService.dart';
import 'package:wworker/App/Order/Model/orderModel.dart' hide OrderService;

class UpdateOrderStatusSheet extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onStatusUpdated;

  const UpdateOrderStatusSheet({
    super.key,
    required this.order,
    required this.onStatusUpdated,
  });

  @override
  State<UpdateOrderStatusSheet> createState() => _UpdateOrderStatusSheetState();
}

class _UpdateOrderStatusSheetState extends State<UpdateOrderStatusSheet> {
  final OrderService _orderService = OrderService();
  String? selectedStatus;
  bool isLoading = false;

  final List<Map<String, dynamic>> statuses = [
    {
      'value': 'pending',
      'label': 'Pending',
      'icon': Icons.schedule,
      'color': Color(0xFF2196F3),
    },
    {
      'value': 'in_progress',
      'label': 'In Progress',
      'icon': Icons.autorenew,
      'color': Color(0xFF7CB342),
    },
    {
      'value': 'completed',
      'label': 'Completed',
      'icon': Icons.check_circle,
      'color': Color(0xFF4CAF50),
    },
    {
      'value': 'on_hold',
      'label': 'On Hold',
      'icon': Icons.pause_circle,
      'color': Color(0xFFFF9800),
    },
    {
      'value': 'cancelled',
      'label': 'Cancelled',
      'icon': Icons.cancel,
      'color': Color(0xFFF44336),
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.order.status;
  }

  Future<void> _updateStatus() async {
    if (selectedStatus == null || selectedStatus == widget.order.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a different status'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await _orderService.updateOrderStatus(
      orderId: widget.order.id,
      status: selectedStatus!,
    );

    setState(() => isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onStatusUpdated();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return DraggableScrollableSheet(
      expand: false,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      initialChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: media.viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Update Order Status",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF302E2E),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Order: ${widget.order.orderNumber}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Status options
                ...statuses.map((status) {
                  final isSelected = selectedStatus == status['value'];
                  final isCurrent = widget.order.status == status['value'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? status['color']
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? status['color'].withOpacity(0.05)
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: Icon(
                        status['icon'],
                        color: status['color'],
                      ),
                      title: Text(
                        status['label'],
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: const Color(0xFF302E2E),
                        ),
                      ),
                      trailing: isCurrent
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: status['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: status['color'],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : isSelected
                              ? Icon(Icons.check_circle, color: status['color'])
                              : null,
                      onTap: () {
                        setState(() {
                          selectedStatus = status['value'];
                        });
                      },
                    ),
                  );
                }).toList(),

                const SizedBox(height: 30),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _updateStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA16438),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Update Status",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
