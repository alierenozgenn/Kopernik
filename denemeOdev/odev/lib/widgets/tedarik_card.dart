import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odev/theme/theme.dart';
import '../pages/tedarik_detail_page.dart';

class TedarikCard extends StatefulWidget {
  final String docId;
  final String username;
  final String createdBy;
  final String userId;
  final String title;
  final String description;
  final String price;
  final String sector;
  final String imageUrl;
  final VoidCallback? onApply;
  final Function(String userId)? onUsernameTap;

  const TedarikCard({
    Key? key,
    required this.docId,
    required this.username,
    required this.createdBy,
    required this.userId,
    required this.title,
    required this.description,
    required this.sector,
    required this.imageUrl,
    required this.price,
    this.onApply,
    this.onUsernameTap,
  }) : super(key: key);

  @override
  State<TedarikCard> createState() => _TedarikCardState();
}

class _TedarikCardState extends State<TedarikCard> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isOwner =
        (currentUser != null && currentUser.uid == widget.createdBy);

    // Eğer kendi ilanımız ise buton göstermeyelim
    if (isOwner) {
      return _buildCard(context, null, hasApplied: false, isOwner: true);
    }

    // Eğer kullanıcı giriş yapmamışsa yine buton olmayabilir
    if (currentUser == null) {
      return _buildCard(context, null, hasApplied: false, isOwner: false);
    }

    // Burada “başvuru var mı?” kontrolü için StreamBuilder kullanıyoruz
    final docRef = FirebaseFirestore.instance
        .collection('supplies')
        .doc(widget.docId)
        .collection('applications')
        .doc(currentUser.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        // Henüz veri gelmedi
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(context, null, hasApplied: false, loading: true);
        }

        // Doküman varsa => başvuru yapılmış
        bool alreadyApplied = snapshot.data?.exists ?? false;

        // Buton tıklanınca
        VoidCallback? applyCallback = alreadyApplied
            ? null // Başvuru yapıldıysa pasif
            : widget.onApply;

        return _buildCard(context, applyCallback, hasApplied: alreadyApplied);
      },
    );
  }

  /// Kartın iskeletini oluşturan yardımcı metod.
  /// [applyCallback] null ise başvuru butonu pasif, null değilse aktif.
  /// [hasApplied] => true ise buton gri / "Başvuru Yapıldı"
  Widget _buildCard(
    BuildContext context,
    VoidCallback? applyCallback, {
    required bool hasApplied,
    bool loading = false,
    bool isOwner = false,
  }) {
    return GestureDetector(
      // Kartın tamamına tıklayınca TedarikDetailPage(docId: docId) aç
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TedarikDetailPage(docId: widget.docId),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üstteki fotoğraf
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                height: 100,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Eğer imageUrl hatalıysa, bir yedek resim gösterebilirsin
                  return Container(
                    height: 100,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),

            // Kullanıcının adı satırı
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Kullanıcı adını tıklanabilir yap
                  GestureDetector(
                    onTap: () => widget.onUsernameTap?.call(widget.userId),
                    child: Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                ],
              ),
            ),

            // Tedarik ismi (buton rengiyle aynı arkaplanda ve ortada)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Color(0xfff6efee),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000000),
                ),
              ),
            ),

            // Açıklama (sola yaslı)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
            Spacer(),
            // Sektör ve fiyat (solda sektör, sağda fiyat)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.style,
                    size: 14,
                    color: Colors.black54,
                  ),
                  // Sektör
                  Text(
                    widget.sector,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                  Spacer(),
                  // Fiyat
                  Text(
                    widget.price + " TL",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      color: AppTheme.price,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Eğer loading ise (snapshot bekleniyorsa), CircularProgressIndicator gösterebilirsiniz
            if (loading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (!isOwner)
              // Kullanıcı sahibi değil => Buton göster
              GestureDetector(
                onTap: applyCallback, // null ise pasif olur
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasApplied
                        ? AppTheme.textLightColor
                        : AppTheme.secondaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasApplied ? 'Başvuru Yapıldı' : 'Başvur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
