import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../widgets/tedarik_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'public_profile_page.dart';
import '../theme/theme.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<Map<String, String>>> _tedarikItemsStream;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tedarikItemsStream = fetchTedarikItems();
  }

  Stream<List<Map<String, String>>> fetchTedarikItems() {
    return FirebaseFirestore.instance
        .collection('supplies')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, String>> tedarikList = [];
      for (var doc in snapshot.docs) {
        String createdBy = doc['created_by'];
        String name = await _fetchUsernameFromUid(createdBy);

        tedarikList.add({
          'docId': doc.id,
          'title': doc['title'],
          'description': doc['description'],
          'price' : doc['price'],
          'sector': doc['sector'],
          'name': name,
          'file_url': doc['file_url'] ?? '',
          'user_id': createdBy,
          'created_by': doc['created_by'] ?? '',
        });
      }
      return tedarikList;
    });
  }

  Future<String> _fetchUsernameFromUid(String created_by) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(created_by)
          .get();

      if (userDoc.exists) {
        return userDoc['name'] ?? 'Bilinmiyor';
      } else {
        return 'Bilinmiyor';
      }
    } catch (e) {
      print("Error fetching name: $e");
      return 'Bilinmiyor';
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yaparken bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomTextField(
            controller: _searchController,
            labelText: 'Ara...',
            keyboardType: TextInputType.text,
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, String>>>(
            stream: _tedarikItemsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Bir hata oluştu: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text("Veri bulunamadı."));
              }

              final filteredItems = snapshot.data!
                  .where((item) =>
                      item['title']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      item['description']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      item['sector']!.toLowerCase().contains(searchQuery.toLowerCase())||
                      item['name']!.toLowerCase().contains(searchQuery.toLowerCase())
                      )
                  .toList();

              return GridView.builder(
                padding: EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.5,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return TedarikCard(
                    docId: item['docId']!,
                    userId: item['user_id']!,
                    username: item['name']!,
                    title: item['title']!,
                    description: item['description']!,
                    price: item['price']!,
                    sector: item['sector']!,
                    imageUrl: item['file_url']!,
                    createdBy: item['created_by']!,
                    onApply: () {
                      _applyForTedarik(item['docId']!);
                    },
                    onUsernameTap: (String tappedUserId) {
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomButton(
            text: 'Yeni Tedarik Ekle',
            onPressed: () {
              _showAddSupplyDialog(context);
            },
            backgroundColor: Theme.of(context).colorScheme.secondary,
            textColor: Colors.white,
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    );
  }

  void _showAddSupplyDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController sectorController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // StatefulBuilder ekleyerek setState kullanımı sağlanır
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Yeni Tedarik Ekle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    CustomTextField(
                      controller: titleController,
                      labelText: 'Başlık',
                      keyboardType: TextInputType.text,
                      onChanged: (value){},
                    ),
                    SizedBox(height: 8),
                    CustomTextField(
                      controller: priceController,
                      labelText: 'Fiyat',
                      keyboardType: TextInputType.text,
                      onChanged: (value){},
                    ),
                    SizedBox(height: 8),
                    CustomTextField(
                      controller: descriptionController,
                      labelText: 'Açıklama',
                      keyboardType: TextInputType.text,
                      onChanged: (value){},

                    ),
                    SizedBox(height: 8),
                    CustomTextField(
                      controller: sectorController,
                      labelText: 'Sektör',
                      keyboardType: TextInputType.text, 
                      onChanged: (value){},

                    ),
                    SizedBox(height: 8),
                    CustomButton(
                      text: 'Fotoğraf Seç',
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            selectedImage = File(pickedFile.path);
                          });
                        }
                      },
                      backgroundColor: AppTheme.secondaryColor,
                      textColor: Colors.white,
                    ),
                    if (selectedImage != null) ...[
                      SizedBox(height: 16),
                      Image.file(
                        selectedImage!,
                        height: 100,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                CustomButton(
                  text: 'İptal',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  backgroundColor: Colors.grey,
                  textColor: Colors.white,
                ),
                SizedBox(height: 8),
                CustomButton(
                  text: 'Ekle',
                  onPressed: () async {
                    await _addSupply(
                      titleController.text,
                      priceController.text,
                      descriptionController.text,
                      sectorController.text,
                      selectedImage,
                    );
                    Navigator.of(context).pop();
                  },
                  backgroundColor: AppTheme.secondaryColor,
                  textColor: Colors.white,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addSupply(String title, String price,String description, String sector, File? image) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      String? imageUrl;
      if (image != null) {
        imageUrl = await uploadImageToImgbb(image);
        if (imageUrl == null) {
          print('Resim yükleme başarısız.');
          return;
        }

        await FirebaseFirestore.instance.collection('supplies').add({
          'title': title,
          'price': price,
          'description': description,
          'sector': sector,
          'created_by': user?.uid,
          'created_at': Timestamp.now(),
          'file_url': imageUrl,
        });

        print('Yeni tedarik başarıyla eklendi.');
      }
    } catch (e) {
      print("Tedarik eklerken hata oluştu: $e");
    }
  }

  Future<String?> uploadImageToImgbb(File image) async {
    try {
      final url = Uri.parse('https://api.imgbb.com/1/upload?key=b8e8e63a0125d7bcb819f6833cc22e5b'); // API anahtarınızı ekleyin

      var request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('image', image.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        final imageUrl = jsonResponse['data']['url'];
        print('Resim yüklendi: $imageUrl');
        return imageUrl;
      } else {
        print('Resim yükleme başarısız.');
        return null;
      }
    } catch (e) {
      print("Resim yüklerken hata oluştu: $e");
      return null;
    }
  }

  Future<void> _applyForTedarik(String docId) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final currentUser = _auth.currentUser;

    if (currentUser == null) return;
    try {
      final applicationsRef = FirebaseFirestore.instance
          .collection('supplies')
          .doc(docId)
          .collection('applications');

      await applicationsRef.doc(currentUser.uid).set({
        'userId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Başvuru başarılı!');
    } catch (e) {
      print('Başvuru sırasında hata: $e');
    }
  }
}
