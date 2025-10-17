import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/UI/SecQuote.dart';
import 'package:wworker/App/Quotation/Widget/FQCard.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';



class FirstQuote extends ConsumerStatefulWidget {
  const FirstQuote({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FirstQuoteState();
}

class _FirstQuoteState extends ConsumerState<FirstQuote> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _busStopController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); 
    final TextEditingController _descriptionController = TextEditingController(); 

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  FirstQuoteCard(
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    addressController: _addressController,
                    busStopController: _busStopController, 
                    descriptionController: _descriptionController
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
}
