import 'package:nesysworks/models/request_item.dart';
import 'package:nesysworks/services/api_service.dart';
import 'package:nesysworks/utils/location_utils.dart';
import 'package:geolocator/geolocator.dart';

class HomeService {
  Future<List<RequestItem>> fetchFilteredData(
      List<RequestItem> data, Position? userPosition, double maxDistance) async {
    return data.where((item) {
      final distance = LocationUtils.calculateDistance(
        userPosition?.latitude ?? 0.0,
        userPosition?.longitude ?? 0.0,
        double.tryParse(item.latitude) ?? 0.0,
        double.tryParse(item.longitude) ?? 0.0,
      );
      return distance <= maxDistance;
    }).toList();
  }
}