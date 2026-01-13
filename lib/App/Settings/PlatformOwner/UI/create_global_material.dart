import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/global_materials/create_global_board_material.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/global_materials/create_global_fabric_material.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/global_materials/create_global_foam_material.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/global_materials/create_global_hardware_material.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/global_materials/create_global_marble_material.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/global_materials/create_global_other_material.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/global_materials/create_global_wood_material.dart';
import 'package:wworker/Constant/colors.dart';

class CreateGlobalMaterial extends StatelessWidget {
  const CreateGlobalMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        elevation: 0,
        title: Text(
          'Select Material Category',
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Choose the material type to upload. Each category has its own structure and variants.',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          _CategoryCard(
            title: 'Wood',
            description: 'Solid wood materials for furniture frames',
            icon: Icons.forest,
            color: const Color(0xFF8B4513),
            examples: 'Iroko, Mahogany, Melina, Eku',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGlobalWoodMaterialPage(),
              ),
            ),
          ),
          _CategoryCard(
            title: 'Board',
            description: 'Engineered wood boards and panels',
            icon: Icons.view_module,
            color: const Color(0xFFD2691E),
            examples: 'MDF, HDF, Plywood, Particle Board',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGlobalBoardMaterialPage(),
              ),
            ),
          ),
          _CategoryCard(
            title: 'Foam',
            description: 'Cushioning foam with various densities',
            icon: Icons.airlines,
            color: const Color(0xFF4A90E2),
            examples: 'Lemon, Ordinary, Grey densities',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGlobalFoamMaterialPage(),
              ),
            ),
          ),
          _CategoryCard(
            title: 'Marble',
            description: 'Stone and marble surfaces',
            icon: Icons.landscape,
            color: const Color(0xFF7B68EE),
            examples: 'Full Sheet, Half Sheet variants',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGlobalMarbleMaterialPage(),
              ),
            ),
          ),
          _CategoryCard(
            title: 'Fabric',
            description: 'Upholstery fabrics and leather',
            icon: Icons.checkroom,
            color: const Color(0xFFE91E63),
            examples: 'Leather, Velvet, Ankara',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGlobalFabricMaterialPage(),
              ),
            ),
          ),
          _CategoryCard(
            title: 'Hardware',
            description: 'Handles, hinges, screws, and fittings',
            icon: Icons.construction,
            color: const Color(0xFF607D8B),
            examples: 'Handles, Nails, Edge Tape, Brackets',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGlobalHardwareMaterialPage(),
              ),
            ),
          ),
          _CategoryCard(
            title: 'Other',
            description: 'Paint, glue, and miscellaneous materials',
            icon: Icons.more_horiz,
            color: const Color(0xFF9E9E9E),
            examples: 'Paint, Glue, Varnish',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGlobalOtherMaterialPage(),
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
