import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Widget/FQCard.dart';
import 'package:wworker/App/Quotation/Widget/QuoTable.dart';

class FirstQuote extends ConsumerStatefulWidget {
  const FirstQuote({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FirstQuoteState();
}

class _FirstQuoteState extends ConsumerState<FirstQuote> {

  final TextEditingController  _emailController  = TextEditingController();
   final TextEditingController  _phoneController  = TextEditingController();
   final TextEditingController  _busStopController  = TextEditingController();
   final TextEditingController  _addressController  = TextEditingController();
   final TextEditingController  _descriptionController  = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(child: 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 5),
          child: Column(
            children: [
          
            FirstQuoteCard(
            emailController: _emailController,
            phoneController: _phoneController,
            addressController: _addressController,
            busStopController: _busStopController,
            descriptionController: _descriptionController,
            onContinue: () {
      
              print("Continue pressed");
            },
          ),

          QuotationTable(
  items: [
    QuotationItem(
      product: "Table",
      description: "Dining set (6 seater)",
      quantity: 2,
      unitPrice: "#35,000",
      total: "#70,000",
    ),
    QuotationItem(
      product: "Chair",
      description: "Single Chair",
      quantity: 4,
      unitPrice: "#10,000",
      total: "#40,000",
    ),
  ],
)

          
          
          
          ]),
        )),
      ),
    );
  }
}
