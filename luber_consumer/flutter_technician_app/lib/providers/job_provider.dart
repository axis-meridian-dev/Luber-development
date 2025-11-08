import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/job_model.dart';
import '../config/constants.dart';

class JobProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<JobModel> _availableJobs = [];
  List<JobModel> _myJobs = [];
  JobModel? _activeJob;
  bool _isLoading = false;
  String? _error;

  List<JobModel> get availableJobs => _availableJobs;
  List<JobModel> get myJobs => _myJobs;
  JobModel? get activeJob => _activeJob;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAvailableJobs(double latitude, double longitude) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .rpc('get_nearby_jobs', params: {
            'user_lat': latitude,
            'user_long': longitude,
            'radius_miles': AppConstants.jobSearchRadiusMiles,
          });

      _availableJobs = (response as List)
          .map((json) => JobModel.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyJobs() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get technician ID
      final techResponse = await _supabase
          .from('technicians')
          .select('id')
          .eq('user_id', userId)
          .single();

      final technicianId = techResponse['id'];

      final response = await _supabase
          .from('jobs')
          .select('*, vehicles(*), customers:profiles!jobs_customer_id_fkey(*), addresses(*)')
          .eq('technician_id', technicianId)
          .order('created_at', ascending: false);

      _myJobs = (response as List).map((json) => JobModel.fromJson(json)).toList();
      
      // Find active job
      _activeJob = _myJobs.firstWhere(
        (job) => job.status == 'assigned' || job.status == 'in_progress',
        orElse: () => _myJobs.first,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> acceptJob(String jobId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/jobs/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'jobId': jobId}),
      );

      if (response.statusCode == 200) {
        await fetchMyJobs();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to accept job');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> startJob(String jobId) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('Not authenticated');

      await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/jobs/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'jobId': jobId}),
      );

      await fetchMyJobs();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeJob(String jobId, List<String> photoUrls) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/jobs/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'jobId': jobId,
          'photoUrls': photoUrls,
        }),
      );

      if (response.statusCode == 200) {
        await fetchMyJobs();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
