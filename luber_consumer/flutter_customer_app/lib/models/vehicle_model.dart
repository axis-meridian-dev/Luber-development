class VehicleModel {
  final String id;
  final String customerId;
  final String make;
  final String model;
  final int year;
  final String vehicleType;
  final double? oilCapacity;
  final String recommendedOilType;
  final String? licensePlate;
  final String? vin;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleModel({
    required this.id,
    required this.customerId,
    required this.make,
    required this.model,
    required this.year,
    required this.vehicleType,
    this.oilCapacity,
    required this.recommendedOilType,
    this.licensePlate,
    this.vin,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      customerId: json['user_id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      vehicleType: json['vehicle_type'],
      oilCapacity: json['oil_capacity']?.toDouble(),
      recommendedOilType: json['recommended_oil_type'],
      licensePlate: json['license_plate'],
      vin: json['vin'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'vehicle_type': vehicleType,
      'oil_capacity': oilCapacity,
      'recommended_oil_type': recommendedOilType,
      'license_plate': licensePlate,
      'vin': vin,
      'is_default': isDefault,
    };
  }

  String get displayName => '$year $make $model';
}
