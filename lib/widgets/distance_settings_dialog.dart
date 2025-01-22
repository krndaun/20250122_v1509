import 'package:flutter/material.dart';

class DistanceSettingsDialog extends StatefulWidget {
  final double currentDistance;
  final Function(double) onDistanceChanged;

  const DistanceSettingsDialog({
    required this.currentDistance,
    required this.onDistanceChanged,
    Key? key,
  }) : super(key: key);

  @override
  _DistanceSettingsDialogState createState() => _DistanceSettingsDialogState();
}

class _DistanceSettingsDialogState extends State<DistanceSettingsDialog> {
  late double updatedDistance;

  @override
  void initState() {
    super.initState();
    updatedDistance = widget.currentDistance; // 초기값 설정
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('거리 설정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('현재 설정된 거리: ${updatedDistance.toStringAsFixed(1)} km'),
          Slider(
            value: updatedDistance,
            min: 1.0,
            max: 99999.0,
            divisions: 99,
            label: '${updatedDistance.toStringAsFixed(1)} km',
            onChanged: (value) {
              setState(() {
                updatedDistance = value; // 슬라이더 값 업데이트
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onDistanceChanged(updatedDistance); // 부모 위젯에 값 전달
            Navigator.pop(context);
          },
          child: Text('확인'),
        ),
      ],
    );
  }
}