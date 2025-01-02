import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:odev/theme/theme.dart';
import 'dart:convert';
import 'public_profile_page.dart';
import 'package:odev/widgets/full_screen_view.dart';

class TedarikDetailPage extends StatefulWidget {
  final String docId; // Bu tedarik kaydının Firestore'daki doküman ID'si

  const TedarikDetailPage({Key? key, required this.docId}) : super(key: key);

  @override
  State<TedarikDetailPage> createState() => _TedarikDetailPageState();
}

class _TedarikDetailPageState extends State<TedarikDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tedarik bilgisini tutacak değişkenler
  String _title = '';
  String _description = '';
  String _price = '';
  String _sector = '';
  String _imageUrl = '';
  String _createdBy = '';
  String _ownerPhoto = '';
  String _ownerName = '';

  bool _isOwner = false; // Bu tedarik currentUser'a mı ait?

  File? _newImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchTedarikData();
  }

  /// 1. Tedarik bilgisini Firestore'dan çek
  Future<void> _fetchTedarikData() async {
    final docRef =
        FirebaseFirestore.instance.collection('supplies').doc(widget.docId);

    try {
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        // Belki kullanıcıya hata göster
        print('Tedarik bulunamadı.');
        return;
      }
      final data = docSnap.data() as Map<String, dynamic>;
      final currentUser = _auth.currentUser;
      final createdByUid = data['created_by'];

      setState(() {
        _title = data['title'] ?? '';
        _description = data['description'] ?? '';
        _price = data['price'] ?? '';
        _sector = data['sector'] ?? '';
        _imageUrl = data['file_url'] ?? '';
        _createdBy = data['created_by'] ?? '';
        // Eğer giriş yapmış kullanıcının uid'si created_by'ya eşitse => sahibi
        _isOwner = (currentUser != null && currentUser.uid == _createdBy);
      });

       // Kullanıcı detaylarını çek
    if (createdByUid != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(createdByUid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _ownerName = userData['name'] ?? 'Bilinmeyen Sahip';
          _ownerPhoto = userData['profile_photo'] ??
              'assets/images/default_avatar.png';
        });
      }
    }

    } catch (e) {
      print('TedarikDetailPage - Tedarik verisi alınırken hata: $e');
    }
  }
  Future<void> _pickNewImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _newImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Fotoğraf seçilirken hata oluştu: $e');
    }
  }

  /// Profil fotoğrafını İmgBB'ye yükleyip linki döndürüyor
  Future<String?> _uploadImageToImgbb(File image) async {
    try {
      // Kendi API key’inizi buraya ekleyin
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
  /// 2. Eğer sahibi isek, "Düzenle / Sil" butonuna basınca açılacak dialog
  void _showEditDialog() {
    // Dialog içindeki TextField'lar için kontrolcüler
    final TextEditingController titleCtrl = TextEditingController(text: _title);
    final TextEditingController descCtrl =
        TextEditingController(text: _description);
    final TextEditingController priceCtrl =
        TextEditingController(text: _price);
    final TextEditingController sectorCtrl =
        TextEditingController(text: _sector);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Tedariği Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: 'Başlık'),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: 'Açıklama'),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  decoration: InputDecoration(labelText: 'Fiyat'),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: sectorCtrl,
                  decoration: InputDecoration(labelText: 'Sektör'),
                ),
                 SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _pickNewImage();
                  },
                  icon: Icon(Icons.image),
                  label: Text('Fotoğraf Seç'),
                ),
                if (_newImageFile != null) ...[
                  SizedBox(height: 16),
                  Image.file(
                    _newImageFile!,
                    height: 100,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), // Dialog'u kapat
              child: Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () async {
                // Tedarik güncelle
                await _updateTedarik( titleCtrl.text, descCtrl.text, priceCtrl.text, sectorCtrl.text);
                Navigator.pop(ctx); // Dialog kapat
              },
              child: Text('Kaydet'),
            ),
            TextButton(
              onPressed: () async {
                // Tedarik sil
                await _deleteTedarik();
                Navigator.pop(ctx); // Dialog kapat
                Navigator.pop(context); // Detay sayfasından da geri dön
              },
              child: Text(
                'Sil',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 3. Firestore'da tedarik kaydını güncelle
  Future<void> _updateTedarik(title, description, price, sector) async {
    final docRef =
        FirebaseFirestore.instance.collection('supplies').doc(widget.docId);
    try {
      String? newImageUrl = _imageUrl;

      // Eğer yeni resim seçildiyse önce İmgBB'ye yükle
      if (_newImageFile != null) {
        final uploadedUrl = await _uploadImageToImgbb(_newImageFile!);
        if (uploadedUrl != null) {
          newImageUrl = uploadedUrl;
        } else {
          // Yükleme başarısızsa işlemi durdur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Resim yükleme başarısız oldu.')),
          );
          return;
        }
      }

      // Firestore’u güncelle
      await docRef.update({
        'title': title,
        'description': description,
        'price': price,
        'sector': sector,
        'file_url': newImageUrl,
      });

      // State’i güncelleyerek ekranda yansıtmalarını sağla
      setState(() {
        _title = title;
        _description = description;
        _price = price;
        _sector = sector;
        _imageUrl = newImageUrl ?? '';
        _newImageFile = null; // Yeni resim dosyasını temizle
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tedarik başarıyla güncellendi!')),
      );
    } catch (e) {
      print('Tedarik güncellenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme sırasında hata oluştu.')),
      );
    }
  }

  /// 4. Firestore'da tedarik kaydını sil
 Future<void> _deleteTedarik() async {
  try {
    print("Silinecek docId: ${widget.docId}"); // Silinecek doküman ID'sini logla
    await FirebaseFirestore.instance
        .collection('supplies')
        .doc(widget.docId)
        .delete();
    print("Tedarik başarıyla silindi.");
    // Geri dönme işlemini dialogdan sonra yapıyoruz
  } catch (e) {
    print('Tedarik silinirken hata: $e');
  }
}

  /// 5. Başkasının tedariki ise "Başvur" butonuna basınca subcollection'a ekle
  Future<void> _applyForTedarik() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      final applicationsRef = FirebaseFirestore.instance
          .collection('supplies')
          .doc(widget.docId)
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

  /// 6. Tedarik sahibi ise, alt tarafta başvuruda bulunanları listele
  /// `supplies/{docId}/applications` alt koleksiyonundan veriyi çekiyoruz.
  Stream<QuerySnapshot> _getApplicantsStream() {
    return FirebaseFirestore.instance
        .collection('supplies')
        .doc(widget.docId)
        .collection('applications')
        .snapshots();
  }

  /// 7. Tedarik sayfasındaki "Başvur" veya "Başvuru Yapıldı" butonunu oluşturan kısım
  ///    Eğer kullanıcı sahibi ise "Düzenle / Sil" göster, değilse StreamBuilder ile başvuruyu kontrol et.
  Widget _buildApplyOrOwnerButton() {
    // Oturum açan kullanıcı
    final currentUser = _auth.currentUser;

    // Eğer tedarik sahibi isek => "Düzenle/Sil"
    if (_isOwner) {
      return ElevatedButton.icon(
        icon: Icon(Icons.edit),
        label: Text('Tedariki Düzenle / Sil'),
        onPressed: _showEditDialog,
      );
    }

    // Eğer kullanıcı giriş yapmamışsa => buton "Giriş Yap" olarak gösterilebilir
    if (currentUser == null) {
      return ElevatedButton.icon(
        icon: Icon(Icons.lock),
        label: Text('Giriş Yap'),
        onPressed: () {
          // Burada login sayfasına yönlendirebilirsiniz
        },
      );
    }

    // Buraya geldiysek => sahibi değil ve giriş yapmış
    // Artık başvuru yapılmış mı yapılmamış mı kontrol ediyoruz
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('supplies')
          .doc(widget.docId)
          .collection('applications')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Henüz veri çekiliyor, bir loading gösterebilirsiniz
          return Center(child: CircularProgressIndicator());
        }

        // Doküman varsa => başvuru yapılmış
        final hasApplied = snapshot.data?.exists ?? false;

        if (hasApplied) {
          // Başvuru yapılmış => pasif buton, "Başvuru Yapıldı"
          return ElevatedButton.icon(
            onPressed: null, // pasif
            icon: Icon(Icons.check),
            label: Text('Başvuru Yapıldı'),
          );
        } else {
          // Başvuru yapılmamış => "Başvur" butonu aktif
          return ElevatedButton.icon(
            icon: Icon(Icons.send),
            label: Text('Başvur'),
            onPressed: _applyForTedarik,
          );
        }
      },
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Fotoğraf ve sol üstte geriye dön butonu
        Column(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageView(imageUrl: _imageUrl),
                      ),
                    );
                  },
                child: _imageUrl.isNotEmpty
                    ? Image.network(
                        _imageUrl,
                        height: 400,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 400,
                        color: Colors.grey,
                        child: const Center(child: Text('Fotoğraf yok')),
                      ),
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.secondaryColor),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            // 2) Başlık, fiyat ve açıklama
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title ve Price
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2, // Title iki satır olabilir
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _price + " TL",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryColor, // Buton rengiyle aynı
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _sector,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Owner photo, name, and button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Owner photo
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: _imageUrl.isNotEmpty
                              ? NetworkImage(_ownerPhoto)
                              : const AssetImage('assets/images/default_avatar.png')
                                  as ImageProvider,
                        ),
                        const SizedBox(width: 16),

                         Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Kullanıcının profil sayfasına git
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PublicProfilePage(
                                  userId: _createdBy, // _ownerId, sahibin kullanıcı ID'si olmalı
                                ),
                              ),
                            );
                          },
                          child: Text(
                            _ownerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                        // Button
                        _buildApplyOrOwnerButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Eğer sahibi ise başvuranlar listesi
            if (_isOwner) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Başvuranlar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _getApplicantsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Henüz başvuran yok.'),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true, // Parent ScrollView ile uyumlu
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final appData =
                          docs[index].data() as Map<String, dynamic>;
                      final applicantUid = appData['userId'] ?? 'Unknown';

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(applicantUid)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const SizedBox();
                          }

                          final userDoc = userSnapshot.data!;
                          if (!userDoc.exists) {
                            return const ListTile(
                              title: Text('Bilinmeyen Kullanıcı'),
                            );
                          }

                          final userData =
                              userDoc.data() as Map<String, dynamic>;
                          final applicantName = userData['name'] ?? 'No Name';
                          final applicantPhoto =
                              userData['profile_photo'] ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: applicantPhoto.isNotEmpty
                                  ? NetworkImage(applicantPhoto)
                                  : const AssetImage(
                                      'assets/images/default_avatar.png',
                                    ) as ImageProvider,
                            ),
                            title: Text(applicantName),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PublicProfilePage(
                                    userId: applicantUid,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ],
    ),
  );
}
}