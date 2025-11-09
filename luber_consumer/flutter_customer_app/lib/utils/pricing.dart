/// Pricing utility for calculating job prices
///
/// Ports the pricing logic from the Next.js web app (lib/pricing.ts)
/// - Base prices per oil type
/// - Vehicle type multipliers
/// - 20% platform fee calculation

// Base pricing in cents
const Map<String, int> basePrices = {
  'conventional': 3999, // $39.99
  'synthetic_blend': 5999, // $59.99
  'full_synthetic': 7999, // $79.99
  'high_mileage': 6999, // $69.99
};

// Vehicle type multipliers
const Map<String, double> vehicleMultipliers = {
  'sedan': 1.0,
  'suv': 1.2,
  'truck': 1.3,
  'sports_car': 1.4,
  'hybrid': 1.1,
  'electric': 0, // No oil changes for electric vehicles
};

// Oil type display names
const Map<String, String> oilTypeNames = {
  'conventional': 'Conventional Oil',
  'synthetic_blend': 'Synthetic Blend',
  'full_synthetic': 'Full Synthetic',
  'high_mileage': 'High Mileage',
};

// Oil type descriptions
const Map<String, String> oilTypeDescriptions = {
  'conventional': 'Standard motor oil for regular driving',
  'synthetic_blend': 'Mix of synthetic and conventional for better protection',
  'full_synthetic': 'Premium oil for maximum engine protection',
  'high_mileage': 'Formulated for vehicles with 75,000+ miles',
};

class PricingResult {
  final int priceCents;
  final int platformFeeCents;
  final int technicianEarningsCents;

  PricingResult({
    required this.priceCents,
    required this.platformFeeCents,
    required this.technicianEarningsCents,
  });

  double get priceDollars => priceCents / 100.0;
  double get platformFeeDollars => platformFeeCents / 100.0;
  double get technicianEarningsDollars => technicianEarningsCents / 100.0;

  String get priceFormatted => '\$${priceDollars.toStringAsFixed(2)}';
  String get platformFeeFormatted => '\$${platformFeeDollars.toStringAsFixed(2)}';
  String get technicianEarningsFormatted => '\$${technicianEarningsDollars.toStringAsFixed(2)}';
}

/// Calculate job price based on oil type and vehicle type
///
/// Returns pricing breakdown including total price, platform fee, and technician earnings
PricingResult calculateJobPrice(String oilType, String vehicleType) {
  final basePrice = basePrices[oilType] ?? basePrices['conventional']!;
  final multiplier = vehicleMultipliers[vehicleType] ?? 1.0;
  final totalPrice = (basePrice * multiplier).round();

  // Platform takes 20% fee
  final platformFee = (totalPrice * 0.2).round();
  final technicianEarnings = totalPrice - platformFee;

  return PricingResult(
    priceCents: totalPrice,
    platformFeeCents: platformFee,
    technicianEarningsCents: technicianEarnings,
  );
}

/// Get display name for oil type
String getOilTypeName(String oilType) {
  return oilTypeNames[oilType] ?? oilType;
}

/// Get description for oil type
String getOilTypeDescription(String oilType) {
  return oilTypeDescriptions[oilType] ?? '';
}

/// Get base price for oil type in dollars
double getBasePrice(String oilType) {
  final priceCents = basePrices[oilType] ?? basePrices['conventional']!;
  return priceCents / 100.0;
}

/// Format cents as dollar string
String formatPrice(int cents) {
  return '\$${(cents / 100.0).toStringAsFixed(2)}';
}
