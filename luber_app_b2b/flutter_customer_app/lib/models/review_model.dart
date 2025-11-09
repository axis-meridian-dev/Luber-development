class Review {
  final String id;
  final String bookingId;
  final String customerId;
  final String? shopId;
  final int rating; // Overall rating 1-5
  final int? serviceQualityRating; // 1-5
  final int? communicationRating; // 1-5
  final int? valueRating; // 1-5
  final bool? wouldRecommend;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final Map<String, dynamic>? booking;
  final Map<String, dynamic>? shop;

  Review({
    required this.id,
    required this.bookingId,
    required this.customerId,
    this.shopId,
    required this.rating,
    this.serviceQualityRating,
    this.communicationRating,
    this.valueRating,
    this.wouldRecommend,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
    this.booking,
    this.shop,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      customerId: json['customer_id'] as String,
      shopId: json['shop_id'] as String?,
      rating: json['rating'] as int,
      serviceQualityRating: json['service_quality_rating'] as int?,
      communicationRating: json['communication_rating'] as int?,
      valueRating: json['value_rating'] as int?,
      wouldRecommend: json['would_recommend'] as bool?,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      booking: json['booking'] as Map<String, dynamic>?,
      shop: json['shop'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'customer_id': customerId,
      'shop_id': shopId,
      'rating': rating,
      'service_quality_rating': serviceQualityRating,
      'communication_rating': communicationRating,
      'value_rating': valueRating,
      'would_recommend': wouldRecommend,
      'review_text': reviewText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Review copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? shopId,
    int? rating,
    int? serviceQualityRating,
    int? communicationRating,
    int? valueRating,
    bool? wouldRecommend,
    String? reviewText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      shopId: shopId ?? this.shopId,
      rating: rating ?? this.rating,
      serviceQualityRating: serviceQualityRating ?? this.serviceQualityRating,
      communicationRating: communicationRating ?? this.communicationRating,
      valueRating: valueRating ?? this.valueRating,
      wouldRecommend: wouldRecommend ?? this.wouldRecommend,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get averageDetailedRating {
    final ratings = [
      serviceQualityRating,
      communicationRating,
      valueRating,
    ].where((r) => r != null).map((r) => r!).toList();

    if (ratings.isEmpty) return rating.toDouble();

    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  String get ratingDisplay {
    return '$rating/5';
  }
}
