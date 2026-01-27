import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/court_643.dart';
import '../services/api_service.dart';

class CourtProvider extends ChangeNotifier {
  List<Court643> _courts = [];
  bool _isLoading = false;

  List<Court643> get courts => _courts;
  bool get isLoading => _isLoading;

  Future<void> fetchCourts(String token) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      final response = await dio.get('/api/courts', options: Options(headers: {'Authorization': 'Bearer $token'}));
      
      if (response.statusCode == 200) {
        final List data = response.data;
        _courts = data.map((json) => Court643.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching courts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
