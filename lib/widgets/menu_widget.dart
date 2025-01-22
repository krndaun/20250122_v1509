import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppMenu extends StatefulWidget {
  final Future<void> Function() onRefreshLocation; // 콜백 추가

  AppMenu({required this.onRefreshLocation});

  @override
  _AppMenuState createState() => _AppMenuState();
}

class _AppMenuState extends State<AppMenu> {
  String? username;
  String? email;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 사용자 데이터 로드
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Unknown User';
      email = prefs.getString('email') ?? 'Unknown Email';
      userId = prefs.getString('id') ?? 'Unknown ID';
    });

    // 디버깅: 로드된 데이터 출력
    print('Loaded User Data: username=$username, email=$email, userId=$userId');
  }

  /// 사용자 데이터 삭제 (로그아웃)
  Future<void> _clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 디버깅: 로그아웃 확인 메시지
    print('User data cleared. Logging out...');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '이름: ${username ?? 'Unknown User'}',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  '이메일: ${email ?? 'Unknown Email'}',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  'ID: ${userId ?? 'Unknown ID'}',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('위치 새로고침'),
            onTap: () async {
              await widget.onRefreshLocation(); // widget으로 접근
              Navigator.pop(context); // Drawer 닫기
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () async {
              await _clearUserData(); // 사용자 데이터 삭제

              // 로그인 페이지로 이동
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);

              // 디버깅: 로그아웃 후 확인 메시지
              print('Navigated to login screen after logout.');
            },
          ),
        ],
      ),
    );
  }
}