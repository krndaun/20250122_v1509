import 'package:flutter/material.dart';
import 'package:nesysworks/models/request_item.dart';

class RequestList extends StatefulWidget {
  final List<RequestItem> requestList;
  final Function(int) onJoin;
  final Future<void> Function() onRefresh;
  final double? maxDistance;
  final double userLatitude;
  final double userLongitude;

  RequestList({
    required this.requestList,
    required this.onJoin,
    required this.onRefresh,
    this.maxDistance,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  _RequestListState createState() => _RequestListState();
}

class _RequestListState extends State<RequestList> {
  int? _highlightedRequestId;

  void highlightRequest(int requestId) {
    setState(() {
      _highlightedRequestId = requestId;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _highlightedRequestId = null;
      });
    });
  }

  /// 소켓 통신으로 요청 리스트 업데이트
  void updateRequestList(List<RequestItem> updatedList) {
    setState(() {
      for (var updatedItem in updatedList) {
        final index = widget.requestList.indexWhere((item) => item.id == updatedItem.id);
        if (index != -1) {
          widget.requestList[index] = updatedItem; // 기존 아이템 업데이트
        } else {
          widget.requestList.add(updatedItem); // 새 요청 추가
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requestList.isEmpty) {
      return Center(
        child: Text('요청 리스트가 없습니다.'),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        itemCount: widget.requestList.length,
        itemBuilder: (context, index) {
          final item = widget.requestList[index];

          // 거리 제한이 설정되어 있고 초과한 경우 숨기기
          if (widget.maxDistance != null && item.distance > widget.maxDistance!) {
            return SizedBox.shrink();
          }

          final isHighlighted = item.id == _highlightedRequestId;
          final isFullyJoined = item.joinedWorkers >= item.workers;

          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            color: isHighlighted ? Colors.yellow.withOpacity(0.5) : Colors.white,
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('차량번호: ${item.vehicleNumber}'),
                      Text('위치: ${item.location}'),
                      Text('상황: ${item.situation}'),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.distance.toStringAsFixed(2)} km'),
                      ElevatedButton(
                        onPressed: isFullyJoined
                            ? null
                            : () {
                          widget.onJoin(item.id); // 참여 처리
                          highlightRequest(item.id); // 하이라이트

                        },
                        child: Text(
                          isFullyJoined ? '마감됨' : '${item.joinedWorkers}/${item.workers} 참여',
                        ),
                        style: isFullyJoined
                            ? ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}