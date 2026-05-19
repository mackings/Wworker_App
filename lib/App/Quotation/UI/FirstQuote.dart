import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Invoice/Api/client_service.dart';
import 'package:wworker/App/Invoice/Model/Client_model.dart';
import 'package:wworker/App/Quotation/UI/SecQuote.dart';
import 'package:wworker/App/Quotation/Widget/FQCard.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';

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
  static const Color _pageBg = Color(0xFFFAF7F3);
  static const Color _ink = Color(0xFF211D1A);
  static const Color _brand = Color(0xFF8B4513);
  static const Color _border = Color(0xFFE8DED6);

  final ClientService _clientService = ClientService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _busStopController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Client selection state
  List<ClientModel> _allClients = [];
  List<ClientModel> _filteredClients = [];
  ClientModel? _selectedClient;
  bool _isLoadingClients = true;
  bool _isNewClient = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _emailController.dispose();
    _phoneController.dispose();
    _busStopController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _buildAutoDescription() {
    final quotations =
        widget.selectedQuotations ?? const <Map<String, dynamic>>[];
    if (quotations.isEmpty) {
      return 'Quotation';
    }

    final productDescriptions = quotations
        .map((quotation) => quotation["product"])
        .whereType<Map>()
        .map((product) => product["description"]?.toString().trim() ?? '')
        .where((description) => description.isNotEmpty)
        .toSet()
        .toList();

    if (productDescriptions.isNotEmpty) {
      return productDescriptions.join(', ');
    }

    final productNames = quotations
        .map((quotation) => quotation["product"])
        .whereType<Map>()
        .map((product) => product["name"]?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    if (productNames.isNotEmpty) {
      return 'Quotation for ${productNames.join(', ')}';
    }

    return 'Quotation';
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
        _allClients.sort(
          (a, b) =>
              a.clientName.toLowerCase().compareTo(b.clientName.toLowerCase()),
        );
        _filteredClients = _allClients;
        _isLoadingClients = false;
      });
    } catch (e) {
      debugPrint("Error loading clients: $e");
      setState(() => _isLoadingClients = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredClients = query.isEmpty
          ? _allClients
          : _allClients
                .where(
                  (client) => client.clientName.toLowerCase().contains(query),
                )
                .toList();

      // Do not auto-fill the client name from search.
      // Search is only for picking an existing client.
      if (query.isNotEmpty) {
        _selectedClient = null;
        _isNewClient = false;
        _nameController.clear();
        _clearClientFields();
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
      _isNewClient = false;
      _searchController.clear();
    });
  }

  void _clearClientFields() {
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _busStopController.clear();
  }

  void _createNewClient({bool keepTypedName = false}) {
    setState(() {
      _selectedClient = null;
      _isNewClient = true;
      if (!keepTypedName) {
        _nameController.clear();
      }
      _searchController.clear();
      _clearClientFields();
    });
  }

  void _createNewClientFromSearch() {
    final typed = _searchController.text.trim();
    setState(() {
      _selectedClient = null;
      _isNewClient = true;
      if (typed.isNotEmpty) {
        _nameController.text = typed;
      }
      _searchController.clear();
      _clearClientFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: _pageBg,
        surfaceTintColor: _pageBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _ink,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          "Client Information",
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 14),

                  // Client Selection Section
                  _buildClientSelectionSection(),

                  const SizedBox(height: 14),

                  // Client Form
                  FirstQuoteCard(
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    addressController: _addressController,
                    busStopController: _busStopController,
                  ),

                  const SizedBox(height: 22),

                  _buildContinueButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Nav.push(
                          SecQuote(
                            name: _nameController.text,
                            address: _addressController.text,
                            nearestBusStop: _busStopController.text,
                            phone: _phoneController.text,
                            email: _emailController.text,
                            description: _buildAutoDescription(),
                            selectedQuotations: widget.selectedQuotations ?? [],
                            quotationQuantities:
                                widget.quotationQuantities ?? {},
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all required fields'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _brand,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Who is this for?",
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Select a saved client or enter new client details.",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline, color: _brand, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Select Client",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const Spacer(),
              if (_isLoadingClients)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _brand,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  "Tap a saved client to prefill details",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _createNewClient(),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text("New client"),
                style: TextButton.styleFrom(
                  foregroundColor: _brand,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Search/Select Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search clients...",
              prefixIcon: const Icon(Icons.search, color: _brand, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _brand, width: 1.4),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),

          // Search "no match" -> allow creating a new client explicitly.
          if (!_isLoadingClients &&
              _searchController.text.trim().isNotEmpty &&
              _filteredClients.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _brand.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add, size: 16, color: _brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "No client found for \"${_searchController.text.trim()}\"",
                      style: const TextStyle(
                        fontSize: 12,
                        color: _brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _createNewClientFromSearch,
                    style: TextButton.styleFrom(
                      foregroundColor: _brand,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("New client"),
                  ),
                ],
              ),
            ),

          // All clients list (filtered by search text)
          if (!_isLoadingClients &&
              _allClients.isNotEmpty &&
              (_searchController.text.trim().isEmpty ||
                  _filteredClients.isNotEmpty) &&
              !_isNewClient)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _searchController.text.trim().isEmpty
                    ? _allClients.length
                    : _filteredClients.length,
                itemBuilder: (context, index) {
                  final client = _searchController.text.trim().isEmpty
                      ? _allClients[index]
                      : _filteredClients[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFFFF3E0),
                      child: Text(
                        client.clientName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFA16438),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(
                      client.clientName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    subtitle: Text(
                      client.phoneNumber.isNotEmpty
                          ? client.phoneNumber
                          : "No phone number",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    onTap: () => _selectClient(client),
                  );
                },
              ),
            ),

          // New Client Indicator
          if (_isNewClient && _nameController.text.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _brand.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add, size: 16, color: _brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Creating new client: ${_nameController.text.trim()}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: _brand,
                        fontWeight: FontWeight.w700,
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _brand),
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
                        fontWeight: FontWeight.w700,
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
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        if (_selectedClient!.phoneNumber.isNotEmpty)
                          Text(
                            _selectedClient!.phoneNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
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
                        _searchController.clear();
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
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContinueButton({required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFB7835E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        child: const Text("Continue"),
      ),
    );
  }
}
