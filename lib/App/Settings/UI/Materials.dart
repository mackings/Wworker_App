import 'package:flutter/material.dart' hide MaterialType;
import 'package:intl/intl.dart';
import 'package:wworker/App/Settings/MaterialUpload/Api/SmaterialService.dart' show MaterialService;
import 'package:wworker/App/Settings/Model/SMaterialModel.dart';
import 'package:wworker/App/Settings/UI/CreateMaterial.dart';



// class MaterialsPage extends StatefulWidget {
//   const MaterialsPage({super.key});

//   @override
//   State<MaterialsPage> createState() => _MaterialsPageState();
// }

// class _MaterialsPageState extends State<MaterialsPage> {
//   final MaterialService _materialService = MaterialService();
//   List<MaterialModel> materials = [];
//   bool isLoading = true;
//   String? errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _loadMaterials();
//   }

//   Future<void> _loadMaterials() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     try {
//       final result = await _materialService.getAllMaterials();

//       if (result['success'] == true) {
//         final List<dynamic> materialsJson = result['data'] ?? [];
//         setState(() {
//           materials = materialsJson
//               .map((e) => MaterialModel.fromJson(e))
//               .toList();
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//           errorMessage = result['message'] ?? 'Failed to load materials';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = 'Error: $e';
//       });
//     }
//   }

//   void _navigateToCreateMaterial() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const CreateMaterialPage(),
//       ),
//     ).then((_) => _loadMaterials());
//   }

//   void _navigateToMaterialDetails(MaterialModel material) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => MaterialDetailsPage(material: material),
//       ),
//     ).then((_) => _loadMaterials());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           "Materials",
//           style: TextStyle(
//             color: Color(0xFF302E2E),
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: _buildBody(),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _navigateToCreateMaterial,
//         backgroundColor: const Color(0xFFA16438),
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }

//   Widget _buildBody() {
//     if (isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(color: Color(0xFFA16438)),
//       );
//     }

