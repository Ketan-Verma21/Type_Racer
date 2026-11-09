import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:type_racer/config/env.dart';

/// One shared socket connection for the whole app.
class SocketClient {
  final io.Socket socket;
  static SocketClient? _instance;

  SocketClient._internal()
      : socket = io.io(
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
        ) {
    _connect();
  }

  static SocketClient get instance => _instance ??= SocketClient._internal();

  DateTime? _lastConnectCall;
  void _connect() {
    _lastConnectCall = DateTime.now();
    socket.connect();
  }

  /// Connect if we aren't connected yet (safe to call any time).
  void ensureConnected() {
    if (socket.connected) return;
    // don't start a second connection attempt while one is in progress
    final last = _lastConnectCall;
    if (last != null && DateTime.now().difference(last).inSeconds < 5) return;
    _connect();
  }
}
