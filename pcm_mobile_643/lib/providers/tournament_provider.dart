import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/tournament_643.dart';
import '../services/api_service.dart';

class TournamentProvider extends ChangeNotifier {
  List<Tournament643> _tournaments = [];
  bool _isLoading = false;

  List<Tournament643> get tournaments => _tournaments;
  bool get isLoading => _isLoading;

  Future<void> fetchTournaments(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      final response = await dio.get('/api/tournaments', options: Options(headers: {'Authorization': 'Bearer $token'}));

      if (response.statusCode == 200) {
        final List data = response.data;
        _tournaments = data.map((json) => Tournament643.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching tournaments: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinTournament(String token, int tournamentId, String? teamName) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      final response = await dio.post(
        '/api/tournaments/$tournamentId/join',
        data: teamName != null ? "\"$teamName\"" : null, // Send string directly if simple body
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json' 
          }
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error joining tournament: $e");
      return false;
    }
  }

  Future<bool> leaveTournament(String token, int tournamentId) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      final response = await dio.post(
        '/api/tournaments/$tournamentId/leave',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error leaving tournament: $e");
      return false;
    }
  }
}
