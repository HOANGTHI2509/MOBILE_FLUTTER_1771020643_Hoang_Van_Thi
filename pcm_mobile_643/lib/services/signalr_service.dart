import 'package:signalr_netcore/signalr_client.dart';
import 'api_service.dart';

class SignalRService {
  late HubConnection _hubConnection;
  Function(String)? onNotificationReceived;
  Function()? onCalendarUpdate;

  // Singleton
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  Future<void> initSignalR() async {
    final baseUrl = ApiService.baseUrl; // E.g http://10.0.2.2:5282
    final hubUrl = "$baseUrl/pcmHub";

    _hubConnection = HubConnectionBuilder().withUrl(hubUrl).build();

    _hubConnection.onclose(({error}) => print("SignalR Connection Closed"));

    _hubConnection.on("ReceiveNotification", (arguments) {
      final message = arguments?[0] as String?;
      if (message != null && onNotificationReceived != null) {
        onNotificationReceived!(message);
      }
    });

    _hubConnection.on("UpdateCalendar", (arguments) {
      if (onCalendarUpdate != null) {
        onCalendarUpdate!();
      }
    });

    try {
      await _hubConnection.start();
      print("SignalR Connected!");
    } catch (e) {
      print("SignalR Connection Error: $e");
    }
  }
}
