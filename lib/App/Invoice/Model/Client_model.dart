class ClientModel {
  final String clientName;
  final String phoneNumber;
  final String email;
  final String clientAddress;
  final String nearestBusStop;

  ClientModel({
    required this.clientName,
    required this.phoneNumber,
    required this.email,
    required this.clientAddress,
    required this.nearestBusStop,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      clientName: json['clientName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      clientAddress: json['clientAddress'] ?? '',
      nearestBusStop: json['nearestBusStop'] ?? '',
    );
  }
}
