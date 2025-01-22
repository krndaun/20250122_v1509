import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketScreen extends StatefulWidget {
  @override
  _WebSocketScreenState createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends State<WebSocketScreen> {
  late WebSocketChannel channel;
  List<dynamic> realTimeData = [];

  @override
  void initState() {
    super.initState();
    // WebSocket 서버에 연결
    channel = IOWebSocketChannel.connect('ws://121.140.204.7:18988');

    // 서버로부터 메시지 수신
    channel.stream.listen((message) {
      final data = jsonDecode(message);
      setState(() {
        realTimeData = data; // 실시간 데이터 업데이트
      });
    }, onError: (error) {
      print('WebSocket 오류: $error');
    }, onDone: () {
      print('WebSocket 연결 종료');
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('실시간 데이터'),
      ),
      body: ListView.builder(
        itemCount: realTimeData.length,
        itemBuilder: (context, index) {
          final item = realTimeData[index];
          return ListTile(
            title: Text('ID: ${item['id']}'),
            subtitle: Text('참여 인원: ${item['joined_workers']} / ${item['workers']}'),
            trailing: ElevatedButton(
              onPressed: item['joined_workers'] >= item['workers']
                  ? null
                  : () => joinRequest(item['id']),
              child: Text('참여'),
            ),
          );
        },
      ),
    );
  }

  Future<void> joinRequest(int id) async {
    try {
      // 서버에 참여 요청 API 호출
      final response = await http.post(
        Uri.parse('http://121.140.204.7:18988/api/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('참여 성공!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('참여 실패: ${result['error']}')),
          );
        }
      } else {
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('참여 요청 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('참여 요청 중 오류 발생')),
      );
    }
  }
}
