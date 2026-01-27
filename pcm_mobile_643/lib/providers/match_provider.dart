import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/match_643.dart';
import '../services/api_service.dart';

class MatchProvider extends ChangeNotifier {
  List<Match643> _matches = [];
  bool _isLoading = false;

  List<Match643> get matches => _matches;
  bool get isLoading => _isLoading;

  Future<void> fetchMatches(String token, int tournamentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      final response = await dio.get(
        '/api/matches',
        queryParameters: {'tournamentId': tournamentId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        _matches = data.map((json) => Match643.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching matches: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
