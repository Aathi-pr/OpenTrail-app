import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class OpentrailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final bool obscureText;
  final String? hintText;
  const OpentrailTextField({
    super.key,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.hintText
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: const Color(0xFFFFFFFF),),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: Colors.white70
          )
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: Colors.white70
          )
        )
        ),

    );
  }
}
