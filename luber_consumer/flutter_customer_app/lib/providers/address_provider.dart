import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/constants.dart';
import '../models/address_model.dart';

class AddressProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final http.Client _httpClient;

  AddressProvider({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _error;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AddressModel? get defaultAddress {
    if (_addresses.isEmpty) return null;
    try {
      return _addresses.firstWhere((address) => address.isDefault);
    } catch (_) {
      return _addresses.first;
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

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _requireToken();
      final response = await _httpClient.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/addresses'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final entries = data['addresses'] as List<dynamic>;
        _addresses = entries.map((json) => AddressModel.fromJson(json)).toList();
        _error = null;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to load addresses');
      }
    } catch (e) {
      _error = e.toString();
      _addresses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress({
    required String label,
    required String streetAddress,
    required String city,
    required String state,
    required String zipCode,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    try {
      final token = _requireToken();
      final response = await _httpClient.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/addresses'),
        headers: _headers(token),
        body: json.encode({
          'label': label,
          'street_address': streetAddress,
          'city': city,
          'state': state,
          'zip_code': zipCode,
          'latitude': latitude,
          'longitude': longitude,
          'is_default': isDefault,
        }),
      );

      if (response.statusCode == 201) {
        await fetchAddresses();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to create address');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAddress(
    String id, {
    String? label,
    String? streetAddress,
    String? city,
    String? state,
    String? zipCode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      final token = _requireToken();
      final payload = <String, dynamic>{
      };
      if (label != null) payload['label'] = label;
      if (streetAddress != null) payload['street_address'] = streetAddress;
      if (city != null) payload['city'] = city;
      if (state != null) payload['state'] = state;
      if (zipCode != null) payload['zip_code'] = zipCode;
      if (latitude != null) payload['latitude'] = latitude;
      if (longitude != null) payload['longitude'] = longitude;
      if (isDefault != null) {
        payload['is_default'] = isDefault;
      }
      if (payload.isEmpty) {
        return true;
      }
      final response = await _httpClient.patch(
        Uri.parse('${AppConstants.apiBaseUrl}/api/addresses/$id'),
        headers: _headers(token),
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        await fetchAddresses();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to update address');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefaultAddress(String id) async {
    return updateAddress(id, isDefault: true);
  }

  Future<bool> deleteAddress(String id) async {
    try {
      final token = _requireToken();
      final response = await _httpClient.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/api/addresses/$id'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        await fetchAddresses();
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to delete address');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _addresses = [];
    _error = null;
    notifyListeners();
  }
}
