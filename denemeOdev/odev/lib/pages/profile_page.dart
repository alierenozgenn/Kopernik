import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:odev/theme/theme.dart';
import 'dart:convert'; // JSON parse için
import 'public_profile_page.dart';
import 'tedarik_detail_page.dart';
import '../widgets/tedarik_card.dart'; // TedarikCard widget'ını doğru import ettiğinden emin ol

class ProfilesPage extends StatefulWidget {
  @override
  _ProfilesPageState createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı verileri
  String _userName = '';
  String _profilePhotoUrl = '';
  String _userEmail = '';

  // TextEditingController - isim düzenlemek için
  TextEditingController _nameController = TextEditingController();

  // Seçilen resim (galeriden)
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Kullanıcıya ait tedarikleri çekecek Future
  late Future<List<Map<String, String>>> _userTedarikItems;

  @override
  void initState() {
    super.initState();
    // Kullanıcı bilgilerini ve kullanıcıya ait tedarikleri çek
    _fetchUserData();
    _userTedarikItems = _fetchUserTedarikItems();
  }

  /// Firestore'dan kullanıcı verisini çekip state'e atar
  Future<void> _fetchUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _userName = data?['name'] ?? '';
          _profilePhotoUrl = data?['profile_photo'] ?? '';
          _userEmail = data?['email'] ?? currentUser.email ?? '';
        });
        // Dialog açıldığında kullanıcının mevcut adını gösterir
        _nameController.text = _userName;
      }
    } catch (e) {
      print('Kullanıcı verisi alınırken hata oluştu: $e');
    }
  }

  /// Bu kullanıcıya (currentUser.uid) ait tedarikleri çekiyoruz
  Future<List<Map<String, String>>> _fetchUserTedarikItems() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('supplies')
          .where('created_by', isEqualTo: currentUser.uid)
          .get();

      List<Map<String, String>> tedarikList = [];
      for (var doc in snapshot.docs) {
        // Tedarik dokümanındaki alanları okuyoruz
        tedarikList.add({
          'docId': doc.id,
          'title': doc['title'],
          'description': doc['description'],
          'price' : doc['price'],
          'sector': doc['sector'],
          // Kullanıcı adı olarak, anlık _userName’i kullanmak istiyorsan:
          'username': _userName.isNotEmpty ? _userName : 'Bilinmiyor',
          // Tedarik resminin URL'si
          'image_url': doc['file_url'] ?? '',
          'user_id': currentUser.uid, 
          'created_by': doc['created_by'] ?? '',
        });
      }
      return tedarikList;
    } catch (e) {
      print("Error fetching user tedarik items: $e");
      return [];
    }
  }

  /// Galeriden fotoğraf seçme
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Fotoğraf seçilirken hata oluştu: $e');
    }
  }
  /// Profil fotoğrafını İmgBB'ye yükleyip linki döndürüyor
  Future<String?> _uploadImageToImgbb(File image) async {
    try {
      // Kendi API key’ini buraya eklemelisin
      final url = Uri.parse(
        'https://api.imgbb.com/1/upload?key=b8e8e63a0125d7bcb819f6833cc22e5b',
      );

      var request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('image', image.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        final imageUrl = jsonResponse['data']['url'];
        return imageUrl;
      } else {
        print('Resim yükleme başarısız. Kod: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Resim yüklenirken hata oluştu: $e');
      return null;
    }
  }

  /// Firestore’da kullanıcı profilini günceller
  Future<void> _updateUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      String? newPhotoUrl = _profilePhotoUrl;
      // Eğer yeni resim seçildiyse önce İmgBB'ye yükle
      if (_imageFile != null) {
        final uploadedUrl = await _uploadImageToImgbb(_imageFile!);
        if (uploadedUrl != null) {
          newPhotoUrl = uploadedUrl;
        }
      }
      // Firestore’u güncelle
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'name': _nameController.text.trim(),
        'profile_photo': newPhotoUrl,
      });

      // State’i güncelleyerek ekranda yansıtmalarını sağla
      setState(() {
        _userName = _nameController.text.trim();
        _profilePhotoUrl = newPhotoUrl ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil başarıyla güncellendi!')),
      );
    } catch (e) {
      print('Profil güncellenirken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme sırasında hata oluştu.')),
      );
    }
  }

  /// Çıkış yap
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yaparken bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      // İstersen AppBar da ekleyebilirsin
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Tüm sayfa dikey olarak sıralansın
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısım: Profil foto + kullanıcı bilgileri + ayar (settings) butonu
            Row(
              children: [
                // Profil fotoğrafı
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_profilePhotoUrl.isNotEmpty
                          ? NetworkImage(_profilePhotoUrl) as ImageProvider
                          : AssetImage('assets/images/default_avatar.png')),
                ),
                SizedBox(width: 16),
                // İsim, e-posta, vb.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kullanıcı adı
                      Text(
                        'Ad: $_userName',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      // E-posta
                      Text(
                        'E-posta: $_userEmail',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      // Alt satır: hesap açılış tarihi ve settings butonu
                      Row(
                        children: [
                          // Hesap açılış tarihi
                          Text(
                            'Hesap Açılış Tarihi: '
                            '${currentUser?.metadata.creationTime?.toLocal().toString().split(' ')[0] ?? "Bilinmiyor"}',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Spacer(),
                          // Ayarlar butonu
                          IconButton(
                            icon: Icon(Icons.settings, color: AppTheme.secondaryColor,),
                            onPressed: () {
                              // Ayar / Profili Düzenle Dialog’u
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Profili Düzenle'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: _nameController,
                                          decoration: InputDecoration(
                                            labelText: 'Yeni Ad',
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        ElevatedButton(
                                          onPressed: () async {
                                            await _pickImage(); 
                                          },
                                          child: Text('Fotoğraf Seç'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text('İptal', style: TextStyle(color: Colors.black),),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await _updateUserProfile();
                                          Navigator.of(context).pop(); 
                                        },
                                        child: Text('Güncelle', style: TextStyle(color: AppTheme.secondaryColor),),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Paylaştığınız Tedarikler başlığı
            Text(
              'Paylaştığınız Tedarikler',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            // Alt kısım: Tedarik kartlarını FutureBuilder ile listeliyoruz
            Expanded(
              child: FutureBuilder<List<Map<String, String>>>(
                future: _userTedarikItems,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Bir hata oluştu: ${snapshot.error}'),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text('Henüz paylaşılmış bir tedarik yok.'),
                    );
                  }

                  final tedarikList = snapshot.data!;

                  return GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.60,
                    ),
                    itemCount: tedarikList.length,
                    itemBuilder: (context, index) {
                      final item = tedarikList[index];
                      return TedarikCard(
                        userId: item['user_id']!,
                        username: item['username']!,
                        title: item['title']!,
                        description: item['description']!,
                        price : item['price']!,
                        sector: item['sector']!,
                        imageUrl: item['image_url']!,
                        docId: item['docId']!,
                        createdBy: item['created_by']!,  
                         onUsernameTap: (String tappedUserId) {
                      // Kullanıcı adına tıklanıldığında, bir profil sayfasına git
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PublicProfilePage(userId: tappedUserId),
                        ),
                      );
                    },
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
