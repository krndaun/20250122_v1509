import 'dart:convert'; // jsonEncode를 위한 import
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _initializeFirebaseMessaging();
    _navigateToNextScreen();
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 초기화 설정 (onDidReceiveLocalNotification 제외)
    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // 알림 클릭 처리
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification Clicked: ${response.payload}');
      },
    );
  }

  /// Firebase Messaging 초기화
  Future<void> _initializeFirebaseMessaging() async {
    if (Platform.isIOS) {
      // iOS 관련 설정은 제외
      print('iOS 푸시 알림은 비활성화되었습니다.');
      return;
    }

    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Android용 FCM 토큰 요청 및 알림 처리만 활성화
    String? token = await messaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      // 서버에 토큰 저장 코드
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('포그라운드 푸시 알림 수신: ${message.notification?.title}');
    });
  }
  // Future<void> _initializeFirebaseMessaging() async {
  //   final FirebaseMessaging messaging = FirebaseMessaging.instance;
  //
  //   // 알림 권한 요청
  //   NotificationSettings settings = await messaging.requestPermission(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );
  //
  //   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  //     print('알림 권한 허용됨');
  //   } else {
  //     print('알림 권한 거부됨');
  //     return;
  //   }
  //
  //   // FCM 토큰 가져오기
  //   String? token = await messaging.getToken();
  //   if (token != null) {
  //     print('FCM 토큰: $token');
  //   }
  //
  //   // 포그라운드 알림 처리
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print('포그라운드 푸시 알림 수신: ${message.notification?.title}');
  //     RemoteNotification? notification = message.notification;
  //     AndroidNotification? android = message.notification?.android;
  //
  //     if (notification != null && android != null) {
  //       flutterLocalNotificationsPlugin.show(
  //         notification.hashCode,
  //         notification.title,
  //         notification.body,
  //         NotificationDetails(
  //           android: AndroidNotificationDetails(
  //             'high_importance_channel',
  //             'High Importance Notifications',
  //             importance: Importance.high,
  //           ),
  //         ),
  //       );
  //     }
  //   });
  //
  //   // 알림 클릭 시 앱 열기
  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     print('푸시 알림으로 앱 열림: ${message.notification?.title}');
  //     Navigator.pushNamed(context, '/home');
  //   });
  // }

  /// 다음 화면으로 이동
  void _navigateToNextScreen() {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Image.asset(
            'assets/images/splash_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}