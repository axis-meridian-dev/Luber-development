import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/technician_model.dart';

class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String userType;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    required this.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      userType: json['user_type'],
    );
  }
}

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  UserModel? _currentUser;
  TechnicianModel? _technicianProfile;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  TechnicianModel? get technicianProfile => _technicianProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isApproved => _technicianProfile?.isApproved ?? false;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _fetchProfile();
    }
    
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _fetchProfile();
      } else {
        _currentUser = null;
        _technicianProfile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = UserModel.fromJson(userResponse);

      final techResponse = await _supabase
          .from('technicians')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (techResponse != null) {
        _technicianProfile = TechnicianModel.fromJson(techResponse);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      await _fetchProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String certificationNumber,
    required int yearsExperience,
    String? bio,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Sign up user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'user_type': 'technician',
        },
      );

      if (authResponse.user != null) {
        // Create technician profile
        await _supabase.from('technicians').insert({
          'user_id': authResponse.user!.id,
          'certification_number': certificationNumber,
          'years_experience': yearsExperience,
          'bio': bio,
          'status': 'pending',
        });

        await _fetchProfile();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _technicianProfile = null;
    notifyListeners();
  }
  
  Future<void> refreshProfile() async {
    await _fetchProfile();
  }
}
