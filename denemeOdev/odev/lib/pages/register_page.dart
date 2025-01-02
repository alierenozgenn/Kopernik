// lib/pages/register_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import '../widgets/custom_text_field.dart'; // Import ettiğiniz widget
import '../widgets/custom_button.dart';
import '../theme/theme.dart'; // Tema dosyanızı doğru şekilde import edin

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String? errorMessage;
  bool _isLoading = false;

  Future<void> registerUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Kullanıcı oluşturma
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Kullanıcı bilgilerini Firestore'a ekleme
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': _nameController.text.trim(),
          'uid': user.uid,
          'created_at': FieldValue.serverTimestamp(),
          'profile_picture': '',
        });
      }

      // Kayıt başarılı, giriş sayfasına yönlendirme
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Bir hata oluştu. Lütfen tekrar deneyin.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kopernik Pizza",style: TextStyle(color: Color(0xff0e7f3f)),),
        iconTheme: IconThemeData(color: Color(0xff0e7f3f)),

      ),
      body: SingleChildScrollView( // Klavye açıldığında taşmayı önlemek için
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [

            Center(
              child:
             Image.asset(
              'assets/images/logo.png', // Logo resminizin yolunu belirtin
              height: 210, // Logo yüksekliğini ayarlayın
              width: 210, // Logo genişliğini ayarlayın

            ),


            ),
            SizedBox(height: 40),

            CustomTextField(
              controller: _nameController,
              labelText: 'Kullanıcı Adı',
              keyboardType: TextInputType.name,
              onChanged: (value) {},
            ),
            SizedBox(height: 20),
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
              obscureText: true,
              onChanged: (value) {},
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : CustomButton(
                    text: 'Kayıt Ol',
                    onPressed: registerUser,
                    backgroundColor: Color(0xff0e7f3f), // İstediğiniz renk
                    textColor: Colors.white, // İstediğiniz metin rengi
                  ),
            SizedBox(height: 20),
            CustomButton(
              text: 'Zaten hesabınız mı var? Giriş yapın',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
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

  @override
  void dispose() {
    // Controller'ları serbest bırakmayı unutmayın
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
