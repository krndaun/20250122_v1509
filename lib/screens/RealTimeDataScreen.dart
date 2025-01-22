import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RealTimeDataScreen extends StatefulWidget {
  @override
  _RealTimeDataScreenState createState() => _RealTimeDataScreenState();
}

class _RealTimeDataScreenState extends State<RealTimeDataScreen> {
  final WebSocketChannel channel = IOWebSocketChannel.connect('ws://121.140.204.7:18988');
  List<dynamic> realTimeData = [];

  @override
  void initState() {
    super.initState();
    channel.stream.listen((message) {
      setState(() {
        realTimeData = [...realTimeData, message];
      });
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
      appBar: AppBar(title: Text('실시간 데이터')),
      body: ListView.builder(
        itemCount: realTimeData.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(realTimeData[index]));
        },
      ),
    );
  }
}
