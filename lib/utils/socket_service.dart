import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect(String serverUrl) {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.onConnect((_) {
      print('Socket connected');
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
    });
  }

  void listenForUpdates(Function(Map<String, dynamic>) onUpdate) {
    socket.on('update_status', (data) {
      print('[Socket] 상태 업데이트 수신: $data');
      onUpdate(data);
    });
  }

  void dispose() {
    socket.dispose();
  }
}