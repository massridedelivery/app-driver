import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Convention guard (SCRUM-42 §2): QR codes must be rendered through the shared
/// `QrImage` widget (lib/common/widgets/qr_image.dart), never `Image.network`.
///
/// Why: a payment QR's `qr_code_url` can arrive as an http(s) URL (Omise) OR as
/// a `data:image/...;base64,...` URI (Beam). Flutter's `Image.network` CANNOT
/// decode a `data:` URI, so a Beam QR would silently fail to render. `QrImage`
/// detects the shape and decodes base64 via `Image.memory`, making the
/// Omise→Beam migration a no-op. This test fails the build if anyone renders a
/// QR-ish source with `Image.network` so the regression can't sneak back in.
void main() {
  test('QR sources are rendered via QrImage, never Image.network', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'run from the package root');

    final networkCall = RegExp(r'Image\.network\s*\(');
    final violations = <String>[];

    // The QrImage widget itself is the sanctioned renderer: it uses
    // Image.network for the http(s) case, and its doc references the anti-pattern
    // by name. Exempt only this one file.
    final normalizedSep = Platform.pathSeparator;
    final qrImagePath =
        'lib${normalizedSep}common${normalizedSep}widgets${normalizedSep}qr_image.dart';

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith(qrImagePath) ||
          entity.path.endsWith('lib/common/widgets/qr_image.dart')) {
        continue;
      }
      final text = entity.readAsStringSync();

      for (final m in networkCall.allMatches(text)) {
        // Look at the argument that follows the call opening paren.
        final windowEnd = (m.end + 80) > text.length ? text.length : m.end + 80;
        var arg = text.substring(m.end, windowEnd).toLowerCase();
        final closeParen = arg.indexOf(')');
        if (closeParen >= 0) arg = arg.substring(0, closeParen);

        // A "qr" anywhere in the argument means a QR source is being passed to
        // Image.network — the exact pattern that breaks on Beam data: URIs.
        if (arg.contains('qr')) {
          final line = '\n'.allMatches(text.substring(0, m.start)).length + 1;
          violations.add('${entity.path}:$line');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Render QR via QrImage (lib/common/widgets/qr_image.dart), not '
          'Image.network — it cannot decode Beam `data:` URIs. Offending '
          'call(s):\n  ${violations.join('\n  ')}',
    );
  });
}
