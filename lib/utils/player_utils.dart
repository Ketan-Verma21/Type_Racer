// TODO Implement this library.import 'package:type_racer/utils/socket_client.dart';

import 'package:type_racer/utils/socket_client.dart';

/// Returns the player entry that belongs to this device, or null if it
/// isn't found (e.g. after a reconnect the socket id changes, or the game
/// state was reset). Always null-check the result.
dynamic findMe(List players) {
  final id = SocketClient.instance.socket?.id;
  for (final p in players) {
    if (p['socketID'] == id) return p;
  }
  return null;
}
