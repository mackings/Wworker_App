import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Invoice/Api/client_service.dart';
import 'package:wworker/App/Invoice/Model/Client_model.dart';
import 'package:wworker/App/Quotation/UI/SecQuote.dart';
import 'package:wworker/App/Quotation/Widget/FQCard.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';



class FirstQuote extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>>? selectedQuotations;
  final Map<String, int>? quotationQuantities;

  const FirstQuote({
    super.key,
    this.selectedQuotations,
    this.quotationQuantities,
  });

  @override
  ConsumerState<FirstQuote> createState() => _FirstQuoteState();
}

class _FirstQuoteState extends ConsumerState<FirstQuote> {
  final ClientService _clientService = ClientService();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _busStopController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Client selection state
  List<ClientModel> _allClients = [];
  List<ClientModel> _filteredClients = [];
  ClientModel? _selectedClient;
  bool _isLoadingClients = true;
  bool _showClientDropdown = false;
  bool _isNewClient = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _emailController.dispose();
    _phoneController.dispose();
    _busStopController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoadingClients = true);
    
    try {
      final clients = await _clientService.getClients();
      
      // Remove duplicates based on client name
      final uniqueClients = <String, ClientModel>{};
      for (var client in clients) {
        if (client.clientName.isNotEmpty) {
          uniqueClients[client.clientName.toLowerCase()] = client;
        }
      }
      
      setState(() {
        _allClients = uniqueClients.values.toList();
        _allClients.sort((a, b) => 
          a.clientName.toLowerCase().compareTo(b.clientName.toLowerCase())
        );
        _filteredClients = _allClients;
        _isLoadingClients = false;
      });
    } catch (e) {
      debugPrint("Error loading clients: $e");
      setState(() => _isLoadingClients = false);
    }
  }

  void _onNameChanged() {
    final query = _nameController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredClients = _allClients;
        _showClientDropdown = false;
        _selectedClient = null;
        _isNewClient = false;
        _clearClientFields();
      } else {
        _filteredClients = _allClients
            .where((client) => 
              client.clientName.toLowerCase().contains(query))
            .toList();
        _showClientDropdown = _filteredClients.isNotEmpty;
        
        // Check if exact match exists
        final exactMatch = _filteredClients.firstWhere(
          (client) => client.clientName.toLowerCase() == query,
          orElse: () => ClientModel(
            clientName: '',
            phoneNumber: '',
            email: '',
            clientAddress: '',
            nearestBusStop: '',
          ),
        );
        
        if (exactMatch.clientName.isEmpty) {
          _isNewClient = true;
          _selectedClient = null;
        }
      }
    });
  }

  void _selectClient(ClientModel client) {
    setState(() {
      _selectedClient = client;
      _nameController.text = client.clientName;
      _emailController.text = client.email;
      _phoneController.text = client.phoneNumber;
      _addressController.text = client.clientAddress;
      _busStopController.text = client.nearestBusStop;
      _showClientDropdown = false;
      _isNewClient = false;
    });
  }

  void _clearClientFields() {
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _busStopController.clear();
  }

  void _createNewClient() {
    setState(() {
      _selectedClient = null;
      _isNewClient = true;
      _showClientDropdown = false;
      _clearClientFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Client Information",
          style: TextStyle(
            color: Color(0xFF302E2E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Client Selection Section
                  _buildClientSelectionSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Client Form
                  FirstQuoteCard(
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    addressController: _addressController,
                    busStopController: _busStopController,
                    descriptionController: _descriptionController,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  CustomButton(
                    text: "Continue",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Nav.push(
                          SecQuote(
                            name: _nameController.text,
                            address: _addressController.text,
                            nearestBusStop: _busStopController.text,
                            phone: _phoneController.text,
                            email: _emailController.text,
                            description: _descriptionController.text,
                            selectedQuotations: widget.selectedQuotations ?? [],
                            quotationQuantities:
                                widget.quotationQuantities ?? {},
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                color: Color(0xFFA16438),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Select Client",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF302E2E),
                ),
              ),
              const Spacer(),
              if (_isLoadingClients)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFA16438),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Search/Select Field
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Search or enter new client name...",
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFFA16438),
                size: 20,
              ),
              suffixIcon: _nameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _nameController.clear();
                        _clearClientFields();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFA16438),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          
          // Client Dropdown Results
          if (_showClientDropdown && _filteredClients.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _filteredClients.length,
                itemBuilder: (context, index) {
                  final client = _filteredClients[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFFFF3E0),
                      child: Text(
                        client.clientName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFA16438),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(
                      client.clientName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF302E2E),
                      ),
                    ),
                    subtitle: Text(
                      client.phoneNumber.isNotEmpty
                          ? client.phoneNumber
                          : "No phone number",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () => _selectClient(client),
                  );
                },
              ),
            ),
          
          // New Client Indicator
          if (_isNewClient && _nameController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    Icons.person_add,
                    size: 16,
                    color: Color(0xFFA16438),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Creating new client: ${_nameController.text}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA16438),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Selected Client Info
          if (_selectedClient != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA16438)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFFFF3E0),
                    child: Text(
                      _selectedClient!.clientName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFA16438),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "Client Selected",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedClient!.clientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF302E2E),
                          ),
                        ),
                        if (_selectedClient!.phoneNumber.isNotEmpty)
                          Text(
                            _selectedClient!.phoneNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.grey,
                    onPressed: () {
                      setState(() {
                        _selectedClient = null;
                        _nameController.clear();
                        _clearClientFields();
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // Quick Stats
          if (!_isLoadingClients && _allClients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                "${_allClients.length} client${_allClients.length != 1 ? 's' : ''} available",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }
}