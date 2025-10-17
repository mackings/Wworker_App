class MaterialItem {
  final String id;
  final String? woodType;
  final String? foamType;
  final String? type;
  final num width;
  final num height;
  final num length;
  final num thickness;
  final String? unit;
  final num squareMeter;
  final num price;
  final num quantity;
  final String? description;

  MaterialItem({
    required this.id,
    this.woodType,
    this.foamType,
    this.type,
    required this.width,
    required this.height,
    required this.length,
    required this.thickness,
    this.unit,
    required this.squareMeter,
    required this.price,
    required this.quantity,
    this.description,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json["_id"] ?? "",
      woodType: json["woodType"],
      foamType: json["foamType"],
      type: json["type"],
      width: json["width"] ?? 0,
      height: json["height"] ?? 0,
      length: json["length"] ?? 0,
      thickness: json["thickness"] ?? 0,
      unit: json["unit"],
      squareMeter: json["squareMeter"] ?? 0,
      price: json["price"] ?? 0,
      quantity: json["quantity"] ?? 0,
      description: json["description"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "woodType": woodType,
      "foamType": foamType,
      "type": type,
      "width": width,
      "height": height,
      "length": length,
      "thickness": thickness,
      "unit": unit,
      "squareMeter": squareMeter,
      "price": price,
      "quantity": quantity,
      "description": description,
    };
  }
}

class AdditionalCost {
  final String id;
  final String name;
  final num amount;
  final String description;

  AdditionalCost({
    required this.id,
    required this.name,
    required this.amount,
    required this.description,
  });

  factory AdditionalCost.fromJson(Map<String, dynamic> json) {
    return AdditionalCost(
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
      amount: json["amount"] ?? 0,
      description: json["description"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "amount": amount,
      "description": description,
    };
  }
}
