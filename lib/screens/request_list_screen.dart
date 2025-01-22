import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nesysworks/models/request_item.dart';
import 'package:nesysworks/services/api_service.dart';
import 'package:nesysworks/widgets/request_list_tile.dart';

class RequestListScreen extends StatefulWidget {
  final String userId;
  final double userLatitude;
  final double userLongitude;
  final double maxDistance;

  RequestListScreen({
    required this.userId,
    required this.userLatitude,
    required this.userLongitude,
    required this.maxDistance,
  });

  @override
  _RequestListScreenState createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  List<RequestItem> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final requests = await ApiService.fetchRequestList(widget.userId);
      setState(() {
        _requests = requests.where((item) {
          // 거리 필터링
          final distance = calculateDistance(
            widget.userLatitude,
            widget.userLongitude,
            double.tryParse(item.latitude) ?? 0.0,
            double.tryParse(item.longitude) ?? 0.0,
          );
          return distance <= widget.maxDistance;
        }).toList();
      });
    } catch (e) {
      print("요청 데이터 로드 오류: $e");
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // 지구 반지름 (km)
    final dLat = _degreeToRadian(lat2 - lat1);
    final dLon = _degreeToRadian(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(lat1)) * cos(_degreeToRadian(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreeToRadian(double degree) => degree * pi / 180;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('요청 목록')),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: ListView.builder(
          itemCount: _requests.length,
          itemBuilder: (context, index) {
            final item = _requests[index];
            return RequestListTile(
              item: item,
              userLatitude: widget.userLatitude,
              userLongitude: widget.userLongitude,
              maxDistance: widget.maxDistance,
              onJoin: () async {
                await ApiService.joinRequest(item.id, widget.userId);
                _fetchRequests();
              },
            );
          },
        ),
      ),
    );
  }
}