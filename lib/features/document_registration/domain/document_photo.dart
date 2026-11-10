import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Longest side a document photo is uploaded at: still sharp enough to read
/// a card or a plate, a fraction of a 12 MP camera shot.
const int docPhotoMaxSide = 2000;

/// JPEG quality the picker and [shrinkDocumentPhoto] start from.
const int docPhotoQuality = 80;

/// What a document photo aims to stay under before upload, so it goes up
/// quickly on mobile data (the backend accepts more for `driver_doc`).
const int docPhotoTargetBytes = 2 * 1024 * 1024;

/// Thrown by the upload when the backend refuses the file as too large
/// (POST /api/media/confirm 422 `file_too_large`). [message] is the
/// backend's own Thai text; the driver should take the photo again.
class DocumentFileTooLargeException implements Exception {
  const DocumentFileTooLargeException(this.message);
  final String message;

  // friendlyErrorMessage shows an `Exception: …` text as is.
  @override
  String toString() => 'Exception: $message';
}

/// Whether [bytes] start like a JPEG file.
bool isJpeg(Uint8List bytes) =>
    bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;

/// A photo re-encoded to fit [maxBytes]: the camera's rotation baked in,
/// the long side capped at [docPhotoMaxSide], JPEG from quality
/// [docPhotoQuality] down to 50, then smaller sizes, with no EXIF (phone
/// photos carry GPS). Returns null when [source] isn't a readable image, so
/// the caller keeps the original.
///
/// Pure and synchronous so it can run in an isolate (`compute`).
Uint8List? shrinkDocumentPhoto(({Uint8List source, int maxBytes}) job) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(job.source);
  } catch (_) {
    // Some decoders throw on garbage instead of returning null.
  }
  if (decoded == null) return null;

  var image = img.bakeOrientation(decoded);
  var side = docPhotoMaxSide;
  while (true) {
    final longSide = image.width > image.height ? image.width : image.height;
    if (longSide > side) {
      image = image.width >= image.height
          ? img.copyResize(image, width: side)
          : img.copyResize(image, height: side);
    }
    image.exif = img.ExifData();
    for (final quality in const [docPhotoQuality, 70, 60, 50]) {
      final out = img.encodeJpg(image, quality: quality);
      if (out.length <= job.maxBytes) return out;
    }
    if (side <= 400) return img.encodeJpg(image, quality: 50);
    side = side * 3 ~/ 4;
  }
}
