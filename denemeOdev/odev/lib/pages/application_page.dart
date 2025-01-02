import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'public_profile_page.dart';

import '../widgets/tedarik_card.dart';

class ApplicationsPage extends StatelessWidget {
  const ApplicationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Kullanıcı giriş yapmamışsa bir bilgilendirme gösterilebilir
    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text("Lütfen giriş yapınız.")),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        // applications alt koleksiyonlarını tarar ve kullanıcının başvurularını getirir
        stream: FirebaseFirestore.instance
            .collectionGroup('applications')
            .where('userId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, appSnap) {
          if (appSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (appSnap.hasError) {
            return Center(child: Text('Bir hata oluştu: ${appSnap.error}'));
          }
          if (!appSnap.hasData || appSnap.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz bir başvurunuz yok."));
          }

          final applicationDocs = appSnap.data!.docs;

          return ListView.builder(
            itemCount: applicationDocs.length,
            itemBuilder: (context, index) {
              final applicationDoc = applicationDocs[index];
              final supplyRef = applicationDoc.reference.parent.parent;

              if (supplyRef == null) {
                return const ListTile(
                  title: Text("İlgili Tedarik bulunamadı."),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: supplyRef.get(),
                builder: (context, supplySnap) {
                  if (supplySnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (supplySnap.hasError) {
                    return Text(
                        "Tedarik yüklenirken hata: ${supplySnap.error}");
                  }
                  if (!supplySnap.hasData || !supplySnap.data!.exists) {
                    return const ListTile(
                      title: Text("Tedarik bulunamadı veya silinmiş."),
                    );
                  }

                  final supplyData =
                      supplySnap.data!.data() as Map<String, dynamic>;
                  final docId = supplySnap.data!.id;
                  final createdBy = supplyData['created_by'] ?? '';
                  final title = supplyData['title'] ?? '';
                  final description = supplyData['description'] ?? '';
                  final price = supplyData['price'] ?? '';
                  final sector = supplyData['sector'] ?? '';
                  final imageUrl = supplyData['file_url'] ?? '';

                  // Kullanıcı bilgilerini çekmek için FutureBuilder
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(createdBy)
                        .get(),
                    builder: (context, userSnap) {
                      if (userSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (userSnap.hasError) {
                        return Text(
                            "Kullanıcı bilgileri yüklenirken hata: ${userSnap.error}");
                      }
                      if (!userSnap.hasData || !userSnap.data!.exists) {
                        return const ListTile(
                          title: Text("Kullanıcı bulunamadı."),
                        );
                      }

                      final userData =
                          userSnap.data!.data() as Map<String, dynamic>;
                      final username =
                          userData['name'] ?? 'Bilinmeyen Kullanıcı';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: SizedBox(
                          height: 350,
                          child: TedarikCard(
                            docId: docId,
                            userId: createdBy,
                            username:
                                username, // Kullanıcı adını buraya ekleyin
                            title: title,
                            price: price,
                            description: description,
                            sector: sector,
                            imageUrl: imageUrl,
                            createdBy: createdBy,
                            onUsernameTap: (tappedUserId) {
                              // Kullanıcı profil sayfasına yönlendirme
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PublicProfilePage(userId: tappedUserId),
                                ),
                              );
                            },
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
    );
  }
}
