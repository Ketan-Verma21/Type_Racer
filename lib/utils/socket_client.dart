import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Server address, chosen at build/run time (no trailing slash):
///   flutter run -d chrome --dart-define=SERVER_URL=http://localhost:3000
/// Without --dart-define the app uses the hosted server.
const String kServerUrl = String.fromEnvironment(
  'SERVER_URL',
  defaultValue: 'https://typ-racer-server.onrender.com',
);

/// One shared socket connection for the whole app.
class SocketClient {
  IO.Socket? socket;
  static SocketClient? _instance;

  SocketClient._internal() {
    socket = IO.io(
      kServerUrl,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        // keep retrying (a sleeping free-tier server needs ~1 min to wake up)
        'reconnection': true,
        'reconnectionAttempts': 100000,
        'reconnectionDelay': 2000,
        'reconnectionDelayMax': 10000,
        'timeout': 20000,
      },
    );
    _connect();
  }

  DateTime? _lastConnectCall;
  void _connect() {
    _lastConnectCall = DateTime.now();
    socket!.connect();
  }

  static SocketClient get instance {
    _instance ??= SocketClient._internal();
    return _instance!;
  }

  /// Connect if we aren't connected yet (safe to call any time).
  void ensureConnected() {
    final s = socket;
    if (s == null || s.connected) return;
    // don't start a second connection attempt while one is in progress
    final last = _lastConnectCall;
    if (last != null && DateTime.now().difference(last).inSeconds < 5) return;
    _connect();
  }
}
