import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Order/Model/orderModel.dart';
import 'package:wworker/Constant/urls.dart';



class OrderCard extends StatelessWidget {
  
  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onAddPayment;
  final VoidCallback? onUpdateStatus;
  final VoidCallback? onViewReceipt;
  final VoidCallback? onAssignStaff; // NEW
  final bool showFinancialInfo;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onDelete,
    this.onAddPayment,
    this.onUpdateStatus,
    this.onViewReceipt,
    this.onAssignStaff, // NEW
    this.showFinancialInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final image = (firstItem?['image']?.isNotEmpty ?? false)
        ? firstItem!['image']
        : Urls.woodImg;

    Color statusColor;
    String statusText;

    switch (order.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
        statusText = 'Completed';
        break;
      case 'in_progress':
        statusColor = AppColors.warning;
        statusText = 'In Progress';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusText = 'Cancelled';
        break;
      case 'on_hold':
        statusColor = AppColors.info;
        statusText = 'On Hold';
        break;
      default:
        statusColor = AppColors.primary;
        statusText = 'Pending';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Delete Button & Assignment Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    image,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                ),
                
                // NEW: Assignment Badge (Top Left)
                if (order.isAssigned)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person,
                            size: 14,
                            color: Color(0xFFA16438),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.assignedTo!.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFA16438),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Delete Button (Top Right)
                if (onDelete != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => _showDeleteConfirmation(context),
                      icon: const Icon(Icons.delete_outline),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailRow("Client:", order.clientName),
                  const SizedBox(height: 16),
                  _buildDetailRow("Order No:", order.orderNumber),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    "Start Date:",
                    order.startDate != null
                        ? DateFormat('MMMM d, yyyy').format(order.startDate!)
                        : 'N/A',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    "End Date:",
                    order.endDate != null
                        ? DateFormat('MMMM d, yyyy').format(order.endDate!)
                        : 'N/A',
                  ),
                  
                  // Conditionally show financial information
                  if (showFinancialInfo) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      "Amount Paid:",
                      "₦${_formatNumber(order.amountPaid)}",
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow("Email:", order.email),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      "Balance:",
                      "₦${_formatNumber(order.balance)}",
                      valueColor: AppColors.primary,
                      valueBold: true,
                    ),
                  ],
                  
                  // NEW: Show Assignment Info
                  if (order.isAssigned) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFA16438).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Color(0xFFA16438),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Assigned to',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFA16438),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  order.assignedTo!.displayName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF302E2E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (order.assignedTo!.position.isNotEmpty)
                                  Text(
                                    order.assignedTo!.position,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (onAssignStaff != null)
                            IconButton(
                              onPressed: onAssignStaff,
                              icon: const Icon(Icons.edit_outlined),
                              iconSize: 18,
                              color: const Color(0xFFA16438),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  _buildStatusRow("Status:", statusText, statusColor),

                  // Action Buttons
                  if (onAddPayment != null || 
                      onUpdateStatus != null || 
                      onViewReceipt != null ||
                      onAssignStaff != null) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    
                    // Different button layouts based on showFinancialInfo
                    if (showFinancialInfo)
                      _buildFinancialActions()
                    else
                      _buildOrderManagementActions(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action buttons for Sales page (financial management)
  Widget _buildFinancialActions() {
    return Column(
      children: [
        Row(
          children: [
            if (onAddPayment != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: order.balance > 0 ? onAddPayment : null,
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text("Add Payment"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ),
            if (onAddPayment != null && onViewReceipt != null)
              const SizedBox(width: 12),
            if (onViewReceipt != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: order.amountPaid > 0 ? onViewReceipt : null,
                  icon: const Icon(Icons.receipt_outlined, size: 18),
                  label: const Text("View Receipt"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: BorderSide(color: AppColors.info),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledForegroundColor: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Action buttons for All Orders page (order management)
  Widget _buildOrderManagementActions() {
    return Column(
      children: [
        Row(
          children: [
            if (onUpdateStatus != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onUpdateStatus,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text("Update Status"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            // NEW: Assign Staff Button
            if (onUpdateStatus != null && onAssignStaff != null)
              const SizedBox(width: 12),
            if (onAssignStaff != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAssignStaff,
                  icon: Icon(
                    order.isAssigned ? Icons.person : Icons.person_add,
                    size: 18,
                  ),
                  label: Text(order.isAssigned ? "Reassign" : "Assign Staff"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String statusText, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
          'Are you sure you want to delete order ${order.orderNumber}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onDelete != null) onDelete!();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// App Colors Class
class AppColors {
  static const Color primary = Color(0xFFA16438);
  static const Color textPrimary = Color(0xFF302E2E);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFF7CB342);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
}