import 'package:flutter/material.dart';
import 'package:wworker/App/Invoice/Widget/DarkInvoice.dart';
import 'package:wworker/App/Invoice/Widget/elegantInvoice.dart';
import 'package:wworker/App/Invoice/Widget/invoice_template_prefs.dart';
import 'package:wworker/App/Invoice/Widget/minimalInvoice.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';

class InvoiceTemplateSettings extends StatefulWidget {
  const InvoiceTemplateSettings({super.key});

  @override
  State<InvoiceTemplateSettings> createState() =>
      _InvoiceTemplateSettingsState();
}

class _InvoiceTemplateSettingsState extends State<InvoiceTemplateSettings> {
  int _selected = 0;
  bool _isLoading = true;
  late final PageController _pageController;
  late final List<QuotationItem> _items;
  late final List<Widget> _templateWidgets;

  final List<Map<String, String>> _templateInfo = const [
    {
      'name': 'Modern Dark',
      'description': 'Bold dark theme with curved design',
    },
    {
      'name': 'Minimal Clean',
      'description': 'Simple and professional layout',
    },
    {
      'name': 'Elegant Botanical',
      'description': 'Soft colors with natural elements',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _items = [
      QuotationItem(
        id: 'sample-1',
        woodType: 'Walnut',
        foamType: null,
        width: 200,
        height: 0,
        length: 120,
        thickness: 18,
        unit: 'cm',
        squareMeter: 2.4,
        quantity: 2,
        costPrice: 12000,
        sellingPrice: 15000,
        description: 'Cabinet panel',
        image: '',
      ),
      QuotationItem(
        id: 'sample-2',
        woodType: 'Oak',
        foamType: null,
        width: 150,
        height: 0,
        length: 80,
        thickness: 12,
        unit: 'cm',
        squareMeter: 1.2,
        quantity: 1,
        costPrice: 7000,
        sellingPrice: 9000,
        description: 'Shelf insert',
        image: '',
      ),
    ];
    _templateWidgets = _buildTemplates();
    _loadSelection();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> _buildTemplates() {
    return [
      ModernInvoiceTemplate(
        clientName: "Sample Client",
        clientAddress: "12 Sample Street",
        clientBusStop: "Central Stop",
        clientPhone: "+234 000 000 0000",
        clientEmail: "client@example.com",
        invoiceNumber: "INV-0001",
        quotationNumber: "Q-0001",
        invoiceDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        paymentStatus: "unpaid",
        description: "Sample invoice preview",
        items: _items,
        grandTotal: 24000,
        amountPaid: 0,
        balance: 24000,
        isExistingInvoice: false,
        bankName: "First Bank",
        accountName: "Sample Furniture Ltd",
        accountNumber: "0123456789",
        bankCode: "011",
      ),
      MinimalInvoiceTemplate(
        clientName: "Sample Client",
        clientAddress: "12 Sample Street",
        clientBusStop: "Central Stop",
        clientPhone: "+234 000 000 0000",
        clientEmail: "client@example.com",
        invoiceNumber: "INV-0001",
        quotationNumber: "Q-0001",
        invoiceDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        paymentStatus: "unpaid",
        description: "Sample invoice preview",
        items: _items,
        grandTotal: 24000,
        amountPaid: 0,
        balance: 24000,
        isExistingInvoice: false,
        bankName: "First Bank",
        accountName: "Sample Furniture Ltd",
        accountNumber: "0123456789",
        bankCode: "011",
      ),
      ElegantInvoiceTemplate(
        clientName: "Sample Client",
        clientAddress: "12 Sample Street",
        clientBusStop: "Central Stop",
        clientPhone: "+234 000 000 0000",
        clientEmail: "client@example.com",
        invoiceNumber: "INV-0001",
        quotationNumber: "Q-0001",
        invoiceDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        paymentStatus: "unpaid",
        description: "Sample invoice preview",
        items: _items,
        grandTotal: 24000,
        amountPaid: 0,
        balance: 24000,
        isExistingInvoice: false,
        bankName: "First Bank",
        accountName: "Sample Furniture Ltd",
        accountNumber: "0123456789",
        bankCode: "011",
      ),
    ];
  }

  Future<void> _loadSelection() async {
    final index = await InvoiceTemplatePrefs.getTemplateIndex();
    setState(() {
      _selected = index.clamp(0, _templateInfo.length - 1);
      _isLoading = false;
    });
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_selected);
      }
    });
  }

  Future<void> _saveSelection() async {
    await InvoiceTemplatePrefs.setTemplateIndex(_selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Invoice template saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Invoice Template'),
        actions: const [
          GuideHelpIcon(
            title: "Invoice Template",
            message:
                "Choose the default invoice template used for new invoices. "
                "Once saved, invoices will use this design automatically so "
                "you don’t need to pick a template each time.",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  height: 80,
                  color: Colors.white,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _templateInfo.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selected == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selected = index);
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFA16438)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFA16438)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _templateInfo[index]['name']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _templateInfo[index]['description']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _selected = index);
                    },
                    itemCount: _templateInfo.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _templateWidgets[index],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saveSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA16438),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Template',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
