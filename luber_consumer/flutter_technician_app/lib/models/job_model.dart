class JobModel {
  final String id;
  final String customerId;
  final String? technicianId;
  final String vehicleId;
  final String addressId;
  final String oilType;
  final double latitude;
  final double longitude;
  final DateTime scheduledFor;
  final String status;
  final double subtotal;
  final double platformFee;
  final double totalPrice;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  
  // Populated fields
  final Map<String, dynamic>? vehicle;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? address;
  
  // Calculated field
  final double? distanceInMiles;

  JobModel({
    required this.id,
    required this.customerId,
    this.technicianId,
    required this.vehicleId,
    required this.addressId,
    required this.oilType,
    required this.latitude,
    required this.longitude,
    required this.scheduledFor,
    required this.status,
    required this.subtotal,
    required this.platformFee,
    required this.totalPrice,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    this.vehicle,
    this.customer,
    this.address,
    this.distanceInMiles,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'],
      customerId: json['customer_id'],
      technicianId: json['technician_id'],
      vehicleId: json['vehicle_id'],
      addressId: json['address_id'],
      oilType: json['oil_type'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      scheduledFor: DateTime.parse(json['scheduled_for']),
      status: json['status'],
      subtotal: json['subtotal'].toDouble(),
      platformFee: json['platform_fee'].toDouble(),
      totalPrice: json['total_price'].toDouble(),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      vehicle: json['vehicles'],
      customer: json['customers'],
      address: json['addresses'],
      distanceInMiles: json['distance_miles']?.toDouble(),
    );
  }

  double get technicianEarnings => subtotal; // Subtotal goes to technician (80%)
  
  String get vehicleDisplay => vehicle != null 
      ? '${vehicle!['year']} ${vehicle!['make']} ${vehicle!['model']}'
      : 'Vehicle';
      
  String get customerName => customer?['full_name'] ?? 'Customer';
  String get customerPhone => customer?['phone_number'] ?? '';
  String get fullAddress => address?['street'] ?? '';
}
