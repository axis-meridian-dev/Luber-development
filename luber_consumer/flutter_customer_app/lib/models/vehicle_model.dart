class VehicleModel {
  final String id;
  final String customerId;
  final String make;
  final String model;
  final int year;
  final String? licensePlate;
  final String? color;
  final bool isDefault;
  final DateTime createdAt;

  VehicleModel({
    required this.id,
    required this.customerId,
    required this.make,
    required this.model,
    required this.year,
    this.licensePlate,
    this.color,
    required this.isDefault,
    required this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      customerId: json['customer_id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      licensePlate: json['license_plate'],
      color: json['color'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get displayName => '$year $make $model';
}
