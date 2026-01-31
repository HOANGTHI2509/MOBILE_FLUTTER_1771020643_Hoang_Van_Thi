import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/booking_643.dart';
import '../services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  List<Booking643> _bookings = [];
  bool _isLoading = false;

  List<Booking643> get bookings => _bookings;
  bool get isLoading => _isLoading;

  Future<void> fetchCalendar(String token, DateTime from, DateTime to) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      final response = await dio.get(
        '/api/bookings/calendar',
        queryParameters: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        _bookings = data.map((json) => Booking643.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching calendar: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Booking643?> holdBooking(String token, Map<String, dynamic> bookingData) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      final response = await dio.post(
        '/api/bookings/hold',
        data: bookingData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 201) {
        return Booking643.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error holding booking: $e");
      return null;
    }
  }

  Future<bool> confirmBooking(String token, int bookingId) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      final response = await dio.post(
        '/api/bookings/confirm/$bookingId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error confirming booking: $e");
      return false;
    }
  }

  Future<String?> createRecurringBooking(String token, Map<String, dynamic> data) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      final response = await dio.post(
        '/api/bookings/recurring',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return null; // Success (no error message)
      }
      return "Lỗi không xác định";
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response?.data.toString();
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> cancelBooking(String token, int bookingId) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      final response = await dio.post(
        '/api/bookings/cancel/$bookingId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error cancelling booking: $e");
      return null;
    }
  }
}
