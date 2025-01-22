import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class RequestItem {
  double calculateDistance(double userLat, double userLng) {
    if (latitude.isEmpty || longitude.isEmpty) {
      return 0.0;
    }

    return Geolocator.distanceBetween(
      userLat,
      userLng,
      double.parse(latitude),
      double.parse(longitude),
    ) / 1000; // 미터를 km로 변환
  }

  factory RequestItem.empty() {
    return RequestItem(
      id: -1,
      vehicleNumber: '',
      situation: '',
      textInfo1: '',
      textInfo2: '',
      textInfo3: '',
      location: '',
      request_location: '',
      latitude: '0.0',
      longitude: '0.0',
      workers: 0,
      totalWorkers: 0,
      joinedWorkers: 0,
      duration: 0,
      startTime: '',
      progressStatus: '',
      createdAt: '',
      updatedAt: '',
      isUserJoined: false,
      taskStatus: 'notStarted',
      isClosed: false,
      joinedUsernames: [],
      participantDetails: [],
      distance: 0.0,
      isCompleted: false,
    );
  }

  final int id;
  final String vehicleNumber;
  final String situation;
  final String textInfo1;
  final String textInfo2;
  final String textInfo3;
  final String location;
  final String latitude;
  final String longitude;
  final int workers;
  final int joinedWorkers;
  final int totalWorkers;
  final int duration;
  final String startTime;
  final String progressStatus;
  final String createdAt;
  final String updatedAt;
  final bool isUserJoined;
  final String taskStatus;
  final bool isClosed;
  final List<Map<String, dynamic>> joinedUsernames;
  final double distance;
  final bool isCompleted;
  final String request_location;
  final List<Map<String, dynamic>> participantDetails;

  RequestItem({
    required this.id,
    required this.vehicleNumber,
    required this.situation,
    required this.textInfo1,
    required this.textInfo2,
    required this.textInfo3,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.workers,
    required this.joinedWorkers,
    required this.totalWorkers,
    required this.duration,
    required this.startTime,
    required this.progressStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.isUserJoined,
    required this.taskStatus,
    required this.isClosed,
    required this.joinedUsernames,
    this.distance = 0.0,
    required this.isCompleted,
    required this.request_location,
    required this.participantDetails,
  });

  /// `copyWith` 메서드 추가
  RequestItem copyWith({
    int? id,
    String? vehicleNumber,
    String? situation,
    String? textInfo1,
    String? textInfo2,
    String? textInfo3,
    String? location,
    String? latitude,
    String? longitude,
    int? workers,
    int? joinedWorkers,
    int? totalWorkers,
    int? duration,
    String? startTime,
    String? progressStatus,
    String? createdAt,
    String? updatedAt,
    bool? isUserJoined,
    String? taskStatus,
    bool? isClosed,
    List<Map<String, dynamic>>? joinedUsernames,
    double? distance,
    bool? isCompleted,
    String? request_location,
    List<Map<String, dynamic>>? participantDetails,
  }) {
    return RequestItem(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      situation: situation ?? this.situation,
      textInfo1: textInfo1 ?? this.textInfo1,
      textInfo2: textInfo2 ?? this.textInfo2,
      textInfo3: textInfo3 ?? this.textInfo3,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      workers: workers ?? this.workers,
      joinedWorkers: joinedWorkers ?? this.joinedWorkers,
      totalWorkers: totalWorkers ?? this.totalWorkers,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      progressStatus: progressStatus ?? this.progressStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isUserJoined: isUserJoined ?? this.isUserJoined,
      taskStatus: taskStatus ?? this.taskStatus,
      isClosed: isClosed ?? this.isClosed,
      joinedUsernames: joinedUsernames ?? this.joinedUsernames,
      distance: distance ?? this.distance,
      isCompleted: isCompleted ?? this.isCompleted,
      request_location: request_location ?? this.request_location,
      participantDetails: participantDetails ?? this.participantDetails,
    );
  }

  // JSON 처리 메서드와 기타 메서드는 기존대로 유지
  factory RequestItem.fromJson(Map<String, dynamic> json) {
    return RequestItem(
      id: json['id'] ?? json['request_id'] ?? -1,
      vehicleNumber: json['vehicle_number'] ?? 'Unknown',
      situation: json['situation'] ?? 'Unknown',
      textInfo1: json['text_info1'] ?? '',
      textInfo2: json['text_info2'] ?? '',
      textInfo3: json['text_info3'] ?? '',
      location: json['location'] ?? 'Unknown',
      request_location: json['request_location'] ?? 'Unknown',
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      totalWorkers: json['total_workers'] ?? 0,
      workers: json['workers'] ?? 0,
      joinedWorkers: json['joined_workers'] ?? 0,
      duration: json['duration'] ?? 0,
      startTime: json['start_time'] ?? '',
      progressStatus: json['progress_status'] ?? 'Unknown',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      isUserJoined: json['is_user_joined'] == true || json['is_user_joined'] == 1,
      taskStatus: json['task_status'] ?? 'notStarted',
      isClosed: json['is_closed'] == true || json['is_closed'] == 1,
      joinedUsernames: _parseJoinedUsernames(json['joined_usernames']),
      distance: (json['distance'] != null) ? double.tryParse(json['distance'].toString()) ?? 0.0 : 0.0,
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
      participantDetails: _parseParticipantDetails(json['joined_usernames']),
    );
  }

  static List<Map<String, dynamic>> _parseJoinedUsernames(dynamic data) {
    if (data == null || data == 'null') return [];
    try {
      if (data is String && data.isNotEmpty) {
        final parsed = jsonDecode(data);
        if (parsed is List) {
          return List<Map<String, dynamic>>.from(parsed);
        }
      } else if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      print('Error parsing joined_usernames: $e');
    }
    return [];
  }

  static List<Map<String, dynamic>> _parseParticipantDetails(dynamic data) {
    return _parseJoinedUsernames(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_number': vehicleNumber,
      'situation': situation,
      'text_info1': textInfo1,
      'text_info2': textInfo2,
      'text_info3': textInfo3,
      'location': location,
      'request_location': request_location,
      'latitude': latitude,
      'longitude': longitude,
      'workers': workers,
      'joined_workers': joinedWorkers,
      'total_workers': totalWorkers,
      'duration': duration,
      'start_time': startTime,
      'progress_status': progressStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_user_joined': isUserJoined,
      'task_status': taskStatus,
      'is_closed': isClosed,
      'joined_usernames': joinedUsernames,
      'distance': distance,
      'is_completed': isCompleted,
      'participantDetails': participantDetails,
    };
  }
}