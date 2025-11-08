import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/job_model.dart';
import '../config/constants.dart';

class JobProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<JobModel> _jobs = [];
  JobModel? _activeJob;
  bool _isLoading = false;
  String? _error;

  List<JobModel> get jobs => _jobs;
  JobModel? get activeJob => _activeJob;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchJobs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final response = await _supabase
          .from('jobs')
          .select('*, vehicles(*), technicians:profiles!jobs_technician_id_fkey(*), addresses(*)')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);

      _jobs = (response as List).map((json) => JobModel.fromJson(json)).toList();
      
      // Find active job
      _activeJob = _jobs.firstWhere(
        (job) => job.status == 'assigned' || job.status == 'in_progress',
        orElse: () => _jobs.firstWhere(
          (job) => job.status == 'pending',
          orElse: () => _jobs.first,
        ),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<JobModel?> createJob({
    required String vehicleId,
    required String addressId,
    required String oilType,
    required double latitude,
    required double longitude,
    required DateTime scheduledFor,
    required String paymentMethodId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/jobs/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'vehicleId': vehicleId,
          'addressId': addressId,
          'oilType': oilType,
          'latitude': latitude,
          'longitude': longitude,
          'scheduledFor': scheduledFor.toIso8601String(),
          'paymentMethodId': paymentMethodId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final job = JobModel.fromJson(data['job']);
        _jobs.insert(0, job);
        _activeJob = job;
        _isLoading = false;
        notifyListeners();
        return job;
      } else {
        throw Exception('Failed to create job');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> subscribeToJob(String jobId) async {
    _supabase
        .channel('job_$jobId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'jobs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: jobId,
          ),
          callback: (payload) {
            final updatedJob = JobModel.fromJson(payload.newRecord);
            final index = _jobs.indexWhere((j) => j.id == jobId);
            if (index != -1) {
              _jobs[index] = updatedJob;
              if (_activeJob?.id == jobId) {
                _activeJob = updatedJob;
              }
              notifyListeners();
            }
          },
        )
        .subscribe();
  }
}
