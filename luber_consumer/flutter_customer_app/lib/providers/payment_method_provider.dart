import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/constants.dart';
import '../models/payment_method_model.dart';

class PaymentMethodProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final http.Client _httpClient;

  PaymentMethodProvider({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  List<PaymentMethodModel> _paymentMethods = [];
  bool _isLoading = false;
  String? _error;

  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PaymentMethodModel? get defaultMethod {
    try {
      return _paymentMethods.firstWhere((method) => method.isDefault);
    } catch (_) {
      return _paymentMethods.isNotEmpty ? _paymentMethods.first : null;
    }
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  String _requireToken() {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Not authenticated');
    }
    return token;
  }

  Future<void> fetchPaymentMethods() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _requireToken();
      final response = await _httpClient.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/payment-methods'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final entries = data['paymentMethods'] as List<dynamic>;
        _paymentMethods = entries.map((json) => PaymentMethodModel.fromJson(json)).toList();
        _error = null;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to fetch payment methods');
      }
    } catch (e) {
      _error = e.toString();
      _paymentMethods = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPaymentMethod({
    required String cardholderName,
    bool setAsDefault = false,
  }) async {
    try {
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(name: cardholderName),
          ),
        ),
      );

      final token = _requireToken();
      final response = await _httpClient.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/payment-methods/add'),
        headers: _headers(token),
        body: json.encode({
          'paymentMethodId': paymentMethod.id,
          'setAsDefault': setAsDefault,
        }),
      );

      if (response.statusCode == 200) {
        _error = null;
        await fetchPaymentMethods();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to add payment method');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePaymentMethod(String id) async {
    try {
      final token = _requireToken();
      final response = await _httpClient.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/api/payment-methods/delete'),
        headers: _headers(token),
        body: json.encode({'paymentMethodId': id}),
      );

      if (response.statusCode == 200) {
        _error = null;
        await fetchPaymentMethods();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to delete payment method');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefault(String id) async {
    try {
      final token = _requireToken();
      final response = await _httpClient.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/payment-methods/set-default'),
        headers: _headers(token),
        body: json.encode({'paymentMethodId': id}),
      );

      if (response.statusCode == 200) {
        _error = null;
        await fetchPaymentMethods();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to update payment method');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _paymentMethods = [];
    _error = null;
    notifyListeners();
  }
}
