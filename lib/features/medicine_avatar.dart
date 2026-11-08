import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// A medicine's own photo/color, with a safe fallback for older/imported records.
class MedicineAvatar extends StatelessWidget {
  final String photo;
  final int color;
  final double size;
  const MedicineAvatar({
    super.key,
    required this.photo,
    required this.color,
    this.size = 64,
  });
  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      if (photo.isNotEmpty) bytes = base64Decode(photo);
    } on FormatException {
      /* Show the medicine symbol. */
    }
    final fallback = Icon(
      Icons.medication_rounded,
      color: Color(color),
      size: size * .52,
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Color(color).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: bytes == null
          ? fallback
          : Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}
