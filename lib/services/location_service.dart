import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static const String baseUrl = 'http://121.140.204.7:18988';
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  /// **현재 위치 가져오기**
  Future<Position> getCurrentPosition() async {
    try {
      // 위치 권한 확인
      await _ensureLocationPermission();
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('현재 위치를 가져올 수 없습니다: $e');
    }
  }

  /// **위치 권한 확인 및 요청**
  Future<void> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되었습니다. 설정에서 활성화해주세요.');
    }
  }

  /// **위도와 경도로 주소 변환**
  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.country ?? ''}'.trim();
      }
    } catch (e) {
      print('주소 변환 오류: $e');
    }
    return '주소를 찾을 수 없음';
  }

  /// **거리 계산 (단위: km)**
  double calculateDistance(
      double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude) /
        1000; // 결과를 km 단위로 반환
  }

  /// **서버에 위치 업데이트**
  Future<Map<String, dynamic>> updateLocationOnServer(
      String userId, Position position) async {
    try {
      // 데이터 검증
      if (userId.isEmpty || position.latitude == 0 || position.longitude == 0) {
        throw Exception('필수 데이터 누락: userId=$userId, latitude=${position.latitude}, longitude=${position.longitude}');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/update_location'),
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        }),
      );

      if (response.statusCode == 200) {
        // 성공 응답 파싱
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('위치 업데이트 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('위치 업데이트 실패: $e');
      rethrow;
    }
  }
}