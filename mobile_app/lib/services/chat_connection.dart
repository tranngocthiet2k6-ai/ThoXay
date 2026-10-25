/// One authenticated conversation. Closing the screen must close this transport.
class ChatConnection {
  ChatConnection({required this.events, required this.close});
  final Stream<Map<String, dynamic>> events;
  final Future<void> Function() close;
}
