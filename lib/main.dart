import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/View/Onboarding.dart';
import 'package:wworker/App/Auth/Widgets/customRecovery.dart';
import 'package:wworker/Constant/colors.dart';


void main() {
  runApp( ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const FirstOnboard()
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {

      String selectedOption = "";

    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

        CustomRecoveryOption(
          title: "Reset via Email",
          subtitle: "Code will be sent to your email address",
          leadingIcon:
              const Icon(Icons.email_outlined, color: Color(0xFF302E2E)),
          isSelected: selectedOption == "email",
          onTap: () => setState(() => selectedOption = "email"),
        ),
        const SizedBox(height: 12),
        CustomRecoveryOption(
          title: "Reset via Phone",
          subtitle: "Code will be sent to your phone number",
          leadingIcon:
              const Icon(Icons.phone_outlined, color: Color(0xFF302E2E)),
          isSelected: selectedOption == "phone",
          onTap: () => setState(() => selectedOption = "phone"),
        ),


    
 
          ],
        ),
      ),

    );
  }
}
