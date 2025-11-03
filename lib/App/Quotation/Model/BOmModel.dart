import 'package:wworker/App/Quotation/Model/ITemCostModel.dart';

class BOMModel {


  final String id;
  final String userId;
  final String name;
  final String description;
  final List<MaterialItem> materials;
  final List<AdditionalCost> additionalCosts;
  final num materialsCost;
  final num additionalCostsTotal;
  final num totalCost;
  final String createdAt;
  final String updatedAt;
  final String bomNumber;

  BOMModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.materials,
    required this.additionalCosts,
    required this.materialsCost,
    required this.additionalCostsTotal,
    required this.totalCost,
    required this.createdAt,
    required this.updatedAt,
    required this.bomNumber,
  });

  factory BOMModel.fromJson(Map<String, dynamic> json) {
    return BOMModel(
      id: json["_id"] ?? "",
      userId: json["userId"] ?? "",
      name: json["name"] ?? "",
      description: json["description"] ?? "",
      materials: (json["materials"] as List<dynamic>?)
              ?.map((e) => MaterialItem.fromJson(e))
              .toList() ??
          [],
      additionalCosts: (json["additionalCosts"] as List<dynamic>?)
              ?.map((e) => AdditionalCost.fromJson(e))
              .toList() ??
          [],
      materialsCost: json["materialsCost"] ?? 0,
      additionalCostsTotal: json["additionalCostsTotal"] ?? 0,
      totalCost: json["totalCost"] ?? 0,
      createdAt: json["createdAt"] ?? "",
      updatedAt: json["updatedAt"] ?? "",
      bomNumber: json["bomNumber"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "userId": userId,
      "name": name,
      "description": description,
      "materials": materials.map((e) => e.toJson()).toList(),
      "additionalCosts": additionalCosts.map((e) => e.toJson()).toList(),
      "materialsCost": materialsCost,
      "additionalCostsTotal": additionalCostsTotal,
      "totalCost": totalCost,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "bomNumber": bomNumber,
    };
  }
}
