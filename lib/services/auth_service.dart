import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// 사용자 데이터 저장
  static Future<void> saveUserData(String username, String email, String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('id', id);
  }

  /// 사용자 데이터 불러오기
  static Future<Map<String, String?>> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username'),
      'email': prefs.getString('email'),
      'id': prefs.getString('id'),
    };
  }

  /// 사용자 데이터 초기화 (로그아웃 시)
  static Future<void> clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}