enum MediaPrivacy { public, private }

enum MediaCategory {
  avatar(
    purpose: 'avatar',
    description: 'User profile picture',
    privacy: MediaPrivacy.public,
    maxSizeBytes: 2 * 1024 * 1024, // 2 MB
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
  ),
  driverDoc(
    purpose: 'driver_doc',
    description: 'Verification documents',
    privacy: MediaPrivacy.private,
    maxSizeBytes: 5 * 1024 * 1024, // 5 MB
    allowedMimeTypes: ['image/jpeg', 'image/png', 'application/pdf'],
  ),
  chat(
    purpose: 'chat',
    description: 'In-app messaging',
    privacy: MediaPrivacy.private,
    maxSizeBytes: 2 * 1024 * 1024, // 2 MB
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
  ),
  menu(
    purpose: 'menu',
    description: 'Food item images',
    privacy: MediaPrivacy.public,
    maxSizeBytes: 3 * 1024 * 1024, // 3 MB
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
  ),
  restaurant(
    purpose: 'restaurant',
    description: 'Shop branding/logo',
    privacy: MediaPrivacy.public,
    maxSizeBytes: 3 * 1024 * 1024, // 3 MB
    allowedMimeTypes: ['image/jpeg', 'image/png'],
  ),
  restaurantDoc(
    purpose: 'restaurant_doc',
    description: 'Business verification',
    privacy: MediaPrivacy.private,
    maxSizeBytes: 5 * 1024 * 1024, // 5 MB
    allowedMimeTypes: ['image/jpeg', 'image/png', 'application/pdf'],
  );

  const MediaCategory({
    required this.purpose,
    required this.description,
    required this.privacy,
    required this.maxSizeBytes,
    required this.allowedMimeTypes,
  });

  /// The string value sent to the API as the `purpose` field.
  final String purpose;

  /// Human-readable description of this category.
  final String description;

  /// Whether files in this category are publicly accessible or private.
  final MediaPrivacy privacy;

  /// Maximum allowed file size in bytes.
  final int maxSizeBytes;

  /// List of accepted MIME types for this category.
  final List<String> allowedMimeTypes;

  /// Whether this category stores private (pre-signed URL) files.
  bool get isPrivate => privacy == MediaPrivacy.private;

  /// Max size formatted as a readable string (e.g. "5 MB").
  String get maxSizeLabel => '${maxSizeBytes ~/ (1024 * 1024)} MB';

  /// Returns true if [mimeType] is allowed for this category.
  bool isMimeTypeAllowed(String mimeType) =>
      allowedMimeTypes.contains(mimeType);

  /// Find a [MediaCategory] by its API purpose string.
  static MediaCategory? fromPurpose(String purpose) {
    for (final category in MediaCategory.values) {
      if (category.purpose == purpose) return category;
    }
    return null;
  }
}
