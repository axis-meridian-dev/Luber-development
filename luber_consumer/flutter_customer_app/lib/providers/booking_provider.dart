import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../models/address_model.dart';
import '../models/payment_method_model.dart';

/// Booking state provider
///
/// Manages the booking flow state across all steps:
/// 1. Vehicle selection
/// 2. Address selection
/// 3. Service/oil type selection
/// 4. Schedule date/time selection
/// 5. Payment confirmation
class BookingProvider with ChangeNotifier {
  // Selected data
  VehicleModel? _selectedVehicle;
  AddressModel? _selectedAddress;
  String? _selectedOilType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  PaymentMethodModel? _selectedPaymentMethod;
  String? _specialInstructions;

  // Getters
  VehicleModel? get selectedVehicle => _selectedVehicle;
  AddressModel? get selectedAddress => _selectedAddress;
  String? get selectedOilType => _selectedOilType;
  DateTime? get selectedDate => _selectedDate;
  TimeOfDay? get selectedTime => _selectedTime;
  PaymentMethodModel? get selectedPaymentMethod => _selectedPaymentMethod;
  String? get specialInstructions => _specialInstructions;

  /// Get scheduled datetime combining date and time
  DateTime? get scheduledDateTime {
    if (_selectedDate == null || _selectedTime == null) {
      return null;
    }
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  /// Check if step 1 (vehicle) is complete
  bool get isVehicleStepComplete => _selectedVehicle != null;

  /// Check if step 2 (address) is complete
  bool get isAddressStepComplete => _selectedAddress != null;

  /// Check if step 3 (service) is complete
  bool get isServiceStepComplete => _selectedOilType != null;

  /// Check if step 4 (schedule) is complete
  bool get isScheduleStepComplete => _selectedDate != null && _selectedTime != null;

  /// Check if step 5 (payment) is complete
  bool get isPaymentStepComplete => _selectedPaymentMethod != null;

  /// Check if all required data is selected
  bool get isBookingComplete {
    return isVehicleStepComplete &&
        isAddressStepComplete &&
        isServiceStepComplete &&
        isScheduleStepComplete &&
        isPaymentStepComplete;
  }

  // Setters
  void selectVehicle(VehicleModel vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void selectOilType(String oilType) {
    _selectedOilType = oilType;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void selectTime(TimeOfDay time) {
    _selectedTime = time;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethodModel paymentMethod) {
    _selectedPaymentMethod = paymentMethod;
    notifyListeners();
  }
  
  void clearPaymentMethod() {
    _selectedPaymentMethod = null;
    notifyListeners();
  }

  void setSpecialInstructions(String? instructions) {
    _specialInstructions = instructions;
    notifyListeners();
  }

  /// Reset all booking data
  void reset() {
    _selectedVehicle = null;
    _selectedAddress = null;
    _selectedOilType = null;
    _selectedDate = null;
    _selectedTime = null;
    _selectedPaymentMethod = null;
    _specialInstructions = null;
    notifyListeners();
  }

  /// Get booking data as JSON for API submission
  Map<String, dynamic> toJson() {
    if (!isBookingComplete) {
      throw Exception('Booking data is incomplete');
    }

    final scheduledDateTime = this.scheduledDateTime!;

    return {
      'vehicleId': _selectedVehicle!.id,
      'addressId': _selectedAddress!.id,
      'oilType': _selectedOilType,
      'latitude': _selectedAddress!.latitude,
      'longitude': _selectedAddress!.longitude,
      'scheduledFor': scheduledDateTime.toIso8601String(),
      'paymentMethodId': _selectedPaymentMethod!.stripePaymentMethodId,
      'specialInstructions': _specialInstructions,
    };
  }
}
