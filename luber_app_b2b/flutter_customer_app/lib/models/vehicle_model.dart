class Vehicle {
  final String id;
  final String customerId;
  final String make;
  final String model;
  final int year;
  final String? color;
  final String? licensePlate;
  final String? vin;
  final String vehicleType; // 'sedan' | 'suv' | 'truck' | 'van' | 'sports' | 'other'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.customerId,
    required this.make,
    required this.model,
    required this.year,
    this.color,
    this.licensePlate,
    this.vin,
    required this.vehicleType,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      color: json['color'] as String?,
      licensePlate: json['license_plate'] as String?,
      vin: json['vin'] as String?,
      vehicleType: json['vehicle_type'] as String? ?? 'sedan',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'license_plate': licensePlate,
      'vin': vin,
      'vehicle_type': vehicleType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Vehicle copyWith({
    String? id,
    String? customerId,
    String? make,
    String? model,
    int? year,
    String? color,
    String? licensePlate,
    String? vin,
    String? vehicleType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      vehicleType: vehicleType ?? this.vehicleType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    return '$year $make $model';
  }

  String get vehicleTypeDisplay {
    switch (vehicleType) {
      case 'sedan':
        return 'Sedan';
      case 'suv':
        return 'SUV';
      case 'truck':
        return 'Truck';
      case 'van':
        return 'Van';
      case 'sports':
        return 'Sports Car';
      case 'other':
        return 'Other';
      default:
        return 'Vehicle';
    }
  }
}
