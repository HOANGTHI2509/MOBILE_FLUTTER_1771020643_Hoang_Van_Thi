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

  Future<void> initSignalR(String? token) async {
    final baseUrl = ApiService.baseUrl; // E.g http://10.0.2.2:5282
    final hubUrl = "$baseUrl/pcmHub";

    final builder = HubConnectionBuilder().withUrl(hubUrl, 
      options: HttpConnectionOptions(
        accessTokenFactory: () async => token ?? ''
      )
    );
    _hubConnection = builder.build();

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

    _hubConnection.on("UpdateMatchScore", (arguments) {
      if (arguments != null && arguments.length >= 3) {
        final matchId = arguments[0];
        final score1 = arguments[1];
        final score2 = arguments[2];
        if (onMatchScoreUpdate != null) {
          onMatchScoreUpdate!(matchId.toString(), score1.toString(), score2.toString());
        }
      }
    });

    try {
      await _hubConnection.start();
      print("SignalR Connected!");
    } catch (e) {
      print("SignalR Connection Error: $e");
    }
  }

  // Methods to call Server Hub
  Future<void> joinMatchGroup(String matchId) async {
    if (_hubConnection.state == HubConnectionState.Connected) {
      await _hubConnection.invoke("JoinMatchGroup", args: [matchId]);
    }
  }

  Future<void> leaveMatchGroup(String matchId) async {
    if (_hubConnection.state == HubConnectionState.Connected) {
      await _hubConnection.invoke("LeaveMatchGroup", args: [matchId]);
    }
  }

  // Callback for UI to register
  Function(String, String, String)? onMatchScoreUpdate;
}