//     if (errorMessage != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 60, color: Colors.red),
//             const SizedBox(height: 16),
//             Text(
//               'Failed to load materials',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[700],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 errorMessage!,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _loadMaterials,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Retry'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFA16438),
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     if (materials.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             const Text(
//               'No materials found',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 8),
//             TextButton.icon(
//               onPressed: _navigateToCreateMaterial,
//               icon: const Icon(Icons.add),
//               label: const Text('Add Material'),
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadMaterials,
//       color: const Color(0xFFA16438),
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: materials.length,
//         itemBuilder: (context, index) {
//           final material = materials[index];
//           return MaterialCard(
//             material: material,
//             onTap: () => _navigateToMaterialDetails(material),
//           );
//         },
//       ),
//     );
//   }
// }

// // ========== MATERIAL CARD WIDGET ==========
// class MaterialCard extends StatelessWidget {
//   final MaterialModel material;
//   final VoidCallback onTap;

//   const MaterialCard({
//     super.key,
//     required this.material,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Text(
//                     material.name,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF302E2E),
//                     ),
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFA16438).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     material.unit,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFFA16438),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             _buildInfoRow(
//               'Standard Size',
//               '${material.standardWidth} x ${material.standardLength} ${material.standardUnit}',
//             ),
//             const SizedBox(height: 8),
//             _buildInfoRow(
//               'Price per ${material.unit}',
//               '₦${_formatNumber(material.pricePerSqm)}',
//             ),
//             const SizedBox(height: 8),
//             _buildInfoRow('Available Types', '${material.types.length}'),
//             const SizedBox(height: 8),
//             _buildInfoRow('Available Sizes', '${material.sizes.length}'),
//             if (material.foamDensities.isNotEmpty) ...[
//               const SizedBox(height: 8),
//               _buildInfoRow('Foam Densities', '${material.foamDensities.length}'),
//             ],
//             if (material.foamThicknesses.isNotEmpty) ...[
//               const SizedBox(height: 8),
//               _buildInfoRow(
//                 'Foam Thicknesses',
//                 '${material.foamThicknesses.length}',
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             color: Colors.grey,
//           ),
//         ),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Color(0xFF302E2E),
//           ),
//         ),
//       ],
//     );
//   }

//   String _formatNumber(double number) {
//     final formatter = NumberFormat('#,###.##');
//     return formatter.format(number);
//   }
// }

// // ========== MATERIAL DETAILS PAGE ==========
// class MaterialDetailsPage extends StatefulWidget {
//   final MaterialModel material;

//   const MaterialDetailsPage({
//     super.key,
//     required this.material,
//   });

//   @override
//   State<MaterialDetailsPage> createState() => _MaterialDetailsPageState();
// }

// class _MaterialDetailsPageState extends State<MaterialDetailsPage> {
//   final MaterialService _materialService = MaterialService();
//   final TextEditingController _typeNameController = TextEditingController();
//   final TextEditingController _typePriceController = TextEditingController();
//   bool isAddingType = false;

//   Future<void> _addTypes() async {
//     if (_typeNameController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter a type name')),
//       );
//       return;
//     }

//     setState(() => isAddingType = true);

//     final types = <dynamic>[
//       if (_typePriceController.text.isNotEmpty)
//         MaterialType(
//           name: _typeNameController.text.trim(),
//           pricePerSqm: double.tryParse(_typePriceController.text),
//         )
//       else
//         _typeNameController.text.trim(),
//     ];

//     final request = AddMaterialTypesRequest(types: types);
//     final result = await _materialService.addMaterialTypes(
//       widget.material.id,
//       request,
//     );

//     setState(() => isAddingType = false);

//     if (result['success'] == true) {
//       _typeNameController.clear();
//       _typePriceController.clear();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Type added successfully')),
//       );
//       Navigator.pop(context); // Refresh parent
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(result['message'] ?? 'Failed to add type')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: Text(
//           widget.material.name,
//           style: const TextStyle(
//             color: Color(0xFF302E2E),
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildInfoCard(),
//             const SizedBox(height: 16),
//             _buildTypesSection(),
//             const SizedBox(height: 16),
//             _buildSizesSection(),
//             if (widget.material.foamDensities.isNotEmpty) ...[
//               const SizedBox(height: 16),
//               _buildFoamDensitiesSection(),
//             ],
//             if (widget.material.foamThicknesses.isNotEmpty) ...[
//               const SizedBox(height: 16),
//               _buildFoamThicknessesSection(),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Material Information',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF302E2E),
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildDetailRow('Unit', widget.material.unit),
//           const Divider(height: 24),
//           _buildDetailRow(
//             'Standard Size',
//             '${widget.material.standardWidth} x ${widget.material.standardLength} ${widget.material.standardUnit}',
//           ),
//           const Divider(height: 24),
//           _buildDetailRow(
//             'Price per ${widget.material.unit}',
//             '₦${_formatNumber(widget.material.pricePerSqm)}',
//           ),
//           const Divider(height: 24),
//           _buildDetailRow(
//             'Waste Threshold',
//             '${(widget.material.wasteThreshold * 100).toStringAsFixed(0)}%',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTypesSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Material Types',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF302E2E),
//                 ),
//               ),
//               TextButton.icon(
//                 onPressed: () => _showAddTypeDialog(),
//                 icon: const Icon(Icons.add, size: 18),
//                 label: const Text('Add Type'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           if (widget.material.types.isEmpty)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(20),
//                 child: Text(
//                   'No types added yet',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ),
//             )
//           else
//             ...widget.material.types.map((type) => Padding(
//                   padding: const EdgeInsets.only(bottom: 8),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         type.name,
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                       if (type.pricePerSqm != null)
//                         Text(
//                           '₦${_formatNumber(type.pricePerSqm!)}',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFFA16438),
//                           ),
//                         ),
//                     ],
//                   ),
//                 )),
//         ],
//       ),
//     );
//   }

//   Widget _buildSizesSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Available Sizes',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF302E2E),
//             ),
//           ),
//           const SizedBox(height: 12),
//           if (widget.material.sizes.isEmpty)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(20),
//                 child: Text(
//                   'No sizes available',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ),
//             )
//           else
//             ...widget.material.sizes.map((size) => Padding(
//                   padding: const EdgeInsets.only(bottom: 8),
//                   child: Text(
//                     '${size.width} x ${size.length} ${widget.material.standardUnit}',
//                     style: const TextStyle(fontSize: 14),
//                   ),
//                 )),
//         ],
//       ),
//     );
//   }

//   Widget _buildFoamDensitiesSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Foam Densities',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF302E2E),
//             ),
//           ),
//           const SizedBox(height: 12),
//           ...widget.material.foamDensities.map((density) => Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Text(
//                   '${density.density} ${density.unit}',
//                   style: const TextStyle(fontSize: 14),
//                 ),
//               )),
//         ],
//       ),
//     );
//   }

//   Widget _buildFoamThicknessesSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Foam Thicknesses',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF302E2E),
//             ),
//           ),
//           const SizedBox(height: 12),
//           ...widget.material.foamThicknesses.map((thickness) => Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Text(
//                   '${thickness.thickness} ${thickness.unit}',
//                   style: const TextStyle(fontSize: 14),
//                 ),
//               )),
//         ],
//       ),
//     );
//   }

//   void _showAddTypeDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Add Material Type'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: _typeNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Type Name *',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _typePriceController,
//               decoration: const InputDecoration(
//                 labelText: 'Price per sqm (Optional)',
//                 border: OutlineInputBorder(),
//                 prefixText: '₦',
//               ),
//               keyboardType: TextInputType.number,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               _typeNameController.clear();
//               _typePriceController.clear();
//               Navigator.pop(context);
//             },
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: isAddingType
//                 ? null
//                 : () {
//                     Navigator.pop(context);
//                     _addTypes();
//                   },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFFA16438),
//               foregroundColor: Colors.white,
//             ),
//             child: isAddingType
//                 ? const SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   )
//                 : const Text('Add'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 14, color: Colors.grey),
//         ),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Color(0xFF302E2E),
//           ),
//         ),
//       ],
//     );
//   }

//   String _formatNumber(double number) {
//     final formatter = NumberFormat('#,###.##');
//     return formatter.format(number);
//   }

//   @override
//   void dispose() {
//     _typeNameController.dispose();
//     _typePriceController.dispose();
//     super.dispose();
//   }
// }