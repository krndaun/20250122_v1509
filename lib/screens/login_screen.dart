import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'ResetPassword_Screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
  TextEditingController(text: "jd@pline.co.kr"); // 기본 이메일
  final TextEditingController _passwordController =
  TextEditingController(text: "123"); // 기본 비밀번호

  String? username;
  String? email;
  String? id;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
      email = prefs.getString('email');
      id = prefs.getString('id');
    });

    // 사용자 데이터가 있으면 홈 화면으로 이동
    if (email != null && username != null && id != null) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _saveUserData(String username, String email, String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('id', id);
  }

  void _clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void _login() async {
    final emailInput = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (emailInput.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://works.plinemotors.kr/apilogin'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': emailInput,
          'password': password,
        },
      );

      print('API 응답: ${response.body}'); // API 응답 확인용 로그

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['status'] == true) {
          if (data['reset'] == true) {
            // 초기 비밀번호 사용 시 비밀번호 변경 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordScreen(email: emailInput),
              ),
            );
          } else {
            // 정상 로그인
            final username = data['username'] ?? 'username';
            final id = data['id'] ?? 'id';
            final email = emailInput;

            _saveUserData(username, email, id);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('환영합니다, $username님!')),
            );

            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그인 실패: ${data['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 오류: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: '이메일'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
