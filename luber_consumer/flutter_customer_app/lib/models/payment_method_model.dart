class PaymentMethodModel {
  final String id;
  final String userId;
  final String stripePaymentMethodId;
  final String? cardBrand;
  final String? cardLast4;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.stripePaymentMethodId,
    this.cardBrand,
    this.cardLast4,
    required this.isDefault,
    required this.createdAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'],
      userId: json['user_id'],
      stripePaymentMethodId: json['stripe_payment_method_id'],
      cardBrand: json['card_brand'],
      cardLast4: json['card_last4'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'stripe_payment_method_id': stripePaymentMethodId,
      'card_brand': cardBrand,
      'card_last4': cardLast4,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayName {
    if (cardBrand != null && cardLast4 != null) {
      final brand = cardBrand!.toUpperCase();
      return '$brand •••• $cardLast4';
    }
    return 'Payment Method';
  }
}
