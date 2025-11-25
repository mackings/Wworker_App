import 'package:flutter/material.dart';
import 'package:wworker/App/Invoice/Api/client_service.dart';
import 'package:wworker/App/Invoice/Model/Client_model.dart';
import 'package:wworker/App/Invoice/View/invoiceList.dart';
import 'package:wworker/App/Invoice/Widget/clientCard.dart';
import 'package:wworker/App/Order/View/QuoforOrder.dart';
import 'package:wworker/App/Order/View/allOrders.dart';
import 'package:wworker/App/Quotation/UI/AllclientQuotations.dart';
import 'package:wworker/App/Quotation/Widget/Optionmodal.dart';

class ClientsHome extends StatefulWidget {
  const ClientsHome({super.key});

  @override
  State<ClientsHome> createState() => _ClientsHomeState();
}

class _ClientsHomeState extends State<ClientsHome> {
  final ClientService _clientService = ClientService();
  late Future<List<ClientModel>> _clientsFuture;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredClientNames = [];
  List<String> _allClientNames = [];

  @override
  void initState() {
    super.initState();
    _clientsFuture = _clientService.getClients();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClientNames = _allClientNames;
      } else {
        _filteredClientNames = _allClientNames
            .where((name) => name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  List<String> _getUniqueClientNames(List<ClientModel> clients) {
    // Use a Set to automatically remove duplicates, then convert back to List
    final uniqueNames = clients
        .map((e) => e.clientName)
        .where((name) => name.isNotEmpty) // Filter out empty names
        .toSet()
        .toList();

    // Sort alphabetically for better UX
    uniqueNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return uniqueNames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Clients",
          style: TextStyle(
            color: Color(0xFF302E2E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<ClientModel>>(
          future: _clientsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFA16438)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final clients = snapshot.data ?? [];

            if (clients.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "No clients found",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Get unique client names and initialize filtered list
            _allClientNames = _getUniqueClientNames(clients);
            if (_filteredClientNames.isEmpty &&
                _searchController.text.isEmpty) {
              _filteredClientNames = _allClientNames;
            }

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search clients...",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFA16438),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFA16438),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                // Results Count
                if (_searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${_filteredClientNames.length} client${_filteredClientNames.length != 1 ? 's' : ''} found",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Client List
                Expanded(
                  child: _filteredClientNames.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No clients match your search",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ClientsCard(
                            clientNames: _filteredClientNames,
                            onGenerateInvoice: (clientName) {
                              debugPrint(
                                "🧾 Generating invoice for $clientName",
                              );

                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) => SelectOptionSheet(
                                  title: "Select Action",
                                  options: [
                                    OptionItem(
                                      label: "Generate Invoice from Quotation",
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AllClientQuotations(
                                                  isForInvoice: true,
                                                  clientName: clientName,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    OptionItem(
                                      label: "Generate from Invoice list",
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                InvoiceListPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
