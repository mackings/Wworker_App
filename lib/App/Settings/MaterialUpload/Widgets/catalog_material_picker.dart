import 'package:flutter/material.dart';
import 'package:wworker/App/Settings/MaterialUpload/Api/SmaterialService.dart';

String cleanCatalogLabel(String raw) {
  return raw.replaceAll('"', '').replaceAll(r'\"', '').trim();
}

double? parseThicknessFromSizeString(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return null;

  // Extract a simple fraction like 1/2 or 3/4 (optionally with quotes/mm/cm).
  final frac = RegExp(r'(\\d+)\\s*/\\s*(\\d+)').firstMatch(s);
  if (frac != null) {
    final num = double.tryParse(frac.group(1) ?? '');
    final den = double.tryParse(frac.group(2) ?? '');
    if (num != null && den != null && den != 0) return num / den;
  }

  // Extract the first decimal/integer number.
  final numMatch = RegExp(r'(\\d+(?:\\.\\d+)?)').firstMatch(s);
  if (numMatch != null) {
    return double.tryParse(numMatch.group(1) ?? '');
  }

  return null;
}

String inferThicknessUnitFromSizeString(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.contains('mm')) return 'mm';
  if (s.contains('cm')) return 'cm';
  if (s.contains('ft') || s.contains('feet')) return 'ft';
  if (s.contains('inches') || s.contains('inch') || s.contains('"')) {
    return 'inches';
  }
  // Default per API doc.
  return 'inches';
}

String catalogMaterialDisplayName(Map<String, dynamic> row) {
  final material = (row['material'] ?? '').toString().trim();
  if (material.isNotEmpty) return material;
  return (row['name'] ?? '').toString().trim();
}

Map<String, dynamic> buildCatalogMaterialCreateFields(
  Map<String, dynamic> row,
) {
  final fields = <String, dynamic>{};

  void putIfNotEmpty(String key, dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty) {
      fields[key] = text;
    }
  }

  final materialName = catalogMaterialDisplayName(row);
  putIfNotEmpty('catalogMaterial', materialName);
  putIfNotEmpty('name', materialName);
  putIfNotEmpty(
    'category',
    cleanCatalogLabel((row['category'] ?? '').toString()),
  );
  putIfNotEmpty(
    'subCategory',
    cleanCatalogLabel((row['subCategory'] ?? '').toString()),
  );
  putIfNotEmpty('size', row['size']);
  putIfNotEmpty('unit', row['unit']);
  putIfNotEmpty('color', row['color']);
  // New supported catalog fields (optional)
  if (row['thickness'] != null) {
    fields['thickness'] = row['thickness'];
  }
  putIfNotEmpty('thicknessUnit', row['thicknessUnit']);
  fields['useCatalog'] = true;

  return fields;
}

Future<Map<String, dynamic>?> pickSupportedCatalogMaterial({
  required BuildContext context,
  required MaterialService materialService,
  String? preferredCategory,
  String title = 'Select Supported Material',
}) async {
  Future<List<Map<String, dynamic>>> fetch({String? category}) async {
    final res = await materialService.getSupportedMaterials(
      category: category,
      limit: 500,
      page: 1,
    );
    if (res['success'] != true || res['data'] is! List) {
      return [];
    }
    return (res['data'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  var items = await fetch(category: preferredCategory);
  if (items.isEmpty && preferredCategory != null) {
    items = await fetch();
  }

  if (items.isEmpty) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No supported catalog materials found')),
    );
    return null;
  }

  if (!context.mounted) return null;

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      var query = '';
      var filtered = List<Map<String, dynamic>>.from(items);

      List<Map<String, dynamic>> applyFilter(String q) {
        final needle = q.toLowerCase().trim();
        if (needle.isEmpty) return List<Map<String, dynamic>>.from(items);
        return items.where((row) {
          final values = [
            catalogMaterialDisplayName(row),
            (row['category'] ?? '').toString(),
            (row['subCategory'] ?? '').toString(),
            (row['size'] ?? '').toString(),
            (row['unit'] ?? '').toString(),
            (row['color'] ?? '').toString(),
            (row['thickness'] ?? '').toString(),
            (row['thicknessUnit'] ?? '').toString(),
          ];
          return values.any((v) => v.toLowerCase().contains(needle));
        }).toList();
      }

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search material, category, size, color...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setSheetState(() {
                        query = value;
                        filtered = applyFilter(query);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('No materials match your search'),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final row = filtered[index];
                              final category = (row['category'] ?? '')
                                  .toString()
                                  .trim();
                              final subCategory = (row['subCategory'] ?? '')
                                  .toString()
                                  .trim();
                              final size = (row['size'] ?? '')
                                  .toString()
                                  .trim();
                              final unit = (row['unit'] ?? '')
                                  .toString()
                                  .trim();
                              final color = (row['color'] ?? '')
                                  .toString()
                                  .trim();
                              final thickness = (row['thickness'] ?? '')
                                  .toString()
                                  .trim();
                              final thicknessUnit = (row['thicknessUnit'] ?? '')
                                  .toString()
                                  .trim();

                              final metaParts = [
                                if (category.isNotEmpty) category,
                                if (subCategory.isNotEmpty) subCategory,
                                if (size.isNotEmpty) size,
                                if (unit.isNotEmpty) unit,
                                if (color.isNotEmpty) color,
                                if (thickness.isNotEmpty && thickness != 'null')
                                  'thk: $thickness ${thicknessUnit.isEmpty ? '' : thicknessUnit}',
                              ];

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                title: Text(
                                  catalogMaterialDisplayName(row),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  metaParts.join(' • '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.pop(ctx, row),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
