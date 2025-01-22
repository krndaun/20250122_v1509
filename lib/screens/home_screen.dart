import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nesysworks/services/api_service.dart';
import 'package:nesysworks/services/location_service.dart';
import 'package:nesysworks/models/request_item.dart';
import 'package:nesysworks/widgets/distance_settings_dialog.dart';
import 'package:nesysworks/widgets/request_list.dart';
import 'package:nesysworks/widgets/joined_request_card.dart';
import 'package:nesysworks/widgets/menu_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../services/socket_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  IO.Socket? socket;
  List<RequestItem> _requestList = [];
  RequestItem? _joinedRequest;
  String _userAddress = '위치를 가져오는 중...';
  double maxDistance = 99999.0;
  String? username;
  String? email;
  String? id;
  List<Map<String, dynamic>> participants = [];
  Position? _currentPosition;
  int? _highlightedRequestId; // 추가

  @override
  void initState() {
    super.initState();
    _initializeUserDataAndApp();
    _initializeRequest();
    _setupSocketListeners();
    _checkUserParticipation();

  }
  final SocketService _socketService = SocketService();

  void _updateRequestList(dynamic updatedData) {
    final updatedRequest = RequestItem.fromJson(updatedData);
    final existingIndex = _requestList.indexWhere((item) => item.id == updatedRequest.id);

    if (existingIndex != -1) {
      // 기존 요청 업데이트
      _requestList[existingIndex] = updatedRequest;
    } else {
      // 새로운 요청 추가
      _requestList.add(updatedRequest);
    }
  }
  void _setupSocketListeners() {
    _socketService.listenForUpdates((updatedRequest) {
      setState(() {
        _updateRequestList(updatedRequest); // 요청 리스트 업데이트
      });
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 소켓 이벤트 리스너 추가
    _socketService.listenForUpdates((updatedData) {
      final updatedRequest = RequestItem.fromJson(updatedData);
      _updateRequestList(updatedRequest); // 메서드 이름 수정
    });
  }
  void highlightRequest(int requestId) {
    setState(() {
      _highlightedRequestId = requestId;
    });

    Future.delayed(Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _highlightedRequestId = null;
      });
    });
  }
  Future<void> _checkUserParticipation() async {
    if (id == null) {
      print('[DEBUG] 사용자 ID가 설정되지 않았습니다.');
      return;
    }

    final response = await ApiService.fetchJoinedRequests(id!);
    if (response.isNotEmpty) {
      setState(() {
        _joinedRequest = RequestItem.fromJson(response.first as Map<String, dynamic>);
      });
    }
  }
  Future<void> _initializeRequest() async {
    if (_joinedRequest == null || _joinedRequest!.id <= 0) {
      print('[DEBUG] 유효한 요청이 없습니다.');
      setState(() {
        _joinedRequest = RequestItem.empty();
      });
      return;
    }

    try {
      final requestDetails = await ApiService.fetchRequestDetails(_joinedRequest!.id);
      setState(() {
        _joinedRequest = requestDetails;
      });
    } catch (e) {
      print('[ERROR] 요청 세부정보를 가져오지 못했습니다: $e');
    }
  }
  /// 상태 업데이트 및 브로드캐스트
  Future<void> _onStatusUpdate(String status) async {
    if (_joinedRequest == null) return;

    try {
      await ApiService.updateTaskStatus(_joinedRequest!.id, id!, status);
      _socketService.emitStatusUpdate(_joinedRequest!.id, status); // 서버에 상태 업데이트 전송
    } catch (e) {
      print('[HomeScreen] 상태 업데이트 오류: $e');
      _showErrorDialog('상태 업데이트 중 오류가 발생했습니다.');
    }
  }

  /// 사용자 데이터 및 앱 초기화
  Future<void> _initializeUserDataAndApp() async {
    await _loadUserData();
    if (id != null) {
      await _updateLocation();
      await _fetchInitialRequests();
    } else {
      print('사용자 ID가 없습니다. 초기화를 건너뜁니다.');
    }
  }
  /// 위치 업데이트 메서드
  Future<void> _updateLocation() async {
    try {
      // 현재 위치 가져오기
      final position = await LocationService().getCurrentPosition();

      // 위도/경도로 주소 변환
      final address = await LocationService().getAddressFromCoordinates(
          position.latitude, position.longitude);

      // 서버로 위치 업데이트
      final response = await LocationService().updateLocationOnServer(id!, position);

      if (response['success']) {
        print('위치 업데이트 성공: $response');
        setState(() {
          _currentPosition = position; // 위치 정보 저장
          _userAddress = address; // 주소 UI에 표시
        });
      }
    } catch (e) {
      print('위치 업데이트 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 업데이트 실패: $e')),
      );
    }
  }
  /// 사용자 데이터 로드
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
      email = prefs.getString('email');
      id = prefs.getString('id');
    });
    print('불러온 사용자 정보: username=$username, email=$email, id=$id');
  }

  /// 초기 요청 데이터 가져오기
  Future<bool> _fetchInitialRequests() async {
    try {
      final joinedRequests = await ApiService.fetchJoinedRequests(id!);

      if (joinedRequests.isNotEmpty) {
        setState(() {
          _joinedRequest = joinedRequests.first;
          participants = _joinedRequest?.joinedUsernames ?? [];
          print('[DEBUG] 참여 요청 데이터: ${_joinedRequest?.toJson()}');
          print('[DEBUG] 참여자 상태: $participants');
        });
        return true;
      } else {
        print('[DEBUG] 참여 요청이 없습니다.');
        setState(() {
          _joinedRequest = null; // 참여 중인 요청이 없으므로 null로 설정
        });
        await _fetchRequestList();
        return false;
      }
    } catch (e) {
      print('[DEBUG] _fetchInitialRequests 오류: $e');
      setState(() {
        _joinedRequest = null; // 오류 발생 시에도 null로 설정
      });
      return false;
    }
  }
  /// 요청 리스트 가져오기
  Future<void> _fetchRequestList() async {
    try {
      print('[DEBUG] _fetchRequestList 호출');
      final requests = await ApiService.fetchRequestList(id!);
      print('[DEBUG] 서버에서 받은 요청 데이터: ${requests.map((e) => e.toJson()).toList()}');
      setState(() {
        _requestList = requests.map((item) {
          final calculatedDistance = item.calculateDistance(
            _currentPosition?.latitude ?? 0.0,
            _currentPosition?.longitude ?? 0.0,
          );
          return item.copyWith(distance: calculatedDistance); // distance 업데이트
        }).toList();
      });
      print('[DEBUG] 요청 리스트 업데이트 완료: ${_requestList.map((e) => e.toJson()).toList()}');
    } catch (e) {
      print('[DEBUG] 요청 리스트 가져오기 오류: $e');
      _showErrorDialog('요청 리스트를 가져오는 중 문제가 발생했습니다.');
    }
  }

  /// 참여 요청 처리
  Future<void> _onJoinRequest(int reqId) async {
    try {
      final response = await ApiService.joinRequest(reqId, id!);
      if (response['success']) {
        await _fetchInitialRequests(); // 상태 갱신
      } else {
        _showErrorDialog(response['message']);
      }
    } catch (e) {
      print('[DEBUG] 참여 요청 처리 오류: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NESYSWORKS'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showDistanceSettingsDialog,
          ),
        ],
      ),
      drawer: AppMenu(
        onRefreshLocation: _updateLocation, // 콜백 전달
      ),
      body: Column(
        children: [
          // 위치 정보 표시
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '현재 위치: $_userAddress',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Divider(), // 구분선 추가
          Expanded(
            // 요청 리스트 또는 참여 페이지 표시
            child: _joinedRequest != null && _joinedRequest!.id > 0
                ? _buildJoinedRequestView()
                : RequestList(
              requestList: _requestList, // 요청 리스트 전달
              onJoin: _onJoinRequest, // 참여 함수 전달
              onRefresh: _fetchRequestList, // 새로고침 함수 전달
              maxDistance: maxDistance, // 최대 거리 전달
              userLatitude: _currentPosition?.latitude ?? 0.0, // 사용자 위도 전달
              userLongitude: _currentPosition?.longitude ?? 0.0, // 사용자 경도 전달
            ),
          ),
        ],
      ),
    );
  }
  /// 참여 페이지 UI
  Widget _buildJoinedRequestView() {
    if (_joinedRequest == null || _joinedRequest!.id <= 0) {
      // 참여 중인 요청이 없을 경우 전체 요청 리스트로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchRequestList();
      });
      return Center(
        child: Text(
          '참여 중인 요청이 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return JoinedRequestCard(
      joinedRequest: _joinedRequest!,
      participants: participants,
      maxDistance: maxDistance,
      onStatusUpdate: (String status) async {
        try {
          await ApiService.updateTaskStatus(_joinedRequest!.id, id!, status);

          if (status == 'completed') {
            setState(() {
              _joinedRequest = null;
              participants = [];
            });
            await _fetchRequestList(); // Refresh request list
          } else {
            await _fetchInitialRequests();
          }
        } catch (e) {
          print('[DEBUG] 상태 업데이트 오류: $e');
        }
      },
      onRefresh: _fetchInitialRequests,
    );
  }

  /// 요청 리스트 UI
  Widget _buildRequestListView() {
    return RequestList(
      requestList: _requestList,
      onJoin: _onJoinRequest,
      onRefresh: _fetchRequestList,
      userLatitude: _currentPosition?.latitude ?? 0.0,
      userLongitude: _currentPosition?.longitude ?? 0.0,
    );
  }

  void _showDistanceSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => DistanceSettingsDialog(
        currentDistance: maxDistance,
        onDistanceChanged: (newDistance) {
          setState(() {
            maxDistance = newDistance;
          });
        },
      ),
    );
  }

}