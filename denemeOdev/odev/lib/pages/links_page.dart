// lib/pages/my_supplies_applications_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// TedarikCard'ı veya kendi tasarımınızı import edin
import '../widgets/tedarik_card.dart';
import 'tedarik_detail_page.dart'; // Detay sayfasına gitmek isteyebilirsiniz

class MySuppliesApplicationsPage extends StatelessWidget {
  const MySuppliesApplicationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Başvurular")),
        body: Center(child: Text("Lütfen giriş yapınız.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Benim Tedarik İlanlarım")),
      body: StreamBuilder<QuerySnapshot>(
        // 1) Benim oluşturduğum (created_by == currentUser.uid) tedarikler
        stream: FirebaseFirestore.instance
            .collection('supplies')
            .where('created_by', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, suppliesSnap) {
          if (suppliesSnap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (suppliesSnap.hasError) {
            return Center(child: Text('Hata: ${suppliesSnap.error}'));
          }
          if (!suppliesSnap.hasData || suppliesSnap.data!.docs.isEmpty) {
            return Center(child: Text("Henüz oluşturduğunuz bir tedarik yok."));
          }

          final suppliesDocs = suppliesSnap.data!.docs;

          return ListView.builder(
            itemCount: suppliesDocs.length,
            itemBuilder: (context, index) {
              final supplyDoc = suppliesDocs[index];
              final supplyData = supplyDoc.data() as Map<String, dynamic>?;

              if (supplyData == null) {
                return ListTile(
                  title: Text("Boş Doküman"),
                );
              }

              // Tedarik bilgileri
              final docId = supplyDoc.id;
              final title = supplyData['title'] ?? 'No title';
              final description = supplyData['description'] ?? '...';
              final price = supplyData['price'] ?? '...';
              final sector = supplyData['sector'] ?? '';
              final imageUrl = supplyData['file_url'] ?? '';
              final createdBy = supplyData['created_by'] ?? '';
              final username = supplyData['name'] ?? '';

              // Loglar ekleyerek veri akışını kontrol edin
              print("DocID: $docId, Title: $title, Username: $username");

              return TedarikCard(
                docId: docId,
                userId: createdBy,
                username: username.isNotEmpty ? username : 'Tanımlanmamış',
                title: title,
                price: price,
                description: description,
                sector: sector,
                imageUrl: imageUrl,
                createdBy: createdBy,
                onApply: null, // Kendimize başvuramayız, null
                onUsernameTap: (tappedUserId) {
                  // Profil sayfasına yönlendirme
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TedarikDetailPage(docId: docId),
                    ),
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
