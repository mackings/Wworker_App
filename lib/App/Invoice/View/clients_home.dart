import 'package:flutter/material.dart';
import 'package:wworker/App/Invoice/Api/client_service.dart';
import 'package:wworker/App/Invoice/Model/Client_model.dart';
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

  @override
  void initState() {
    super.initState();
    _clientsFuture = _clientService.getClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Clients")),
      body: SafeArea(
        child: FutureBuilder<List<ClientModel>>(
          future: _clientsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final clients = snapshot.data ?? [];

            if (clients.isEmpty) {
              return const Center(child: Text("No clients found"));
            }

            final clientNames = clients.map((e) => e.clientName).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ClientsCard(
                clientNames: clientNames,
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
          label: "Generate Invoice from Order",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllOrdersPage(),
              ),
            );
          },
        ),
        OptionItem(
          label: "Create New Order",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SelectQuotationForOrder(
                  clientName: clientName,
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}