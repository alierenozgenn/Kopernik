import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

// Sayfalar
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/application_page.dart';
import 'pages/profile_page.dart';

// Tema
import 'theme/theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupLocalNotifications();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kopernik Pizza',
      theme: AppTheme.theme,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    playSound();
    navigateToAuthCheck();
  }

  void playSound() async {
    // Ses dosyasını çal
    await audioPlayer.play(AssetSource('sounds/splash_sound.mp3'));

    // Sesin bitmesini beklemek için bir Completer kullan
    var completer = Completer<void>();

    // Ses bittiğinde Completer'ı tamamla
    audioPlayer.onPlayerComplete.listen((event) {
      completer.complete();
    });

    // Ses bitene kadar bekle
    await completer.future;
  }

  void navigateToAuthCheck() async {
    await Future.delayed(Duration(seconds: 5)); // Splash ekranının gösterileceği süre
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthCheck()),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset('assets/animations/splash_animation.json',
        ),
      ),
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.hasData ? MainPage() : LoginPage();
      },
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    ApplicationsPage(),
    ProfilesPage(),
  ];

  String getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Ana Sayfa';
      case 1:
        return 'Başvurularım';
      case 2:
        return 'Profilim';
      default:
        return '';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    setupFirebaseMessaging();
  }

  Future<void> setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Kullanıcı bildirimlere izin verdi.');
    } else {
      print('Kullanıcı bildirimlere izin vermedi.');
    }

    String? token = await messaging.getToken();
    print('FCM Token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Ön planda bildirim alındı: ${message.notification?.title}');

      // Bildirimi manuel olarak göster
      showNotification(
        message.notification?.title ?? 'Bildirim',
        message.notification?.body ?? 'Yeni bildirim',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Arka planda bildirim tıklandı: ${message.notification?.title}');
    });

    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print(
          'Uygulama kapalıyken gelen bildirim: ${initialMessage.notification?.title}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 70,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            return Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    getPageTitle(_selectedIndex),
                    style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 21,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Align(
                  alignment: Alignment(
                    (30.0 / (screenWidth / 2)),
                    0.0,
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AuthCheck()),
                      );
                    }, // Image tapped
                    borderRadius: BorderRadius.circular(30),
                    splashColor: Colors.white10, // Splash color over image
                    child: Ink.image(
                      fit: BoxFit.cover, // Fixes border issues
                      width: 60,
                      height: 60,
                      image: AssetImage(
                        'assets/images/logo.png',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout,
                color: AppTheme.secondaryColor, size: 28),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppTheme.secondaryColor,
        unselectedItemColor: AppTheme.textLightColor,
        showUnselectedLabels: false,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
            backgroundColor: AppTheme.primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Başvurular',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilim',
          ),
        ],
      ),
    );
  }
}

Future<void> setupLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('notification');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'high_importance_channel', // channelId
    'High Importance Notifications', // channelName
    channelDescription:
    'This channel is used for important notifications.', // channelDescription
    importance: Importance.max,
    priority: Priority.high,
    largeIcon: DrawableResourceAndroidBitmap("notification"),
    icon: "@mipmap/ic_launcher",
    playSound: true,
    sound: RawResourceAndroidNotificationSound("notification_sound"), // Ses dosyası adı (uzantı olmadan)
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
  );
}