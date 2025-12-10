import 'package:flutter/material.dart';
import 'package:wworker/App/Settings/MaterialUpload/Widgets/CreateBoard.dart';
import 'package:wworker/App/Settings/MaterialUpload/Widgets/CreateFabric.dart';
import 'package:wworker/App/Settings/MaterialUpload/Widgets/CreateFoam.dart';
import 'package:wworker/App/Settings/MaterialUpload/Widgets/CreateMarble.dart';
import 'package:wworker/App/Settings/MaterialUpload/Widgets/CreateWood.dart';

class SelectMaterialCategoryPage extends StatelessWidget {
  const SelectMaterialCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Select Material Category",
          style: TextStyle(
            color: Color(0xFF302E2E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'What type of material would you like to add?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Wood Category
          _CategoryCard(
            title: 'Wood',
            description: 'Solid wood materials for furniture frames',
            icon: Icons.forest,
            color: const Color(0xFF8B4513),
            examples: 'Iroko, Mahogany, Melina, Eku',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateWoodMaterialPage(),
              ),
            ),
          ),
          
          // Board Category
          _CategoryCard(
            title: 'Board',
            description: 'Engineered wood boards and panels',
            icon: Icons.view_module,
            color: const Color(0xFFD2691E),
            examples: 'MDF, HDF, Plywood, Particle Board',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateBoardMaterialPage(),
              ),
            ),
          ),
          
          // Foam Category
          _CategoryCard(
            title: 'Foam',
            description: 'Cushioning foam with various densities',
            icon: Icons.airlines,
            color: const Color(0xFF4A90E2),
            examples: 'Lemon, Ordinary, Grey densities',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateFoamMaterialPage(),
              ),
            ),
          ),
          
          // Marble Category
          _CategoryCard(
            title: 'Marble',
            description: 'Stone and marble surfaces',
            icon: Icons.landscape,
            color: const Color(0xFF7B68EE),
            examples: 'Full Sheet, Half Sheet variants',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateMarbleMaterialPage(),
              ),
            ),
          ),
          
          // Fabric Category
          _CategoryCard(
            title: 'Fabric',
            description: 'Upholstery fabrics and leather',
            icon: Icons.checkroom,
            color: const Color(0xFFE91E63),
            examples: 'Leather, Velvet, Ankara',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateFabricMaterialPage(),
              ),
            ),
          ),
          
          // Hardware Category
          _CategoryCard(
            title: 'Hardware',
            description: 'Handles, hinges, screws, and fittings',
            icon: Icons.construction,
            color: const Color(0xFF607D8B),
            examples: 'Handles, Nails, Edge Tape, Brackets',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateHardwareMaterialPage(),
              ),
            ),
          ),
          
          // Other Category
          _CategoryCard(
            title: 'Other',
            description: 'Paint, glue, and miscellaneous materials',
            icon: Icons.more_horiz,
            color: const Color(0xFF9E9E9E),
            examples: 'Paint, Glue, Varnish',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateOtherMaterialPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String examples;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.examples,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF302E2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Examples: $examples',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}