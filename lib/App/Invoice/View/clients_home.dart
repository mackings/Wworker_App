import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Invoice/Api/client_service.dart';
import 'package:wworker/App/Invoice/Model/Client_model.dart';
import 'package:wworker/App/Invoice/View/invoiceList.dart';
import 'package:wworker/App/Invoice/Widget/clientCard.dart';
import 'package:wworker/App/Quotation/UI/AllclientQuotations.dart';
import 'package:wworker/App/Quotation/Widget/Optionmodal.dart';

const Color _invoiceBg = Color(0xFFFAF7F3);
const Color _invoiceInk = Color(0xFF211D1A);
const Color _invoiceMuted = Color(0xFF756A61);
const Color _invoiceBrand = Color(0xFF8B4513);
const Color _invoiceBorder = Color(0xFFE8DED6);

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
      backgroundColor: _invoiceBg,
      appBar: AppBar(
        backgroundColor: _invoiceBg,
        surfaceTintColor: _invoiceBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Clients",
          style: GoogleFonts.openSans(
            color: _invoiceInk,
            fontSize: 18,
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
                child: CircularProgressIndicator(color: _invoiceBrand),
              );
            }

            if (snapshot.hasError) {
              return _StateMessage(
                icon: Icons.error_outline,
                title: 'Could not load clients',
                message: snapshot.error.toString(),
                iconColor: Colors.redAccent,
              );
            }

            final clients = snapshot.data ?? [];

            if (clients.isEmpty) {
              return const _StateMessage(
                icon: Icons.people_outline,
                title: 'No clients found',
                message:
                    'Create a quotation first to see invoice clients here.',
              );
            }

            // Get unique client names and initialize filtered list
            _allClientNames = _getUniqueClientNames(clients);
            if (_filteredClientNames.isEmpty &&
                _searchController.text.isEmpty) {
              _filteredClientNames = _allClientNames;
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              children: [
                _buildHeader(_allClientNames.length),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _invoiceBorder),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.openSans(
                      color: _invoiceInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search clients",
                      hintStyle: GoogleFonts.openSans(
                        color: _invoiceMuted.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _invoiceBrand,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
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
                    padding: const EdgeInsets.only(top: 10, left: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${_filteredClientNames.length} client${_filteredClientNames.length != 1 ? 's' : ''} found",
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: _invoiceMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // Client List
                if (_filteredClientNames.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: _StateMessage(
                      icon: Icons.search_off,
                      title: 'No matching clients',
                      message: 'Try another client name.',
                    ),
                  )
                else
                  ClientsCard(
                    clientNames: _filteredClientNames,
                    onGenerateInvoice: (clientName) {
                      debugPrint("🧾 Generating invoice for $clientName");

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
                                    builder: (context) => AllClientQuotations(
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
                                    builder: (context) => InvoiceListPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _invoiceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _invoiceBrand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: _invoiceBrand,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate invoice',
                  style: GoogleFonts.openSans(
                    color: _invoiceInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$count client${count == 1 ? '' : 's'} with quotation records',
                  style: GoogleFonts.openSans(
                    color: _invoiceMuted,
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
  final Color iconColor;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor = _invoiceBrand,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                color: _invoiceInk,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                color: _invoiceMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
