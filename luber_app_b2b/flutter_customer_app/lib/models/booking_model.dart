class Booking {
  final String id;
  final String customerId;
  final String? shopId;
  final String? shopTechnicianId;
  final String? servicePackageId;
  final String? vehicleId;
  final String? addressId;
  final String scheduledDate;
  final String scheduledTimeSlot;
  final String status; // 'pending' | 'accepted' | 'in_progress' | 'completed' | 'cancelled'
  final double totalPrice;
  final double? transactionFee;
  final double? shopPayout;
  final String? technicianNotes;
  final String? customerNotes;
  final List<String>? beforePhotos;
  final List<String>? afterPhotos;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  // Joined data (from relations)
  final Map<String, dynamic>? shop;
  final Map<String, dynamic>? servicePackage;
  final Map<String, dynamic>? vehicle;
  final Map<String, dynamic>? address;

  Booking({
    required this.id,
    required this.customerId,
    this.shopId,
    this.shopTechnicianId,
    this.servicePackageId,
    this.vehicleId,
    this.addressId,
    required this.scheduledDate,
    required this.scheduledTimeSlot,
    required this.status,
    required this.totalPrice,
    this.transactionFee,
    this.shopPayout,
    this.technicianNotes,
    this.customerNotes,
    this.beforePhotos,
    this.afterPhotos,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    this.shop,
    this.servicePackage,
    this.vehicle,
    this.address,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      shopId: json['shop_id'] as String?,
      shopTechnicianId: json['shop_technician_id'] as String?,
      servicePackageId: json['service_package_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      addressId: json['address_id'] as String?,
      scheduledDate: json['scheduled_date'] as String,
      scheduledTimeSlot: json['scheduled_time_slot'] as String,
      status: json['status'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
      transactionFee: (json['transaction_fee'] as num?)?.toDouble(),
      shopPayout: (json['shop_payout'] as num?)?.toDouble(),
      technicianNotes: json['technician_notes'] as String?,
      customerNotes: json['customer_notes'] as String?,
      beforePhotos: (json['before_photos'] as List<dynamic>?)?.map((e) => e as String).toList(),
      afterPhotos: (json['after_photos'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at'] as String) : null,
      shop: json['shop'] as Map<String, dynamic>?,
      servicePackage: json['service_package'] as Map<String, dynamic>?,
      vehicle: json['vehicle'] as Map<String, dynamic>?,
      address: json['address'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'shop_id': shopId,
      'shop_technician_id': shopTechnicianId,
      'service_package_id': servicePackageId,
      'vehicle_id': vehicleId,
      'address_id': addressId,
      'scheduled_date': scheduledDate,
      'scheduled_time_slot': scheduledTimeSlot,
      'status': status,
      'total_price': totalPrice,
      'transaction_fee': transactionFee,
      'shop_payout': shopPayout,
      'technician_notes': technicianNotes,
      'customer_notes': customerNotes,
      'before_photos': beforePhotos,
      'after_photos': afterPhotos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  Booking copyWith({
    String? id,
    String? customerId,
    String? shopId,
    String? shopTechnicianId,
    String? servicePackageId,
    String? vehicleId,
    String? addressId,
    String? scheduledDate,
    String? scheduledTimeSlot,
    String? status,
    double? totalPrice,
    double? transactionFee,
    double? shopPayout,
    String? technicianNotes,
    String? customerNotes,
    List<String>? beforePhotos,
    List<String>? afterPhotos,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      shopId: shopId ?? this.shopId,
      shopTechnicianId: shopTechnicianId ?? this.shopTechnicianId,
      servicePackageId: servicePackageId ?? this.servicePackageId,
      vehicleId: vehicleId ?? this.vehicleId,
      addressId: addressId ?? this.addressId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTimeSlot: scheduledTimeSlot ?? this.scheduledTimeSlot,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      transactionFee: transactionFee ?? this.transactionFee,
      shopPayout: shopPayout ?? this.shopPayout,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      customerNotes: customerNotes ?? this.customerNotes,
      beforePhotos: beforePhotos ?? this.beforePhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canCancel => isPending || isAccepted;
  bool get canReview => isCompleted;
}
