// lib/widgets/custom_button.dart

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor; // Buton arka plan rengi
  final Color? textColor; // Buton metin rengi
  final TextStyle? textStyle; // Buton metin stili
  final BorderRadius? borderRadius; // Buton köşe yuvarlaklığı

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor, // Opsiyonel
    this.textColor, // Opsiyonel
    this.textStyle, // Opsiyonel
    this.borderRadius, // Opsiyonel
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Butonun tam genişlik almasını sağlar
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: textStyle ??
              TextStyle(
                color: textColor ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary, // 'primary' yerine 'backgroundColor' kullanıldı
          foregroundColor: textColor ?? Colors.white, // Metin rengi
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
}
