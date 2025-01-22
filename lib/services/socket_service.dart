import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:nesysworks/models/request_item.dart';

class SocketService {
  IO.Socket? socket;

  SocketService();

  /// 소켓 서버에 연결
  void connect(String url) {
    socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket?.onConnect((_) {
      print('소켓 연결 성공');
    });

    socket?.onDisconnect((_) {
      print('소켓 연결 종료');
    });
  }

  /// 소켓 서버에서 연결 해제 및 자원 해제
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
  }

  /// 실시간 요청 업데이트 이벤트 수신
  void listenForUpdates(Function(dynamic) onUpdate) {
    socket?.on('request_update', (data) {
      print('[DEBUG] 소켓 데이터 수신: $data');
      onUpdate(data);
    });
  }

  /// 상태 업데이트 이벤트 전송
  void emitStatusUpdate(int reqId, String status) {
    socket?.emit('update_status', {'reqId': reqId, 'status': status});
  }

  /// 요청 참여 이벤트 전송
  void joinRequest(String reqId, String userId) {
    socket?.emit('join', {'reqId': reqId, 'userId': userId});
  }

  /// 요청 나가기 이벤트 전송
  void leaveRequest(String reqId, String userId) {
    socket?.emit('leave', {'reqId': reqId, 'userId': userId});
  }
}