import 'package:flutter/material.dart';
import 'package:wworker/App/Order/Api/OrderService.dart';
import 'package:wworker/App/Order/Model/StaffModel.dart';
import 'package:wworker/App/Order/Model/orderModel.dart' show OrderModel;


class AssignStaffSheet extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onAssigned;

  const AssignStaffSheet({
    super.key,
    required this.order,
    required this.onAssigned,
  });

  @override
  State<AssignStaffSheet> createState() => _AssignStaffSheetState();
}

class _AssignStaffSheetState extends State<AssignStaffSheet> {
  final OrderService _orderService = OrderService();
  final TextEditingController _notesController = TextEditingController();
  
  List<StaffModel> staffList = [];
  Map<String, int> staffWorkload = {}; // staffId -> pending orders count
  StaffModel? selectedStaff;
  bool isLoading = true;
  bool isAssigning = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableStaff();
    
    // Pre-select if already assigned
    if (widget.order.assignedTo != null) {
      selectedStaff = widget.order.assignedTo;
      _notesController.text = widget.order.assignmentNotes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableStaff() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _orderService.getAvailableStaff();

      if (result['success'] == true) {
        final List<dynamic> staffJson = result['data'] ?? [];
        final List<StaffModel> loadedStaff = 
            staffJson.map((e) => StaffModel.fromJson(e)).toList();
        
        // Load workload for each staff
        await _loadStaffWorkloads(loadedStaff);
        
        setState(() {
          staffList = loadedStaff;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = result['message'] ?? 'Failed to load staff';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _loadStaffWorkloads(List<StaffModel> staff) async {
    try {
      // Fetch all orders to calculate workload
      final ordersResult = await _orderService.getAllOrders();
      
      if (ordersResult['success'] == true) {
        final data = ordersResult['data'];
        final List<dynamic> ordersJson = data['orders'] ?? [];
        final workloadMap = <String, int>{};
        
        // Count pending/in-progress orders for each staff
        for (var orderJson in ordersJson) {
          final order = OrderModel.fromJson(orderJson);
          
          // Only count orders that are pending or in-progress
          if ((order.status == 'pending' || order.status == 'in_progress') &&
              order.assignedTo != null) {
            final staffId = order.assignedTo!.id;
            workloadMap[staffId] = (workloadMap[staffId] ?? 0) + 1;
          }
        }
        
        setState(() {
          staffWorkload = workloadMap;
        });
      }
    } catch (e) {
      debugPrint('Error loading staff workloads: $e');
      // Continue without workload data
    }
  }

  Future<void> _assignStaff() async {
    if (selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a staff member'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show warning if staff has high workload
    final workload = staffWorkload[selectedStaff!.id] ?? 0;
    if (workload >= 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: workload >= 3 ? Colors.red : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Pending Orders Warning'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${selectedStaff!.displayName} currently has $workload pending order${workload > 1 ? 's' : ''}.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: workload >= 3 
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: workload >= 3 
                        ? Colors.red.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      workload >= 3 
                          ? Icons.error_outline 
                          : Icons.info_outline,
                      color: workload >= 3 ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        workload >= 3
                            ? 'This staff member has a high workload. Consider assigning to someone else.'
                            : 'This staff member has pending orders.',
                        style: TextStyle(
                          fontSize: 13,
                          color: workload >= 3 
                              ? Colors.red[900] 
                              : Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to assign this order?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA16438),
              ),
              child: const Text('Assign Anyway',style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
    }

    setState(() => isAssigning = true);

    try {
      final result = await _orderService.assignOrderToStaff(
        orderId: widget.order.id,
        staffId: selectedStaff!.id,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      setState(() => isAssigning = false);

      if (result['success'] == true) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order assigned to ${selectedStaff!.displayName}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onAssigned();
      } else {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to assign order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isAssigning = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unassignStaff() async {
    setState(() => isAssigning = true);

    try {
      final result = await _orderService.unassignOrderFromStaff(
        orderId: widget.order.id,
      );

      setState(() => isAssigning = false);

      if (result['success'] == true) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff unassigned from order'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onAssigned();
      } else {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to unassign order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isAssigning = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA16438).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add,
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
                        widget.order.isAssigned 
                            ? 'Reassign Staff' 
                            : 'Assign Staff',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF302E2E),
                        ),
                      ),
                      Text(
                        'Order #${widget.order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current assignment info
                  if (widget.order.isAssigned) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFA16438).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFA16438),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Currently assigned to',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFA16438),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.order.assignedTo!.displayName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF302E2E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Staff selection
                  const Text(
                    'Select Staff Member',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF302E2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Color(0xFFA16438),
                        ),
                      ),
                    )
                  else if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (staffList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No staff members available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...staffList.map((staff) => _buildStaffTile(staff)),
                  
                  const SizedBox(height: 24),
                  
                  // Notes field
                  const Text(
                    'Assignment Notes (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF302E2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add any special instructions or notes...',
                      filled: true,
                      fillColor: const Color(0xFFF5F8F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFA16438),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      if (widget.order.isAssigned)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isAssigning ? null : _unassignStaff,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isAssigning
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Text(
                                    'Unassign',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      if (widget.order.isAssigned) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isAssigning ? null : _assignStaff,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA16438),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isAssigning
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.order.isAssigned 
                                      ? 'Reassign' 
                                      : 'Assign Staff',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffTile(StaffModel staff) {
    final isSelected = selectedStaff?.id == staff.id;
    final workload = staffWorkload[staff.id] ?? 0;
    final hasPendingOrders = workload > 0;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStaff = staff;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFA16438).withOpacity(0.1) 
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFA16438) 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFFA16438) 
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      staff.displayName.isNotEmpty 
                          ? staff.displayName[0].toUpperCase() 
                          : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                // Warning icon for pending orders
                if (hasPendingOrders)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: workload >= 3 ? Colors.red : Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          staff.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? const Color(0xFFA16438) 
                                : const Color(0xFF302E2E),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: staff.role == 'admin'
                              ? Colors.blue[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          staff.roleText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: staff.role == 'admin'
                                ? Colors.blue[700]
                                : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (staff.position.isNotEmpty)
                    Text(
                      staff.position,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          staff.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Pending orders badge
                      if (hasPendingOrders) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: workload >= 3 
                                ? Colors.red[50] 
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: workload >= 3 
                                  ? Colors.red[200]! 
                                  : Colors.orange[200]!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pending_actions,
                                size: 12,
                                color: workload >= 3 
                                    ? Colors.red[700] 
                                    : Colors.orange[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$workload pending',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: workload >= 3 
                                      ? Colors.red[700] 
                                      : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFA16438),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}