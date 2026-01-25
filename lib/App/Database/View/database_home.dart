import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Database/Api/database_service.dart';
import 'package:wworker/App/Database/Model/database_models.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';



class DatabaseHomePage extends StatelessWidget {
  const DatabaseHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: ColorsApp.bgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Database',
            style: TextStyle(
              color: Color(0xFF302E2E),
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: const TabBar(
            labelColor: ColorsApp.btnColor,
            unselectedLabelColor: Colors.black45,
            indicatorColor: ColorsApp.btnColor,
            tabs: [
              Tab(text: 'Quotations'),
              Tab(text: 'BOMs'),
              Tab(text: 'Clients'),
              Tab(text: 'Users'),
              Tab(text: 'Products'),
              Tab(text: 'Materials'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DatabaseQuotationsTab(),
            DatabaseBomsTab(),
            DatabaseClientsTab(),
            DatabaseStaffTab(),
            DatabaseProductsTab(),
            DatabaseMaterialsTab(),
          ],
        ),
      ),
    );
  }
}

class DatabaseQuotationsTab extends StatefulWidget {
  const DatabaseQuotationsTab({super.key});

  @override
  State<DatabaseQuotationsTab> createState() => _DatabaseQuotationsTabState();
}

class _DatabaseQuotationsTabState extends State<DatabaseQuotationsTab> {
  final DatabaseService _service = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<DatabaseQuotation> _quotations = [];

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getQuotations(search: search);
      setState(() {
        _quotations = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load quotations';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteQuotation(DatabaseQuotation quotation) async {
    final confirm = await _showDeleteDialog(
      context,
      title: 'Delete quotation?',
      message:
          'This will permanently remove ${quotation.quotationNumber} from your database.',
    );
    if (!confirm) return;

    final success = await _service.deleteQuotation(quotation.id);
    if (!mounted) return;
    _showSnack(
      context,
      success ? 'Quotation deleted' : 'Failed to delete quotation',
    );
    if (success) {
      _loadQuotations(search: _searchController.text);
    }
  }

  Future<void> _editQuotation(DatabaseQuotation quotation) async {
    final clientNameController =
        TextEditingController(text: quotation.clientName);
    final clientAddressController =
        TextEditingController(text: quotation.clientAddress);
    final busStopController =
        TextEditingController(text: quotation.nearestBusStop);
    final phoneController =
        TextEditingController(text: quotation.phoneNumber);
    final emailController = TextEditingController(text: quotation.email);
    final descriptionController =
        TextEditingController(text: quotation.description);
    final discountController =
        TextEditingController(text: quotation.discount.toString());

    String statusValue = quotation.status;
    final statusOptions = <String>{
      'draft',
      'sent',
      'approved',
      'rejected',
      'pending',
      'completed',
      'cancelled',
      statusValue,
    }.toList();
    DateTime? dueDate = quotation.dueDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSheetHandle(),
                        const SizedBox(height: 12),
                        Text(
                          'Edit Quotation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ColorsApp.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Client Name',
                          controller: clientNameController,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Client Address',
                          controller: clientAddressController,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Nearest Bus Stop',
                          controller: busStopController,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Phone Number',
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Email',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Description',
                          controller: descriptionController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Discount (%)',
                          controller: discountController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Status',
                      isDropdown: true,
                      dropdownItems: statusOptions,
                      value: statusValue,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => statusValue = value);
                        }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDatePicker(
                          context,
                          label: 'Due Date',
                          date: dueDate,
                          onDateSelected: (picked) =>
                              setModalState(() => dueDate = picked),
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: 'Save Changes',
                          onPressed: () async {
                            final updates = <String, dynamic>{};

                            _setIfChanged(
                              updates,
                              'clientName',
                              clientNameController.text,
                              quotation.clientName,
                            );
                            _setIfChanged(
                              updates,
                              'clientAddress',
                              clientAddressController.text,
                              quotation.clientAddress,
                            );
                            _setIfChanged(
                              updates,
                              'nearestBusStop',
                              busStopController.text,
                              quotation.nearestBusStop,
                            );
                            _setIfChanged(
                              updates,
                              'phoneNumber',
                              phoneController.text,
                              quotation.phoneNumber,
                            );
                            _setIfChanged(
                              updates,
                              'email',
                              emailController.text,
                              quotation.email,
                            );
                            _setIfChanged(
                              updates,
                              'description',
                              descriptionController.text,
                              quotation.description,
                            );

                            final discountValue =
                                double.tryParse(discountController.text.trim());
                            if (discountValue != null &&
                                discountValue != quotation.discount) {
                              updates['discount'] = discountValue;
                            }

                            if (statusValue != quotation.status) {
                              updates['status'] = statusValue;
                            }

                            if (dueDate != null && dueDate != quotation.dueDate) {
                              updates['dueDate'] =
                                  DateFormat('yyyy-MM-dd').format(dueDate!);
                            }

                            if (updates.isEmpty) {
                              Navigator.pop(context);
                              return;
                            }

                            final success = await _service.updateQuotation(
                              quotation.id,
                              updates,
                            );

                            if (!mounted) return;
                            Navigator.pop(context);
                            _showSnack(
                              context,
                              success
                                  ? 'Quotation updated'
                                  : 'Failed to update quotation',
                            );
                            if (success) {
                              _loadQuotations(search: _searchController.text);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchRow(
          controller: _searchController,
          onSearch: () => _loadQuotations(search: _searchController.text),
        ),
        Expanded(
          child: RefreshIndicator(
            color: ColorsApp.btnColor,
            onRefresh: () => _loadQuotations(search: _searchController.text),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorView(_error!);
    }
    if (_quotations.isEmpty) {
      return _buildEmptyView('No quotations found');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _quotations.length,
      itemBuilder: (context, index) {
        final quotation = _quotations[index];
        return _DatabaseCard(
          leading: _QuotationImage(url: quotation.imageUrl),
          title: quotation.quotationNumber.isEmpty
              ? 'Quotation'
              : quotation.quotationNumber,
          subtitle: quotation.clientName,
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusChip(quotation.status),
              const SizedBox(height: 6),
              Text(
                '₦${_formatAmount(quotation.finalTotal)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          details: _buildQuotationDetails(quotation),
          onEdit: () => _editQuotation(quotation),
          onDelete: () => _deleteQuotation(quotation),
          footer: quotation.dueDate == null
              ? null
              : 'Due ${DateFormat('dd MMM, yyyy').format(quotation.dueDate!)}',
        );
      },
    );
  }
}

class DatabaseBomsTab extends StatefulWidget {
  const DatabaseBomsTab({super.key});

  @override
  State<DatabaseBomsTab> createState() => _DatabaseBomsTabState();
}

class _DatabaseBomsTabState extends State<DatabaseBomsTab> {
  final DatabaseService _service = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<DatabaseBom> _boms = [];

  @override
  void initState() {
    super.initState();
    _loadBoms();
  }

  Future<void> _loadBoms({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getBoms(search: search);
      setState(() {
        _boms = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load BOMs';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBom(DatabaseBom bom) async {
    final confirm = await _showDeleteDialog(
      context,
      title: 'Delete BOM?',
      message: 'This will remove ${bom.bomNumber} from your database.',
    );
    if (!confirm) return;

    final success = await _service.deleteBom(bom.id);
    if (!mounted) return;
    _showSnack(
      context,
      success ? 'BOM deleted' : 'Failed to delete BOM',
    );
    if (success) {
      _loadBoms(search: _searchController.text);
    }
  }

  Future<void> _editBom(DatabaseBom bom) async {
    final nameController = TextEditingController(text: bom.name);
    final descriptionController =
        TextEditingController(text: bom.description);
    DateTime? dueDate = bom.dueDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSheetHandle(),
                        const SizedBox(height: 12),
                        Text(
                          'Edit BOM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ColorsApp.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Name',
                          controller: nameController,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Description',
                          controller: descriptionController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        _buildDatePicker(
                          context,
                          label: 'Due Date',
                          date: dueDate,
                          onDateSelected: (picked) =>
                              setModalState(() => dueDate = picked),
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: 'Save Changes',
                          onPressed: () async {
                            final updates = <String, dynamic>{};
                            _setIfChanged(
                              updates,
                              'name',
                              nameController.text,
                              bom.name,
                            );
                            _setIfChanged(
                              updates,
                              'description',
                              descriptionController.text,
                              bom.description,
                            );

                            if (dueDate != bom.dueDate && dueDate != null) {
                              updates['dueDate'] =
                                  DateFormat('yyyy-MM-dd').format(dueDate!);
                            }

                            if (updates.isEmpty) {
                              Navigator.pop(context);
                              return;
                            }

                            final success =
                                await _service.updateBom(bom.id, updates);
                            if (!mounted) return;
                            Navigator.pop(context);
                            _showSnack(
                              context,
                              success ? 'BOM updated' : 'Failed to update BOM',
                            );
                            if (success) {
                              _loadBoms(search: _searchController.text);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchRow(
          controller: _searchController,
          onSearch: () => _loadBoms(search: _searchController.text),
        ),
        Expanded(
          child: RefreshIndicator(
            color: ColorsApp.btnColor,
            onRefresh: () => _loadBoms(search: _searchController.text),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorView(_error!);
    }
    if (_boms.isEmpty) {
      return _buildEmptyView('No BOMs found');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _boms.length,
      itemBuilder: (context, index) {
        final bom = _boms[index];
        return _DatabaseCard(
          leading: _QuotationImage(url: bom.productImage),
          title: bom.bomNumber.isEmpty ? 'BOM' : bom.bomNumber,
          subtitle: bom.productName?.isNotEmpty == true ? bom.productName! : bom.name,
          trailing: Text(
            '₦${_formatAmount(bom.totalCost)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          details: _buildBomDetails(bom),
          onEdit: () => _editBom(bom),
          onDelete: () => _deleteBom(bom),
          footer: bom.dueDate == null
              ? null
              : 'Due ${DateFormat('dd MMM, yyyy').format(bom.dueDate!)}',
        );
      },
    );
  }
}

class DatabaseClientsTab extends StatefulWidget {
  const DatabaseClientsTab({super.key});

  @override
  State<DatabaseClientsTab> createState() => _DatabaseClientsTabState();
}

class _DatabaseClientsTabState extends State<DatabaseClientsTab> {
  final DatabaseService _service = DatabaseService();
  bool _isLoading = true;
  String? _error;
  List<DatabaseClient> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getClients();
      setState(() {
        _clients = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load clients';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteClient(DatabaseClient client) async {
    final confirm = await _showDeleteDialog(
      context,
      title: 'Delete client?',
      message: 'This removes all quotations linked to ${client.clientName}.',
    );
    if (!confirm) return;

    final match = _clientMatch(client);
    final success = await _service.deleteClient(match: match);
    if (!mounted) return;
    _showSnack(
      context,
      success ? 'Client deleted' : 'Failed to delete client',
    );
    if (success) {
      _loadClients();
    }
  }

  Map<String, dynamic> _clientMatch(DatabaseClient client) {
    if (client.phoneNumber.isNotEmpty) {
      return {'clientName': client.clientName, 'phoneNumber': client.phoneNumber};
    }
    if (client.email.isNotEmpty) {
      return {'clientName': client.clientName, 'email': client.email};
    }
    return {'clientName': client.clientName};
  }

  Future<void> _editClient(DatabaseClient client) async {
    final nameController = TextEditingController(text: client.clientName);
    final addressController = TextEditingController(text: client.clientAddress);
    final busStopController = TextEditingController(text: client.nearestBusStop);
    final phoneController = TextEditingController(text: client.phoneNumber);
    final emailController = TextEditingController(text: client.email);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.55,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSheetHandle(),
                    const SizedBox(height: 12),
                    Text(
                      'Edit Client',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColorsApp.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Client Name',
                      controller: nameController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Client Address',
                      controller: addressController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Nearest Bus Stop',
                      controller: busStopController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Phone Number',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Email',
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: () async {
                        final updates = <String, dynamic>{};
                        _setIfChanged(
                          updates,
                          'clientName',
                          nameController.text,
                          client.clientName,
                        );
                        _setIfChanged(
                          updates,
                          'clientAddress',
                          addressController.text,
                          client.clientAddress,
                        );
                        _setIfChanged(
                          updates,
                          'nearestBusStop',
                          busStopController.text,
                          client.nearestBusStop,
                        );
                        _setIfChanged(
                          updates,
                          'phoneNumber',
                          phoneController.text,
                          client.phoneNumber,
                        );
                        _setIfChanged(
                          updates,
                          'email',
                          emailController.text,
                          client.email,
                        );

                        if (updates.isEmpty) {
                          Navigator.pop(context);
                          return;
                        }

                        final success = await _service.updateClient(
                          match: _clientMatch(client),
                          update: updates,
                        );

                        if (!mounted) return;
                        Navigator.pop(context);
                        _showSnack(
                          context,
                          success ? 'Client updated' : 'Failed to update client',
                        );
                        if (success) {
                          _loadClients();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: ColorsApp.btnColor,
      onRefresh: _loadClients,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorView(_error!);
    }
    if (_clients.isEmpty) {
      return _buildEmptyView('No clients found');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        final contact =
            client.phoneNumber.isNotEmpty ? client.phoneNumber : client.email;
        return _DatabaseCard(
          title: client.clientName,
          subtitle: contact,
          onEdit: () => _editClient(client),
          onDelete: () => _deleteClient(client),
          footer: client.clientAddress.isEmpty
              ? null
              : 'Address: ${client.clientAddress}',
        );
      },
    );
  }
}

class DatabaseStaffTab extends StatefulWidget {
  const DatabaseStaffTab({super.key});

  @override
  State<DatabaseStaffTab> createState() => _DatabaseStaffTabState();
}

class _DatabaseStaffTabState extends State<DatabaseStaffTab> {
  final DatabaseService _service = DatabaseService();
  bool _isLoading = true;
  String? _error;
  List<DatabaseStaff> _staff = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getStaff();
      setState(() {
        _staff = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load staff';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteStaff(DatabaseStaff staff) async {
    final confirm = await _showDeleteDialog(
      context,
      title: 'Remove staff?',
      message: 'This will revoke access for ${staff.fullname}.',
    );
    if (!confirm) return;

    final success = await _service.deleteStaff(staff.id);
    if (!mounted) return;
    _showSnack(
      context,
      success ? 'Staff removed' : 'Failed to remove staff',
    );
    if (success) {
      _loadStaff();
    }
  }

  Future<void> _editStaff(DatabaseStaff staff) async {
    final roleController = TextEditingController(text: staff.role);
    final positionController = TextEditingController(text: staff.position);
    bool accessGranted = staff.accessGranted;
    final permissions = {
      'quotation': staff.permissions.quotation,
      'sales': staff.permissions.sales,
      'order': staff.permissions.order,
      'invoice': staff.permissions.invoice,
      'products': staff.permissions.products,
      'boms': staff.permissions.boms,
      'database': staff.permissions.database,
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSheetHandle(),
                        const SizedBox(height: 12),
                        Text(
                          staff.fullname,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ColorsApp.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          staff.email,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Role',
                          isDropdown: true,
                          dropdownItems: const ['owner', 'admin', 'staff'],
                          value: roleController.text,
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() => roleController.text = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Position',
                          controller: positionController,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Access Granted',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          activeColor: ColorsApp.btnColor,
                          value: accessGranted,
                          onChanged: (value) {
                            setModalState(() => accessGranted = value);
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Permissions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPermissionSwitches(
                          permissions,
                          onChanged: (key, value) {
                            setModalState(() => permissions[key] = value);
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: 'Save Changes',
                          onPressed: () async {
                            final updates = <String, dynamic>{
                              'role': roleController.text,
                              'position': positionController.text,
                              'accessGranted': accessGranted,
                              'permissions': permissions,
                            };

                            final success = await _service.updateStaff(
                              userId: staff.id,
                              body: updates,
                            );

                            if (!mounted) return;
                            Navigator.pop(context);
                            _showSnack(
                              context,
                              success ? 'Staff updated' : 'Failed to update staff',
                            );
                            if (success) {
                              _loadStaff();
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: ColorsApp.btnColor,
      onRefresh: _loadStaff,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorView(_error!);
    }
    if (_staff.isEmpty) {
      return _buildEmptyView('No staff found');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _staff.length,
      itemBuilder: (context, index) {
        final staff = _staff[index];
        return _DatabaseCard(
          title: staff.fullname,
          subtitle: staff.position.isEmpty ? staff.role : staff.position,
          trailing: _buildStatusChip(staff.accessGranted ? 'active' : 'blocked'),
          onEdit: () => _editStaff(staff),
          onDelete: () => _deleteStaff(staff),
          footer: staff.phoneNumber.isEmpty
              ? null
              : 'Phone: ${staff.phoneNumber}',
        );
      },
    );
  }
}

class DatabaseProductsTab extends StatefulWidget {
  const DatabaseProductsTab({super.key});

  @override
  State<DatabaseProductsTab> createState() => _DatabaseProductsTabState();
}

class _DatabaseProductsTabState extends State<DatabaseProductsTab> {
  final DatabaseService _service = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<DatabaseProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getProducts(search: search);
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load products';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(DatabaseProduct product) async {
    final confirm = await _showDeleteDialog(
      context,
      title: 'Delete product?',
      message: 'This will remove ${product.name} from your database.',
    );
    if (!confirm) return;

    final success = await _service.deleteProduct(product.id);
    if (!mounted) return;
    _showSnack(
      context,
      success ? 'Product deleted' : 'Failed to delete product',
    );
    if (success) {
      _loadProducts(search: _searchController.text);
    }
  }

  Future<void> _editProduct(DatabaseProduct product) async {
    final nameController = TextEditingController(text: product.name);
    final categoryController = TextEditingController(text: product.category);
    final subCategoryController =
        TextEditingController(text: product.subCategory);
    final descriptionController =
        TextEditingController(text: product.description);
    final productIdController = TextEditingController(text: product.productId);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSheetHandle(),
                    const SizedBox(height: 12),
                    Text(
                      'Edit Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColorsApp.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Name',
                      controller: nameController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Category',
                      controller: categoryController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Sub Category',
                      controller: subCategoryController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Description',
                      controller: descriptionController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Product ID',
                      controller: productIdController,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: () async {
                        final updates = <String, dynamic>{};
                        _setIfChanged(
                          updates,
                          'name',
                          nameController.text,
                          product.name,
                        );
                        _setIfChanged(
                          updates,
                          'category',
                          categoryController.text,
                          product.category,
                        );

                        _setIfChanged(
                          updates,
                          'subCategory',
                          subCategoryController.text,
                          product.subCategory,
                        );

                        _setIfChanged(
                          updates,
                          'description',
                          descriptionController.text,
                          product.description,
                        );
                        _setIfChanged(
                          updates,
                          'productId',
                          productIdController.text,
                          product.productId,
                        );

                        if (updates.isEmpty) {
                          Navigator.pop(context);
                          return;
                        }

                        final success = await _service.updateProduct(
                          id: product.id,
                          body: updates,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        _showSnack(
                          context,
                          success
                              ? 'Product updated'
                              : 'Failed to update product',
                        );
                        if (success) {
                          _loadProducts(search: _searchController.text);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchRow(
          controller: _searchController,
          onSearch: () => _loadProducts(search: _searchController.text),
        ),
        Expanded(
          child: RefreshIndicator(
            color: ColorsApp.btnColor,
            onRefresh: () => _loadProducts(search: _searchController.text),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorView(_error!);
    }
    if (_products.isEmpty) {
      return _buildEmptyView('No products found');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _DatabaseCard(
          leading: _QuotationImage(url: product.image),
          title: product.name,
          subtitle:
              product.category.isEmpty ? product.subCategory : product.category,
          trailing: _buildStatusChip(product.status),
          details: _buildProductDetails(product),
          onEdit: () => _editProduct(product),
          onDelete: () => _deleteProduct(product),
        );
      },
    );
  }
}

class DatabaseMaterialsTab extends StatefulWidget {
  const DatabaseMaterialsTab({super.key});

  @override
  State<DatabaseMaterialsTab> createState() => _DatabaseMaterialsTabState();
}

class _DatabaseMaterialsTabState extends State<DatabaseMaterialsTab> {
  final DatabaseService _service = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<DatabaseMaterial> _materials = [];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getMaterials(search: search);
      setState(() {
        _materials = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load materials';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMaterial(DatabaseMaterial material) async {
    final confirm = await _showDeleteDialog(
      context,
      title: 'Delete material?',
      message: 'This will remove ${material.name} from your database.',
    );
    if (!confirm) return;

    final success = await _service.deleteMaterial(material.id);
    if (!mounted) return;
    _showSnack(
      context,
      success ? 'Material deleted' : 'Failed to delete material',
    );
    if (success) {
      _loadMaterials(search: _searchController.text);
    }
  }

  Future<void> _editMaterial(DatabaseMaterial material) async {
    final nameController = TextEditingController(text: material.name);
    final categoryController = TextEditingController(text: material.category);
    final priceController =
        TextEditingController(text: material.pricePerSqm.toString());
    final widthController =
        TextEditingController(text: material.standardWidth?.toString() ?? '');
    final lengthController =
        TextEditingController(text: material.standardLength?.toString() ?? '');
    final unitController =
        TextEditingController(text: material.standardUnit ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSheetHandle(),
                    const SizedBox(height: 12),
                    Text(
                      'Edit Material',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColorsApp.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Name',
                      controller: nameController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Category',
                      controller: categoryController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Price Per Sqm',
                      controller: priceController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Standard Width',
                      controller: widthController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Standard Length',
                      controller: lengthController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Standard Unit',
                      controller: unitController,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: () async {
                        final updates = <String, dynamic>{};
                        _setIfChanged(
                          updates,
                          'name',
                          nameController.text,
                          material.name,
                        );
                        _setIfChanged(
                          updates,
                          'category',
                          categoryController.text,
                          material.category,
                        );

                        final price =
                            double.tryParse(priceController.text.trim());
                        if (price != null && price != material.pricePerSqm) {
                          updates['pricePerSqm'] = price;
                        }

                        final width =
                            double.tryParse(widthController.text.trim());
                        if (width != material.standardWidth &&
                            widthController.text.trim().isNotEmpty) {
                          updates['standardWidth'] = width;
                        }

                        final length =
                            double.tryParse(lengthController.text.trim());
                        if (length != material.standardLength &&
                            lengthController.text.trim().isNotEmpty) {
                          updates['standardLength'] = length;
                        }

                        _setIfChanged(
                          updates,
                          'standardUnit',
                          unitController.text,
                          material.standardUnit ?? '',
                        );

                        if (updates.isEmpty) {
                          Navigator.pop(context);
                          return;
                        }

                        final success = await _service.updateMaterial(
                          id: material.id,
                          body: updates,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        _showSnack(
                          context,
                          success
                              ? 'Material updated'
                              : 'Failed to update material',
                        );
                        if (success) {
                          _loadMaterials(search: _searchController.text);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchRow(
          controller: _searchController,
          onSearch: () => _loadMaterials(search: _searchController.text),
        ),
        Expanded(
          child: RefreshIndicator(
            color: ColorsApp.btnColor,
            onRefresh: () => _loadMaterials(search: _searchController.text),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorView(_error!);
    }
    if (_materials.isEmpty) {
      return _buildEmptyView('No materials found');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final material = _materials[index];
        return _DatabaseCard(
          leading: _MaterialAvatar(category: material.category),
          title: material.name,
          subtitle: material.category,
          trailing: _buildStatusChip(
            material.status.isEmpty ? 'pending' : material.status,
          ),
          details: _buildMaterialDetails(material),
          onEdit: () => _editMaterial(material),
          onDelete: () => _deleteMaterial(material),
        );
      },
    );
  }
}

class _DatabaseCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final String? footer;
  final Widget? leading;
  final Widget? details;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DatabaseCard({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
    this.trailing,
    this.footer,
    this.leading,
    this.details,
  });

  @override
  State<_DatabaseCard> createState() => _DatabaseCardState();
}

class _DatabaseCardState extends State<_DatabaseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.trailing != null) widget.trailing!,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: ColorsApp.btnColor,
                        onPressed: widget.onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: Colors.redAccent,
                        onPressed: widget.onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (widget.footer != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.footer!,
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
          if (widget.details != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Text(
                    _expanded ? "Hide details" : "View details",
                    style: const TextStyle(
                      color: Color(0xFF8B4513),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF8B4513),
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              widget.details!,
            ],
          ],
        ],
      ),
    );
  }
}

class _QuotationImage extends StatelessWidget {
  final String? url;

  const _QuotationImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 54,
        height: 54,
        color: Colors.grey.shade100,
        child: Image.network(
          url!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey.shade400,
        size: 28,
      ),
    );
  }
}

class _MaterialAvatar extends StatelessWidget {
  final String category;

  const _MaterialAvatar({required this.category});

  @override
  Widget build(BuildContext context) {
    final label = category.isEmpty ? "MAT" : category.toUpperCase();
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          label.length > 3 ? label.substring(0, 3) : label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

Widget _buildQuotationDetails(DatabaseQuotation quotation) {
  final items = quotation.items;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Items",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF302E2E),
        ),
      ),
      const SizedBox(height: 8),
      if (items.isEmpty)
        const Text(
          "No items",
          style: TextStyle(color: Colors.black54, fontSize: 12),
        )
      else
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildItemRow(
              title: item.description.isNotEmpty
                  ? item.description
                  : item.woodType.isNotEmpty
                      ? item.woodType
                      : item.foamType.isNotEmpty
                          ? item.foamType
                          : "Material",
              subtitle:
                  "${item.quantity} ${item.unit} • ${item.width}×${item.length}×${item.thickness}",
              trailing:
                  "₦${_formatAmount(item.sellingPrice)}",
            ),
          ),
        ),
      if (quotation.service != null &&
          quotation.service!.product.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text(
          "Service",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF302E2E),
          ),
        ),
        const SizedBox(height: 6),
        _buildItemRow(
          title: quotation.service!.product,
          subtitle: "Qty ${quotation.service!.quantity}",
          trailing: "₦${_formatAmount(quotation.service!.totalPrice)}",
        ),
      ],
      const SizedBox(height: 12),
      _buildDetailRow("Cost Price", _formatAmount(quotation.costPrice)),
      _buildDetailRow("Overhead Cost", _formatAmount(quotation.overheadCost)),
      _buildDetailRow(
        "Selling Price",
        _formatAmount(quotation.totalSellingPrice),
      ),
      _buildDetailRow(
        "Discount",
        "${quotation.discount.toStringAsFixed(1)}%",
        showCurrency: false,
      ),
      _buildDetailRow(
        "Discount Amount",
        _formatAmount(quotation.discountAmount),
      ),
      _buildDetailRow("Final Total", _formatAmount(quotation.finalTotal)),
    ],
  );
}

Widget _buildBomDetails(DatabaseBom bom) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Materials",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF302E2E),
        ),
      ),
      const SizedBox(height: 8),
      if (bom.materials.isEmpty)
        const Text(
          "No materials",
          style: TextStyle(color: Colors.black54, fontSize: 12),
        )
      else
        ...bom.materials.map(
          (material) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildItemRow(
              title: material.description.isNotEmpty
                  ? material.description
                  : material.name,
              subtitle:
                  "${material.quantity} ${material.unit} • ${material.width}×${material.length}×${material.thickness}",
              trailing: "₦${_formatAmount(material.subtotal > 0 ? material.subtotal : material.price)}",
            ),
          ),
        ),
      if (bom.additionalCosts.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text(
          "Additional Costs",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF302E2E),
          ),
        ),
        const SizedBox(height: 6),
        ...bom.additionalCosts.map(
          (cost) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildItemRow(
              title: cost.name,
              subtitle: cost.description,
              trailing: "₦${_formatAmount(cost.amount)}",
            ),
          ),
        ),
      ],
      const SizedBox(height: 12),
      _buildDetailRow("Materials Total", _formatAmount(bom.materialsCost)),
      _buildDetailRow(
        "Additional Costs",
        _formatAmount(bom.additionalCostsTotal),
      ),
      _buildDetailRow("Total Cost", _formatAmount(bom.totalCost)),
    ],
  );
}

Widget _buildProductDetails(DatabaseProduct product) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildDetailRow('Product ID', product.productId, showCurrency: false),
      _buildDetailRow(
        'Category',
        product.category.isEmpty ? '-' : product.category,
        showCurrency: false,
      ),
      _buildDetailRow(
        'Sub Category',
        product.subCategory.isEmpty ? '-' : product.subCategory,
        showCurrency: false,
      ),
      _buildDetailRow(
        'Status',
        product.status.isEmpty ? '-' : product.status,
        showCurrency: false,
      ),
      if (product.description.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text(
          'Description',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF302E2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.description,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    ],
  );
}

Widget _buildMaterialDetails(DatabaseMaterial material) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildDetailRow('Category', material.category, showCurrency: false),
      _buildDetailRow(
        'Price Per Sqm',
        _formatAmount(material.pricePerSqm),
      ),
      _buildDetailRow(
        'Pricing Unit',
        material.pricingUnit.isEmpty ? '-' : material.pricingUnit,
        showCurrency: false,
      ),
      _buildDetailRow(
        'Global',
        material.isGlobal ? 'Yes' : 'No',
        showCurrency: false,
      ),
      if (material.standardWidth != null ||
          material.standardLength != null ||
          (material.standardUnit != null && material.standardUnit!.isNotEmpty))
        ...[
          const SizedBox(height: 8),
          const Text(
            'Standard Size',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF302E2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${material.standardWidth ?? '-'} × ${material.standardLength ?? '-'} ${material.standardUnit ?? ''}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
    ],
  );
}

Widget _buildDetailRow(
  String label,
  String value, {
  bool showCurrency = true,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          showCurrency ? "₦$value" : value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}

Widget _buildItemRow({
  required String title,
  required String subtitle,
  required String trailing,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF302E2E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Text(
        trailing,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    ],
  );
}

Widget _buildSearchRow({
  required TextEditingController controller,
  required VoidCallback onSearch,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Search...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: ColorsApp.btnColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: onSearch,
          ),
        ),
      ],
    ),
  );
}

Widget _buildErrorView(String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Widget _buildEmptyView(String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        style: const TextStyle(color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Widget _buildSheetHandle() {
  return Center(
    child: Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );
}

Widget _buildStatusChip(String status) {
  final lower = status.toLowerCase();
  Color color;
  switch (lower) {
    case 'approved':
    case 'active':
      color = const Color(0xFF16A34A);
      break;
    case 'sent':
    case 'pending':
      color = const Color(0xFFF59E0B);
      break;
    case 'rejected':
    case 'cancelled':
    case 'blocked':
      color = const Color(0xFFEF4444);
      break;
    default:
      color = ColorsApp.btnColor;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget _buildPermissionSwitches(
  Map<String, bool> permissions, {
  required void Function(String key, bool value) onChanged,
}) {
  final entries = permissions.entries.toList();
  return Wrap(
    spacing: 12,
    runSpacing: 8,
    children: entries.map((entry) {
      return Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _capitalize(entry.key),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Switch(
              value: entry.value,
              activeColor: ColorsApp.btnColor,
              onChanged: (value) => onChanged(entry.key, value),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

Widget _buildDatePicker(
  BuildContext context, {
  required String label,
  required DateTime? date,
  required ValueChanged<DateTime?> onDateSelected,
}) {
  final text = date == null ? 'Select date' : DateFormat('dd MMM, yyyy').format(date);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF7B7B7B),
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? now,
            firstDate: DateTime(now.year - 1),
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) {
            onDateSelected(picked);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 241, 238, 238),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range, size: 18, color: Color(0xFF7B7B7B)),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Future<bool> _showDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

void _setIfChanged(
  Map<String, dynamic> updates,
  String key,
  String value,
  String original,
) {
  if (value.trim() != original.trim()) {
    updates[key] = value.trim();
  }
}

String _formatAmount(double amount) {
  return NumberFormat.decimalPattern().format(amount);
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
