import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Longest side a chat photo is sent at.
const int chatImageMaxSide = 1600;

/// Upload limit the backend accepts for a chat image.
const int chatImageMaxBytes = 2 * 1024 * 1024;

/// Thrown when the picked file can't be read as an image.
class ChatImageDecodeException implements Exception {
  const ChatImageDecodeException();
}

/// Turns a picked photo into the bytes we upload: the camera's rotation
/// applied to the pixels, the long side capped at [chatImageMaxSide], and
/// re-encoded as JPEG (quality 80, lower if needed to stay under
/// [chatImageMaxBytes]) with **no EXIF** — phone photos carry GPS.
///
/// Pure and synchronous so it can run in an isolate (`compute`).
Uint8List prepareChatImage(Uint8List source) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(source);
  } catch (_) {
    // Some decoders throw on garbage instead of returning null.
  }
  if (decoded == null) throw const ChatImageDecodeException();

  // Bake the EXIF orientation into the pixels before the metadata goes.
  var image = img.bakeOrientation(decoded);
  final longSide = image.width > image.height ? image.width : image.height;
  if (longSide > chatImageMaxSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: chatImageMaxSide)
        : img.copyResize(image, height: chatImageMaxSide);
  }
  image.exif = img.ExifData();

  for (final quality in const [80, 70, 60, 50]) {
    final out = img.encodeJpg(image, quality: quality);
    if (out.length <= chatImageMaxBytes) return out;
  }
  // Still too big at quality 50 (very noisy shot): halve and try once more.
  image = img.copyResize(image, width: image.width ~/ 2);
  image.exif = img.ExifData();
  return img.encodeJpg(image, quality: 60);
}
