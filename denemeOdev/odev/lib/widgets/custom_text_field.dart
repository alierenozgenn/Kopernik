// lib/widgets/custom_text_field.dart

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final Function(String) onChanged;
  final InputDecoration? decoration;
  final bool obscureText; // Yeni parametre

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.keyboardType,
    required this.onChanged,
    this.decoration,
    this.obscureText = false, // Varsayılan olarak false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      obscureText: obscureText, // Yeni parametre kullanıldı
      decoration: decoration ??
          InputDecoration(
            labelText: labelText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.blue, // İstediğiniz renk
              ),
            ),
          ),
    );
  }
}
