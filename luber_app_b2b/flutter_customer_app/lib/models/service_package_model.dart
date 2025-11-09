class ServicePackage {
  final String id;
  final String shopId;
  final String packageName;
  final String? description;
  final double price; // in dollars
  final int estimatedDurationMinutes;
  final String? oilType; // 'conventional' | 'synthetic_blend' | 'full_synthetic' | 'high_mileage' | 'diesel'
  final String? oilBrand;
  final bool includesFilter;
  final bool includesInspection;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServicePackage({
    required this.id,
    required this.shopId,
    required this.packageName,
    this.description,
    required this.price,
    required this.estimatedDurationMinutes,
    this.oilType,
    this.oilBrand,
    required this.includesFilter,
    required this.includesInspection,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServicePackage.fromJson(Map<String, dynamic> json) {
    return ServicePackage(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      packageName: json['package_name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int,
      oilType: json['oil_type'] as String?,
      oilBrand: json['oil_brand'] as String?,
      includesFilter: json['includes_filter'] as bool? ?? true,
      includesInspection: json['includes_inspection'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'package_name': packageName,
      'description': description,
      'price': price,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'oil_type': oilType,
      'oil_brand': oilBrand,
      'includes_filter': includesFilter,
      'includes_inspection': includesInspection,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ServicePackage copyWith({
    String? id,
    String? shopId,
    String? packageName,
    String? description,
    double? price,
    int? estimatedDurationMinutes,
    String? oilType,
    String? oilBrand,
    bool? includesFilter,
    bool? includesInspection,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServicePackage(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      packageName: packageName ?? this.packageName,
      description: description ?? this.description,
      price: price ?? this.price,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      oilType: oilType ?? this.oilType,
      oilBrand: oilBrand ?? this.oilBrand,
      includesFilter: includesFilter ?? this.includesFilter,
      includesInspection: includesInspection ?? this.includesInspection,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get durationDisplay {
    final hours = estimatedDurationMinutes ~/ 60;
    final minutes = estimatedDurationMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours hr $minutes min';
    } else if (hours > 0) {
      return '$hours hr';
    } else {
      return '$minutes min';
    }
  }

  String get oilTypeDisplay {
    if (oilType == null) return 'Standard Oil';
    switch (oilType) {
      case 'conventional':
        return 'Conventional Oil';
      case 'synthetic_blend':
        return 'Synthetic Blend';
      case 'full_synthetic':
        return 'Full Synthetic';
      case 'high_mileage':
        return 'High Mileage';
      case 'diesel':
        return 'Diesel Oil';
      default:
        return 'Standard Oil';
    }
  }
}
