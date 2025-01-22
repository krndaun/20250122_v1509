import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nesysworks/models/request_item.dart';

class ApiService {
  static const String baseUrl = 'http://121.140.204.7:18988';

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
  static Map<String, String> getHeaders() {
    return {'Content-Type': 'application/json'};
  }
  static Future<RequestItem> fetchRequestDetails(int reqId) async {
    try {
      if (reqId <= 0) {
        throw Exception('유효하지 않은 요청 ID입니다: $reqId');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/req_info/$reqId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return RequestItem.fromJson(data);
      } else if (response.statusCode == 404) {
        print('[ApiService] 요청 정보가 없습니다. reqId: $reqId');
        throw Exception('요청 정보를 찾을 수 없습니다.');
      } else {
        throw Exception('Failed to fetch request details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching request details: $e');
      throw Exception('Error: $e');
    }
  }
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw Exception('Failed to parse response: $e');
      }
    } else {
      throw Exception('HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }

  static Future<List<RequestItem>> fetchJoinedRequests(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user_joined_request?user_id=$userId'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          print('[DEBUG] 참여 요청이 없습니다.');
          return [];
        }
        return data.map((item) => RequestItem.fromJson(item)).toList();
      } else {
        print('[ApiService] 참여 요청 API 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ApiService] 참여 요청 가져오기 실패: $e');
      return [];
    }
  }

  static Future<void> createRequest(Map<String, dynamic> requestData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/req_info/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      print('createRequest 응답 상태 코드: ${response.statusCode}');
      print('createRequest 응답 본문: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to create request: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating request: $e');
      throw Exception('요청 생성 실패: $e');
    }
  }
  static Future<void> updateRequestStatus(int reqId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/update_status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'req_id': reqId, 'status': status}),
      );

      print('updateRequestStatus 응답 상태 코드: ${response.statusCode}');
      print('updateRequestStatus 응답 본문: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update request status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating request status: $e');
      throw Exception('요청 상태 업데이트 실패: $e');
    }
  }
  static Future<List<RequestItem>> fetchNearbyRequests(String userId, double maxDistance) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/nearby_requests?user_id=$userId&max_distance=$maxDistance'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => RequestItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch nearby requests: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching nearby requests: $e');
      throw Exception('Error: $e');
    }
  }
  static Future<void> updateLocation(String userId, double latitude, double longitude) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/update_location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        print('[ApiService] 위치 업데이트 성공');
      } else {
        print('[ApiService] 위치 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('[ApiService] 위치 업데이트 오류: $e');
    }
  }

  static Future<List<RequestItem>> fetchRequestList(String userId) async {
    try {
      print('[DEBUG] fetchRequestList 호출 - userId: $userId');
      final response = await http.get(
        Uri.parse('$baseUrl/api/ast_req_info?user_id=$userId'),
      );
      print('[DEBUG] fetchRequestList 응답 상태 코드: ${response.statusCode}');
      print('[DEBUG] fetchRequestList 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data == null || data.isEmpty) {
          print('[DEBUG] 응답 데이터가 비어 있습니다.');
          return [];
        }

        // JSON 배열인지 확인 후 파싱
        if (data is List) {
          return data.map((item) {
            try {
              return RequestItem.fromJson(item);
            } catch (e) {
              print('[DEBUG] RequestItem 파싱 오류: $e');
              return RequestItem.empty(); // 오류 발생 시 빈 객체 반환
            }
          }).toList();
        } else {
          print('[DEBUG] 데이터가 배열 형식이 아닙니다.');
          return [];
        }
      } else {
        throw Exception('Failed to load request list: ${response.statusCode}');
      }
    } catch (e) {
      print('[DEBUG] fetchRequestList 오류: $e');
      throw Exception('Error: $e');
    }
  }
  // 참여자 데이터를 가져오는 메서드
  static Future<List<Map<String, dynamic>>> fetchParticipants(int requestId) async {
    final url = Uri.parse('$baseUrl/api/participant_distances?req_id=$requestId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // 서버에서 받아온 데이터 디코딩
      final List<dynamic> data = jsonDecode(response.body);

      // 데이터를 맵 형식으로 변환
      return data.map<Map<String, dynamic>>((participant) {
        return {
          'user_id': participant['user_id'],
          'name': participant['name'],
          'distance': participant['distance'],
          'status': participant['participant_status'], // 상황 정보
          'event_location': participant['request_location'], // 요청 위치 주소
        };
      }).toList();
    } else {
      throw Exception('참여자 데이터를 불러오는 데 실패했습니다. 상태 코드: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> joinRequest(int reqId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'req_id': reqId, 'user_id': userId}),
      );

      print('joinRequest 응답 상태 코드: ${response.statusCode}');
      print('joinRequest 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        // 응답 데이터를 JSON으로 디코딩하여 반환
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('서버에서 참여 요청 처리 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('joinRequest 오류: $e');
      throw Exception('참여 요청 실패: $e');
    }
  }

  static Future<void> updateTaskStatus(
      int reqId, String userId, String status) async {
    await http.post(
      Uri.parse('$baseUrl/api/update_status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'req_id': reqId, 'user_id': userId, 'status': status}),
    );
  }
}