// Job model for technician app (same as Booking but from technician perspective)
class Job {
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

  // Joined data
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? shop;
  final Map<String, dynamic>? servicePackage;
  final Map<String, dynamic>? vehicle;
  final Map<String, dynamic>? address;

  Job({
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
    this.customer,
    this.shop,
    this.servicePackage,
    this.vehicle,
    this.address,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
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
      customer: json['customer'] as Map<String, dynamic>?,
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
    };
  }

  Job copyWith({
    String? status,
    String? technicianNotes,
    List<String>? beforePhotos,
    List<String>? afterPhotos,
    DateTime? completedAt,
  }) {
    return Job(
      id: id,
      customerId: customerId,
      shopId: shopId,
      shopTechnicianId: shopTechnicianId,
      servicePackageId: servicePackageId,
      vehicleId: vehicleId,
      addressId: addressId,
      scheduledDate: scheduledDate,
      scheduledTimeSlot: scheduledTimeSlot,
      status: status ?? this.status,
      totalPrice: totalPrice,
      transactionFee: transactionFee,
      shopPayout: shopPayout,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      customerNotes: customerNotes,
      beforePhotos: beforePhotos ?? this.beforePhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt ?? this.completedAt,
      customer: customer,
      shop: shop,
      servicePackage: servicePackage,
      vehicle: vehicle,
      address: address,
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

  bool get canAccept => isPending;
  bool get canStart => isAccepted;
  bool get canComplete => isInProgress;

  double get technicianEarnings {
    if (shopPayout != null) return shopPayout!;
    return totalPrice - (transactionFee ?? 0);
  }

  String get customerName => customer?['full_name'] as String? ?? 'Customer';
  String get vehicleInfo {
    if (vehicle == null) return 'No vehicle info';
    final year = vehicle!['year'];
    final make = vehicle!['make'];
    final model = vehicle!['model'];
    return '$year $make $model';
  }

  String get locationAddress {
    if (address == null) return 'No address';
    return address!['street_address'] as String? ?? 'No address';
  }
}
