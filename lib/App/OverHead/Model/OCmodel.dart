class OverheadCost {
  final String id;
  final String category;
  final String description;
  final String period;
  final double cost;
  final String user;
  final DateTime createdAt;

  OverheadCost({
    required this.id,
    required this.category,
    required this.description,
    required this.period,
    required this.cost,
    required this.user,
    required this.createdAt,
  });

  factory OverheadCost.fromJson(Map<String, dynamic> json) {
    return OverheadCost(
      id: json["_id"],
      category: json["category"],
      description: json["description"],
      period: json["period"],
      cost: (json["cost"] as num).toDouble(),
      user: json["user"],
      createdAt: DateTime.parse(json["createdAt"]),
    );
  }
}
