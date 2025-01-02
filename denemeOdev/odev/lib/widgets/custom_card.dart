import 'package:flutter/material.dart';
import '../theme/theme.dart';  // theme.dart dosyasını doğru şekilde import etmek için

class CustomCard extends StatelessWidget {
  final String title;
  final String description;
  final String sector;
  final String imageUrl; // Resim URL'si
  final VoidCallback onTap;

  CustomCard({
    required this.title,
    required this.description,
    required this.sector,
    required this.imageUrl,  // Resim URL'si parametresi
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,  // Daha derin gölge
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),  // Daha yuvarlak köşeler
        ),
        color: Colors.white,  // Kartın beyaz arka planı
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğraf kısmı
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,  // Resim kartın genişliğine uyum sağlar
                height: 180,  // Resim yüksekliği
                fit: BoxFit.cover,  // Resmi kapsayacak şekilde yerleştirme
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık kısmı
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor, // Vurgulu renk
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Açıklama kısmı
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 12),

                  // Sektör bilgisi ve ikon
                  Row(
                    children: [
                      Icon(
                        Icons.business,  // Sektör ikonu
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Sector: $sector",
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
