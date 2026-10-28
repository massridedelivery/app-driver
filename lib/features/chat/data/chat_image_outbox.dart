import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/features/chat/data/sources/chat_api_service.dart';
import 'package:massdrive/features/chat/domain/chat_upload_error.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';
import 'package:massdrive/features/dependency_injection.dart';

enum OutboxStatus {
  /// Getting the upload URL / PUT-ing the file / confirming it.
  uploading,

  /// File stored; posting the chat message.
  sending,

  /// No connection (or the server hiccuped): retried on its own.
  waiting,

  /// Refused (blocked, bad file): needs the driver to tap retry.
  failed,

  /// Posted. Kept until the chat shows the server's copy.
  sent,
}

/// One photo on its way to a chat room.
class OutboxItem {
  OutboxItem({
    required this.localId,
    required this.id,
    required this.vertical,
    required this.bytes,
    required this.caption,
    required this.createdAt,
  });

  final String localId;

  /// Bare job / order / messenger-order id.
  final String id;
  final ChatVertical vertical;

  /// The processed JPEG (resized, no EXIF) — also what the bubble shows.
  final Uint8List bytes;
  final String caption;
  final DateTime createdAt;

  OutboxStatus status = OutboxStatus.uploading;

  /// 0…1 across upload + send.
  double progress = 0;

  /// Set once the file is uploaded and confirmed; a retry then only re-sends
  /// the message.
  String? fileKey;

  /// The chat message id the backend gave back (to drop the local bubble
  /// once the real one is in the list).
  String? serverId;

  /// Thai status/error line under the bubble.
  String? message;
  int attempts = 0;

  String get roomId => vertical.roomId(id);
}

/// App-wide queue for chat photos: they keep uploading (and retry when the
/// connection comes back) even if the driver leaves the chat screen while
/// driving. Everything is in memory — a killed app drops what's queued.
class ChatImageOutbox {
  ChatImageOutbox({
    ChatApiService? api,
    Stream<Object?>? connectivityChanges,
    this.retryDelay = defaultRetryDelay,
  }) : _apiOverride = api {
    _connSub =
        (connectivityChanges ??
                Connectivity().onConnectivityChanged.map<Object?>((r) => r))
            .listen((r) {
              if (r is List<ConnectivityResult> &&
                  r.every((c) => c == ConnectivityResult.none)) {
                return;
              }
              retryWaiting();
            });
  }

  static final ChatImageOutbox instance = ChatImageOutbox();

  final ChatApiService? _apiOverride;
  ChatApiService get _api => _apiOverride ?? getIt<ChatApiService>();

  /// Wait before retry number [attempt] (1-based): 5 s, 10 s, 20 s … ≤ 60 s.
  final Duration Function(int attempt) retryDelay;

  static Duration defaultRetryDelay(int attempt) =>
      Duration(seconds: math.min(60, 5 * (1 << (attempt - 1).clamp(0, 4))));

  late final StreamSubscription<Object?> _connSub;
  final List<OutboxItem> _items = [];
  final Set<String> _running = {};
  final Map<String, Timer> _timers = {};
  final _changes = StreamController<void>.broadcast();
  int _seq = 0;

  /// Fires whenever any item changes.
  Stream<void> get changes => _changes.stream;

  List<OutboxItem> itemsFor(String roomId) =>
      _items.where((i) => i.roomId == roomId).toList();

  /// Queues [bytes] (already processed) for the chat of [id] and starts it.
  OutboxItem enqueue({
    required String id,
    required ChatVertical vertical,
    required Uint8List bytes,
    String caption = '',
  }) {
    final item = OutboxItem(
      localId: 'local-${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
      id: id,
      vertical: vertical,
      bytes: bytes,
      caption: caption,
      createdAt: DateTime.now(),
    );
    _items.add(item);
    _notify();
    unawaited(_run(item));
    return item;
  }

  /// The driver tapped retry on a failed/waiting photo.
  void retry(String localId) {
    final item = _find(localId);
    if (item == null || item.status == OutboxStatus.sent) return;
    _timers.remove(localId)?.cancel();
    unawaited(_run(item));
  }

  /// Retries everything that was waiting for a connection.
  void retryWaiting() {
    for (final i in _items.where((i) => i.status == OutboxStatus.waiting)) {
      retry(i.localId);
    }
  }

  /// Drops a photo the driver no longer wants to send, or one the chat now
  /// shows from the server.
  void remove(String localId) {
    _timers.remove(localId)?.cancel();
    _items.removeWhere((i) => i.localId == localId);
    _notify();
  }

  OutboxItem? _find(String localId) {
    for (final i in _items) {
      if (i.localId == localId) return i;
    }
    return null;
  }

  Future<void> _run(OutboxItem item) async {
    if (!_running.add(item.localId)) return;
    item.attempts++;
    item.message = null;
    try {
      if (item.fileKey == null) {
        item
          ..status = OutboxStatus.uploading
          ..progress = 0.05;
        _notify();
        final presigned = await _api.getPresignedUploadUrl(
          contentType: 'image/jpeg',
          id: item.id,
          vertical: item.vertical,
        );
        final data = presigned.data ?? const {};
        final uploadUrl = data['upload_url']?.toString() ?? '';
        final fileKey = data['file_key']?.toString() ?? '';
        if (uploadUrl.isEmpty || fileKey.isEmpty) {
          throw const ChatUploadRefused();
        }
        await _api.uploadFileToPresignedUrl(
          uploadUrl: uploadUrl,
          fileBytes: item.bytes,
          contentType: 'image/jpeg',
          onSendProgress: (sent, total) {
            if (total <= 0) return;
            item.progress = 0.05 + 0.85 * (sent / total).clamp(0.0, 1.0);
            _notify();
          },
        );
        final confirm = await _api.confirmMediaUpload(fileKey);
        if (confirm.data?['confirmed'] == false) {
          throw const ChatUploadRefused();
        }
        item.fileKey = fileKey;
      }
      item
        ..status = OutboxStatus.sending
        ..progress = 0.95;
      _notify();
      final sent = await _api.sendMessageRest(
        id: item.id,
        vertical: item.vertical,
        msgType: 'image',
        text: item.caption,
        fileKey: item.fileKey,
      );
      item
        ..serverId = _messageId(sent.data)
        ..status = OutboxStatus.sent
        ..progress = 1;
      _notify();
      // Nobody watching this room: let the bubble go after a while.
      _timers[item.localId] = Timer(
        const Duration(seconds: 30),
        () => remove(item.localId),
      );
    } catch (e) {
      final failure = classifyChatUploadError(e);
      if (kDebugMode) debugPrint('ChatImageOutbox: ${item.localId} failed: $e');
      if (failure.reupload) item.fileKey = null;
      item
        ..message = failure.message
        ..status = failure.retryable
            ? OutboxStatus.waiting
            : OutboxStatus.failed;
      if (failure.retryable) {
        _timers[item.localId]?.cancel();
        _timers[item.localId] = Timer(
          retryDelay(item.attempts),
          () => retry(item.localId),
        );
      }
      _notify();
    } finally {
      _running.remove(item.localId);
    }
  }

  static String? _messageId(Map<String, dynamic>? body) {
    if (body == null) return null;
    final inner = body['data'];
    final id = inner is Map ? inner['id'] : body['id'];
    final s = id?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  @visibleForTesting
  Future<void> dispose() async {
    for (final t in _timers.values) {
      t.cancel();
    }
    await _connSub.cancel();
    await _changes.close();
  }
}
