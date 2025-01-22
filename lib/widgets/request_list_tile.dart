import 'package:flutter/material.dart';
import '../models/request_item.dart';
import '../utils/calculate_utils.dart';

class RequestListTile extends StatelessWidget {
  final RequestItem item;
  final double userLatitude;
  final double userLongitude;
  final double maxDistance;
  final void Function()? onJoin; // nullable 함수로 수정
  final void Function()? onCancel; // nullable 함수로 수정

  const RequestListTile({
    required this.item,
    required this.userLatitude,
    required this.userLongitude,
    required this.maxDistance,
    this.onJoin, // nullable 허용
    this.onCancel, // nullable 허용
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.vehicleNumber),
      subtitle: Text(item.situation),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onJoin != null)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: onJoin,
            ),
          if (onCancel != null)
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }
}