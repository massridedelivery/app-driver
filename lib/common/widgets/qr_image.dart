import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Renders a QR from a backend-supplied source that may arrive in several
/// shapes across payment gateways (SCRUM-42 §2):
///  • an http(s) URL (Omise) → network image
///  • a `data:image/...;base64,…` URI (Beam) → decoded bytes
///  • a **raw** base64 string with no `data:` prefix → decoded bytes
///
/// Anything that fails to load/decode falls back to a plain QR icon.
class QrImage extends StatelessWidget {
  final String source;
  final double size;
  final Widget? fallback;

  const QrImage({
    super.key,
    required this.source,
    this.size = 180,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final fb = fallback ??
        Icon(Icons.qr_code, size: size * 0.9, color: Colors.black);

    final src = source.trim();
    if (src.isEmpty) return fb;

    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fb,
      );
    }

    final bytes = _tryDecodeBase64(src);
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fb,
      );
    }

    return fb;
  }

  /// Decodes a base64 payload that may be a data URI, url-safe, whitespace-laden
  /// or missing padding. Returns null if it isn't decodable base64.
  static Uint8List? _tryDecodeBase64(String raw) {
    var s = raw;

    // Strip a data-URI prefix: `data:image/png;base64,<payload>`.
    if (s.startsWith('data:')) {
      final comma = s.indexOf(',');
      if (comma >= 0) s = s.substring(comma + 1);
    }

    // Drop any whitespace/newlines some backends wrap the payload in.
    s = s.replaceAll(RegExp(r'\s'), '');
    if (s.isEmpty) return null;

    // Pad to a multiple of 4 so unpadded payloads still decode.
    final mod = s.length % 4;
    if (mod != 0) s = s.padRight(s.length + (4 - mod), '=');

    try {
      return base64.decode(s);
    } catch (_) {
      try {
        return base64Url.decode(s); // url-safe alphabet (-_)
      } catch (_) {
        return null;
      }
    }
  }
}
