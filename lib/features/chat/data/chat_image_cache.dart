import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:massdrive/features/chat/data/sources/chat_api_service.dart';
import 'package:massdrive/features/dependency_injection.dart';

/// Chat images on disk, keyed by `file_key` (the signed `media_url` changes
/// and expires after 5 minutes, so it can't be the cache key).
///
/// Order: the cache → the signed `media_url` → `GET /api/media/files/<key>`
/// with the driver's token. Throws when none works; the caller then
/// re-reads the chat for fresh URLs.
class ChatImageCache {
  ChatImageCache({BaseCacheManager? cache, ChatApiService? api})
    : _cacheOverride = cache,
      _apiOverride = api;

  static final ChatImageCache instance = ChatImageCache();

  final BaseCacheManager? _cacheOverride;
  final ChatApiService? _apiOverride;
  BaseCacheManager get _cache => _cacheOverride ?? _defaultCache;
  ChatApiService get _api => _apiOverride ?? getIt<ChatApiService>();

  static final _defaultCache = CacheManager(
    Config(
      'chatImages',
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 300,
    ),
  );

  static String keyFor(String fileKey, String mediaUrl) =>
      fileKey.isNotEmpty ? 'chat:$fileKey' : mediaUrl;

  Future<File> resolve({
    required String fileKey,
    required String mediaUrl,
  }) async {
    final key = keyFor(fileKey, mediaUrl);
    if (key.isEmpty) throw StateError('chat image without file_key or url');

    final hit = await _cache.getFileFromCache(key);
    if (hit != null) return hit.file;

    if (mediaUrl.startsWith('http')) {
      try {
        return (await _cache.downloadFile(mediaUrl, key: key)).file;
      } catch (_) {
        // Expired or unreachable signed URL — try the authenticated route.
      }
    }
    if (fileKey.isEmpty) throw StateError('media_url failed, no file_key');

    final res = await _api.getMediaFile(fileKey);
    final bytes = Uint8List.fromList(res.data ?? const []);
    final type = res.headers.value('content-type') ?? '';
    // Some deployments answer with a JSON link instead of the bytes.
    if (type.contains('json')) {
      final url = (jsonDecode(utf8.decode(bytes)) as Map)['url']?.toString();
      if (url == null || url.isEmpty) throw StateError('no url in response');
      return (await _cache.downloadFile(url, key: key)).file;
    }
    if (bytes.isEmpty) throw StateError('empty image');
    return _cache.putFile(key, bytes, fileExtension: 'jpg');
  }
}
