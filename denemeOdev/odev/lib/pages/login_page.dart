// lib/pages/login_page.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'register_page.dart';
import 'home_page.dart';
import '../widgets/tedarik_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../theme/theme.dart'; // Tema dosyanızı doğru şekilde import edin
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odev/main.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? errorMessage;

Future<String?> getFCMToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

Future<void> loginUser() async {
  try {
    final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Get FCM token
    String? fcmToken = await getFCMToken();
    if (fcmToken != null) {
      // Save FCM token to Firestore or backend
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({'fcmToken': fcmToken});
    }
     // Navigate to MainPage after successful login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  } on FirebaseAuthException catch (e) {
    setState(() {
      errorMessage = e.message;
    });
  }
}
  @override
  void dispose() {
    // Controller'ları serbest bırakmayı unutmayın
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kopernik Pizza",style: TextStyle(color: Color(0xff0e7f3f)),),
        iconTheme: IconThemeData(color: Color(0xff0e7f3f)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [

             Center(
              child: Image.asset(
                'assets/images/logo.png', // Logo resminizin yolunu belirtin
                height: 200, // Logo yüksekliğini ayarlayın
                width: 200, // Logo genişliğini ayarlayın
              ),
            ),
            SizedBox(height: 40),
            CustomTextField(
              controller: _emailController,
              labelText: 'E-Posta',
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {},
            ),
            SizedBox(height: 20),
            CustomTextField(
              controller: _passwordController,
              labelText: 'Parola',
              keyboardType: TextInputType.text,
              obscureText: true, // Şifre alanını gizlemek için
              onChanged: (value) {},
            ),
            SizedBox(height: 20),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            CustomButton(
              text: 'Giriş Yap',
              onPressed: loginUser,
              backgroundColor: Color(0xff0e7f3f), // İstediğiniz renk
              textColor: Colors.white, // İstediğiniz metin rengi
            ),
            SizedBox(height: 20),
            CustomButton(
              text: 'Kayıt Ol',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              backgroundColor: Color.fromARGB(255, 165, 158, 152), // İstediğiniz renk
              textColor: Colors.white, // İstediğiniz metin rengi
            ),
          ],
        ),
      ),
    );
  }
}
