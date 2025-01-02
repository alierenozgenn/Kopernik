import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odev/theme/theme.dart';
import 'tedarik_detail_page.dart';
import '../widgets/tedarik_card.dart';
import 'package:firebase_auth/firebase_auth.dart';


class PublicProfilePage extends StatefulWidget {
  final String userId; // Hangi kullanıcının profilini göreceğimizi belirler

  const PublicProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _PublicProfilePageState createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  String _userName = '';
  String _profilePhotoUrl = '';
  String _userEmail = '';

  // Bu kullanıcıya ait tedarikleri tutacak Future
  late Future<List<Map<String, String>>> _otherUserTedarikItems;

  @override
  void initState() {
    super.initState();
    // 1. Kullanıcı verisini çek
    _fetchUserData();
    // 2. Kullanıcının paylaşımlarını (supplies) çek
    _otherUserTedarikItems = _fetchOtherUserTedarikItems(widget.userId);
  }

  /// Diğer kullanıcının Firestore’daki profil bilgilerini çek
  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['name'] ?? 'Bilinmiyor';
          _profilePhotoUrl = data['profile_photo'] ?? '';
          _userEmail = data['email'] ?? 'Bilinmiyor';
        });
      }
    } catch (e) {
      print("PublicProfilePage - Kullanıcı verisi alınırken hata: $e");
    }
  }

  /// Bu kullanıcıya ait tedarikleri çek
  Future<List<Map<String, String>>> _fetchOtherUserTedarikItems(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('supplies')
          .where('created_by', isEqualTo: userId)
          .get();

      List<Map<String, String>> tedarikList = [];
      for (var doc in snapshot.docs) {
        // Dokümandaki verileri okuyoruz
        final data = doc.data() as Map<String, dynamic>;

        tedarikList.add({
          'docId': doc.id,
          'title': data['title'] ?? 'No Title',
          'price': data['price'] ?? 'No Price',
          'description': data['description'] ?? '',
          'sector': data['sector'] ?? '',
          'username': _userName.isNotEmpty ? _userName : 'Bilinmiyor',
          'image_url': data['file_url'] ?? '',
          'created_by': data['created_by'] ?? '',
          'user_id': userId,
        });
      }
      return tedarikList;
    } catch (e) {
      print("PublicProfilePage - Tedarikler alınırken hata: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar'da kullanıcı adını göstermek istersek:
      appBar: AppBar(
        title: Text(_userName.isNotEmpty ? _userName : 'Kullanıcı Profili', style: TextStyle(color: AppTheme.secondaryColor),),
        iconTheme: IconThemeData(color: AppTheme.secondaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // Ekrandaki bileşenleri dikey diziyoruz
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üstte profil foto ve kullanıcı bilgileri
            Row(
              children: [
                // Profil fotoğrafı
                CircleAvatar(
                  radius: 50,
                  backgroundImage: (_profilePhotoUrl.isNotEmpty)
                      ? NetworkImage(_profilePhotoUrl) as ImageProvider
                      : AssetImage('assets/images/default_avatar.png'),
                ),
                SizedBox(width: 16),
                // Kullanıcı adı, e-posta vb.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'E-posta: $_userEmail',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // "Paylaştığı Tedarikler" başlığı
            Text(
              'Paylaştığı Tedarikler',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            // GridView / FutureBuilder
            Expanded(
              child: FutureBuilder<List<Map<String, String>>>(
                future: _otherUserTedarikItems,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Bir hata oluştu: ${snapshot.error}'),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text('Bu kullanıcının henüz paylaşımı yok.'),
                    );
                  }

                  final tedarikList = snapshot.data!;

                  return GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,         // 2 sütun
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: tedarikList.length,
                    itemBuilder: (context, index) {
                      final item = tedarikList[index];
                      return TedarikCard(
                        userId: item['user_id']!, 
                        createdBy: item['created_by']!,    // onUsernameTap vb. için
                        username: item['username']!,
                        title: item['title']!,
                        price: item['price']!,
                        description: item['description']!,
                        sector: item['sector']!,
                        imageUrl: item['image_url']!,
                        docId: item['docId']!,

                        onApply: () {
                          _applyForTedarik(item['docId']!);
                           button_color: Colors.green;
                          // Burada başvuru mantığını yazabilirsin
                        },
                           // Bu profil sayfasında başvur butonu yoksa
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  /// 5. Başkasının tedariki ise "Başvur" butonuna basınca subcollection'a ekle
  Future<void> _applyForTedarik(String docId) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
 
    final currentUser = _auth.currentUser;

    if (currentUser == null) return;
    try {
      final applicationsRef = FirebaseFirestore.instance
          .collection('supplies')
          .doc(docId)
          .collection('applications');

      // Basit bir şekilde doc id olarak currentUser.uid kullanabilirsin
      await applicationsRef.doc(currentUser.uid).set({
        'userId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Başvuru başarılı!');
    } catch (e) {
      print('Başvuru sırasında hata: $e');
    }
  }