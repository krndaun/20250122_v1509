import 'package:flutter/material.dart';
import 'package:nesysworks/models/request_item.dart';

import '../services/api_service.dart';

class JoinedRequestCard extends StatefulWidget {
  final RequestItem joinedRequest;
  final Future<bool> Function() onRefresh;
  final Function(String) onStatusUpdate;
  final List<Map<String, dynamic>> participants;
  final double maxDistance;

  JoinedRequestCard({
    required this.joinedRequest,
    required this.onStatusUpdate,
    required this.participants,
    required this.onRefresh,
    required this.maxDistance,
  });

  @override
  _JoinedRequestCardState createState() => _JoinedRequestCardState();
}

class _JoinedRequestCardState extends State<JoinedRequestCard> {
  bool hasStarted = false;

  /// 모든 참여자가 참여했는지 확인하는 함수
  bool areAllParticipantsJoined() {
    return widget.joinedRequest.joinedWorkers == widget.joinedRequest.workers;
  }

  /// 모든 참여자가 500m 이내에 있는지 확인하는 함수
  bool areAllParticipantsWithinRange() {
    return widget.participants.every((participant) {
      final distance = participant['distance'] ?? double.infinity;
      return (distance * 1000).round() <= 500; // 거리(m) 비교
    });
  }

  /// 시작 버튼 활성화 조건 통합
  bool isStartButtonEnabled() {
    return areAllParticipantsJoined() && areAllParticipantsWithinRange();
  }

  /// 상태 업데이트 함수
  Future<void> _updateStatus(String status) async {
    try {
      await widget.onStatusUpdate(status);

      final updatedData = await ApiService.fetchRequestDetails(widget.joinedRequest.id);

      setState(() {
        widget.participants.forEach((participant) {
          final updatedParticipant = updatedData.joinedUsernames.firstWhere(
                (p) => p['user_id'] == participant['user_id'],
            orElse: () => <String, dynamic>{},
          );
          if (updatedParticipant.isNotEmpty) {
            participant['status'] = updatedParticipant['status'];
          }
        });

        hasStarted = status == 'inProgress';
      });

      print('[DEBUG] 상태 업데이트 성공: $status');
    } catch (e) {
      print('[ERROR] 상태 업데이트 실패: $e');
      _showErrorDialog('상태 업데이트 중 오류가 발생했습니다.');
    }
  }

  /// 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 새로고침 후 참여 여부 확인 및 처리
  Future<void> _handleRefresh() async {
    final bool isStillJoined = await widget.onRefresh();
    if (!isStillJoined && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool startButtonEnabled = isStartButtonEnabled();
    List<String> reasons = [];

    // 참여자 인원 부족 확인
    if (!areAllParticipantsJoined()) {
      final requiredWorkers = widget.joinedRequest.workers;
      final currentWorkers = widget.joinedRequest.joinedWorkers;
      reasons.add('참여자 인원 부족: ${requiredWorkers - currentWorkers}명');
    }

    // 거리 초과 참여자 확인
    widget.participants.forEach((participant) {
      final name = participant['name'] ?? '알 수 없음';
      final distanceKm = participant['distance'] ?? double.infinity;
      final distanceM = (distanceKm * 1000).round();

      if (distanceM > 500) {
        final difference = ((distanceM - 500) / 100).ceil() * 100; // 100m 단위 반올림
        reasons.add('참여자 $name 위치 초과: 약 ${difference}m 부족');
      }
    });

    final disabledReason = reasons.isNotEmpty ? reasons.join('\n') : '';

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '차량 번호: ${widget.joinedRequest.vehicleNumber}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '요청 내용: ${widget.joinedRequest.situation}',
              style: TextStyle(fontSize: 14),
            ),
            Divider(),
            Text(
              '요청 위치: ${widget.joinedRequest.location}',
              style: TextStyle(fontSize: 14),
            ),
            Divider(),
            widget.participants.isEmpty
                ? Text('참여자 정보 없음')
                : Column(
              children: widget.participants.map((participant) {
                final name = participant['name'] ?? '알 수 없음';
                final distanceKm = participant['distance'] ?? double.infinity;
                final distanceM = (distanceKm * 1000).round();
                final roundedDistance = (distanceM / 100).ceil() * 100;

                String distanceDisplay;
                if (roundedDistance <= 500) {
                  distanceDisplay = '준비됨';
                } else if (roundedDistance < 1000) {
                  distanceDisplay = '약 ${roundedDistance}m';
                } else {
                  final distanceKmDisplay =
                  (roundedDistance / 1000).toStringAsFixed(1);
                  distanceDisplay = '약 ${distanceKmDisplay}km';
                }

                return ListTile(
                  title: Text('이름: $name'),
                  trailing: roundedDistance <= 500
                      ? Text(
                    '준비됨',
                    style: TextStyle(color: Colors.green),
                  )
                      : Text(
                    distanceDisplay,
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }).toList(),
            ),
            Divider(),
            Text(
              '참여 인원: ${widget.joinedRequest.joinedWorkers}/${widget.joinedRequest.workers}',
              style: TextStyle(fontSize: 14),
            ),
            Divider(),
            hasStarted
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _updateStatus('paused'),
                  child: Text('중단'),
                ),
                ElevatedButton(
                  onPressed: () => _updateStatus('completed'),
                  child: Text('완료'),
                ),
                ElevatedButton(
                  onPressed: () => _updateStatus('requestHelp'),
                  child: Text('지원 요청'),
                ),
              ],
            )
                : Column(
              children: [
                ElevatedButton(
                  onPressed: startButtonEnabled
                      ? () {
                    _updateStatus('inProgress');
                  }
                      : null,
                  child: Text('시작'),
                ),
                if (!startButtonEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '불가 사유:\n$disabledReason',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: _handleRefresh,
                  icon: Icon(Icons.refresh),
                  label: Text('새로고침'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}