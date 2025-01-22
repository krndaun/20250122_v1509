import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddressWidget extends StatefulWidget {
  final void Function(String) onAddressUpdated; // 주소 업데이트 콜백

  const AddressWidget({required this.onAddressUpdated});

  @override
  _AddressWidgetState createState() => _AddressWidgetState();
}

class _AddressWidgetState extends State<AddressWidget> {
  String _address = '위치 정보를 가져오는 중...';

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      // 위치 권한 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('위치 서비스가 비활성화되어 있습니다.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('위치 권한이 거부되었습니다.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('위치 권한이 영구적으로 거부되었습니다.');
      }

      // 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      String address = await _getAddressFromCoordinates(position.latitude, position.longitude);

      setState(() {
        _address = address;
      });

      // 콜백으로 업데이트된 주소 전달
      widget.onAddressUpdated(address);
    } catch (e) {
      print('위치 가져오기 오류: $e');
      setState(() {
        _address = '위치 정보를 가져올 수 없습니다.';
      });
    }
  }

  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.locality ?? ''} ${place.subLocality ?? ''} ${place.street ?? ''}';
      } else {
        return '주소를 찾을 수 없습니다.';
      }
    } catch (e) {
      print('주소 변환 오류: $e');
      return '주소 변환 실패';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: Text(
        '현재 위치: $_address',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}