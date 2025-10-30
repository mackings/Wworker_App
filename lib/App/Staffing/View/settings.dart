import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Staffing/Widgets/database.dart';
import 'package:wworker/App/Staffing/Widgets/notification.dart';
import 'package:wworker/App/Staffing/Widgets/staffaccess.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: CustomText(title: "Settings",),
      ),
      body: SafeArea(child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 15),
          child: Column(
            children: [
          
              DatabaseWidget(),

              SizedBox(height: 30,),

              NotificationsWidget(),

               SizedBox(height: 30,),

              StaffAccessWidget(),
              
                SizedBox(height: 30,),
          
          
            ],
          ),
        ),
      )),
    );
  }
}
