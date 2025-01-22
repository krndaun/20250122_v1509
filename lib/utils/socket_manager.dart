import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketManager {
  IO.Socket? socket;

  void initializeSocket(String url, Function(dynamic) onUpdate) {
    socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) => print('Socket.IO 연결 성공'));
    socket!.on('update', (data) {
      print('소켓 업데이트 데이터: $data');
      onUpdate(data);
    });
    socket!.onDisconnect((_) => print('Socket.IO 연결 끊김'));
  }

  void disconnect() {
    socket?.disconnect();
  }
}