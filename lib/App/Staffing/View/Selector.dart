import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Staffing/Api/staffService.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/DashConfig.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';



class CompanySelectionScreen extends StatefulWidget {
  final List<dynamic> companies;
  final int currentIndex;
  final bool isFromSettings;

  const CompanySelectionScreen({
    super.key,
    required this.companies,
    required this.currentIndex,
    this.isFromSettings = false,
  });

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  final CompanyService _companyService = CompanyService();
  bool isLoading = false;
  int? selectedIndex;
  late List<dynamic> accessibleCompanies;

  @override
  void initState() {
    super.initState();
    // ✅ Filter companies to only show those with access granted
    accessibleCompanies = widget.companies
        .where((company) => company['accessGranted'] == true)
        .toList();
    
    selectedIndex = widget.currentIndex;
  }

  Future<void> _continueWithSelectedCompany() async {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a company'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // ✅ Check if selected company has access
    if (selectedIndex! >= 0 && selectedIndex! < accessibleCompanies.length) {
      final selectedCompany = accessibleCompanies[selectedIndex!];
      if (selectedCompany['accessGranted'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You no longer have access to this company'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    // ✅ If same company is selected, just navigate (no API call needed)
    if (selectedIndex == widget.currentIndex) {
      if (widget.isFromSettings) {
        Navigator.pop(context, false);
      } else {
        Nav.pushReplacement(const DashboardScreen());
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ Call API to switch company
      final result = await _companyService.switchCompany(
        companyIndex: selectedIndex!,
      );

      setState(() => isLoading = false);

      if (result['success'] == true) {
        // ✅ Update SharedPreferences with new active company data
        await _updateLocalCompanyData(selectedIndex!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Company switched successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          // Wait a bit for the snackbar to show
          await Future.delayed(const Duration(milliseconds: 500));

          if (widget.isFromSettings) {
            Navigator.pop(context, true); // Return true (switched)
          } else {
            Nav.pushReplacement(const DashboardScreen());
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message'] ?? 'Failed to switch company'}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ✅ Update SharedPreferences with selected company data
  Future<void> _updateLocalCompanyData(int companyIndex) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (companyIndex >= 0 && companyIndex < accessibleCompanies.length) {
      final selectedCompany = accessibleCompanies[companyIndex];
      
      // Update active company index
      await prefs.setInt('activeCompanyIndex', companyIndex);
      
      // Update active company data
      await prefs.setString('activeCompany', jsonEncode(selectedCompany));
      
      // Update individual company fields for easy access
      if (selectedCompany['name'] != null) {
        await prefs.setString('companyName', selectedCompany['name']);
      }
      
      if (selectedCompany['email'] != null) {
        await prefs.setString('companyEmail', selectedCompany['email']);
      }
      
      if (selectedCompany['phoneNumber'] != null) {
        await prefs.setString('companyPhoneNumber', selectedCompany['phoneNumber']);
      }
      
      if (selectedCompany['address'] != null) {
        await prefs.setString('companyAddress', selectedCompany['address']);
      }
      
      if (selectedCompany['role'] != null) {
        await prefs.setString('userRole', selectedCompany['role']);
      }
      
      if (selectedCompany['position'] != null) {
        await prefs.setString('userPosition', selectedCompany['position']);
      }
      
      debugPrint('✅ Local company data updated to: ${selectedCompany['name']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Show error if no accessible companies
    if (accessibleCompanies.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('No Access'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Accessible Companies',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You don\'t have access to any company. Please contact your administrator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.isFromSettings
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context, false),
              )
            : null,
        automaticallyImplyLeading: widget.isFromSettings,
        title: CustomText(
          title: widget.isFromSettings ? 'Switch Company' : 'Select Company',
          titleFontSize: 18,
          titleFontWeight: FontWeight.w600,
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        subtitle: widget.isFromSettings
                            ? 'Select which company you want to switch to. All your data will be filtered by the selected company.'
                            : 'You have access to multiple companies. Please select which company you want to work with.',
                        subtitleColor: Colors.grey.shade600,
                        subtitleFontSize: 14,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: accessibleCompanies.length,
                    itemBuilder: (context, index) {
                      final company = accessibleCompanies[index];
                      final isSelected = selectedIndex == index;
                      final isCurrent = index == widget.currentIndex;

                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedIndex = index);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF8B4513).withOpacity(0.1)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFF8B4513)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Company Icon
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF8B4513)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    company['name']?[0]?.toUpperCase() ?? 'C',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Company Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            company['name'] ?? 'Unknown Company',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? const Color(0xFF8B4513)
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Current',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${company['role']?.toUpperCase() ?? 'STAFF'} • ${company['position'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? const Color(0xFF8B4513)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    if (company['email'] != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        company['email'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Checkmark
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF8B4513),
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Continue Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _continueWithSelectedCompany,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.isFromSettings ? 'Switch Company' : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8B4513),
                ),
              ),
            ),
        ],
      ),
    );
  }
}