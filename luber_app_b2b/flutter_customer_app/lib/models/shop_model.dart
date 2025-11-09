class Shop {
  final String id;
  final String shopName;
  final String businessLegalName;
  final String businessEmail;
  final String businessPhone;
  final String businessAddress;
  final String businessCity;
  final String businessState;
  final String businessZip;
  final String? logoUrl;
  final String? brandPrimaryColor;
  final String? brandSecondaryColor;
  final String subscriptionTier; // 'solo' | 'business'
  final int serviceRadiusMiles;
  final int totalTechnicians;
  final double? averageRating;
  final bool isActive;
  final String subscriptionStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional field for distance calculation (not from database)
  final double? distanceMiles;

  Shop({
    required this.id,
    required this.shopName,
    required this.businessLegalName,
    required this.businessEmail,
    required this.businessPhone,
    required this.businessAddress,
    required this.businessCity,
    required this.businessState,
    required this.businessZip,
    this.logoUrl,
    this.brandPrimaryColor,
    this.brandSecondaryColor,
    required this.subscriptionTier,
    required this.serviceRadiusMiles,
    required this.totalTechnicians,
    this.averageRating,
    required this.isActive,
    required this.subscriptionStatus,
    required this.createdAt,
    required this.updatedAt,
    this.distanceMiles,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      shopName: json['shop_name'] as String,
      businessLegalName: json['business_legal_name'] as String,
      businessEmail: json['business_email'] as String,
      businessPhone: json['business_phone'] as String,
      businessAddress: json['business_address'] as String,
      businessCity: json['business_city'] as String,
      businessState: json['business_state'] as String,
      businessZip: json['business_zip'] as String,
      logoUrl: json['logo_url'] as String?,
      brandPrimaryColor: json['brand_primary_color'] as String?,
      brandSecondaryColor: json['brand_secondary_color'] as String?,
      subscriptionTier: json['subscription_tier'] as String,
      serviceRadiusMiles: json['service_radius_miles'] as int,
      totalTechnicians: json['total_technicians'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      subscriptionStatus: json['subscription_status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      distanceMiles: (json['distance'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_name': shopName,
      'business_legal_name': businessLegalName,
      'business_email': businessEmail,
      'business_phone': businessPhone,
      'business_address': businessAddress,
      'business_city': businessCity,
      'business_state': businessState,
      'business_zip': businessZip,
      'logo_url': logoUrl,
      'brand_primary_color': brandPrimaryColor,
      'brand_secondary_color': brandSecondaryColor,
      'subscription_tier': subscriptionTier,
      'service_radius_miles': serviceRadiusMiles,
      'total_technicians': totalTechnicians,
      'average_rating': averageRating,
      'is_active': isActive,
      'subscription_status': subscriptionStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (distanceMiles != null) 'distance': distanceMiles,
    };
  }

  Shop copyWith({
    String? id,
    String? shopName,
    String? businessLegalName,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? businessCity,
    String? businessState,
    String? businessZip,
    String? logoUrl,
    String? brandPrimaryColor,
    String? brandSecondaryColor,
    String? subscriptionTier,
    int? serviceRadiusMiles,
    int? totalTechnicians,
    double? averageRating,
    bool? isActive,
    String? subscriptionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? distanceMiles,
  }) {
    return Shop(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      businessLegalName: businessLegalName ?? this.businessLegalName,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      businessCity: businessCity ?? this.businessCity,
      businessState: businessState ?? this.businessState,
      businessZip: businessZip ?? this.businessZip,
      logoUrl: logoUrl ?? this.logoUrl,
      brandPrimaryColor: brandPrimaryColor ?? this.brandPrimaryColor,
      brandSecondaryColor: brandSecondaryColor ?? this.brandSecondaryColor,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      serviceRadiusMiles: serviceRadiusMiles ?? this.serviceRadiusMiles,
      totalTechnicians: totalTechnicians ?? this.totalTechnicians,
      averageRating: averageRating ?? this.averageRating,
      isActive: isActive ?? this.isActive,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      distanceMiles: distanceMiles ?? this.distanceMiles,
    );
  }
}
