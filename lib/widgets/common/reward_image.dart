import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Helper widget yang bisa menampilkan gambar dari:
/// - URL biasa (https://...)
/// - Base64 data URI (data:image/jpeg;base64,...)
/// - Atau fallback ke placeholder jika kosong/gagal
class RewardImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;

  const RewardImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fallback = placeholder ??
        const Icon(Icons.card_giftcard, color: Colors.grey, size: 28);

    if (imageUrl.isEmpty) return fallback;

    // Base64 data URI
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.split(',').last;
        final Uint8List bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }

    // URL biasa
    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
