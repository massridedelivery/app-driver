import 'dart:io';

import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/chat/data/chat_image_cache.dart';
import 'package:massdrive/features/chat/data/chat_image_outbox.dart';
import 'package:massdrive/core/theme/brand_colors.dart';

const _thumbMaxWidth = 220.0;
const _thumbMaxHeight = 260.0;

/// Full-screen photo the driver can pinch to zoom; tap ✕ to close.
void openChatImageViewer(BuildContext context, ImageProvider image) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, _, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(child: Image(image: image)),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 12,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'ปิด',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// An image message from the server: loaded through [ChatImageCache]
/// (cache → signed media_url → authenticated file route). If all fail —
/// usually a media_url older than 5 minutes — [onExpired] re-reads the chat
/// once for a fresh link.
class ChatServerImage extends StatefulWidget {
  const ChatServerImage({
    super.key,
    required this.fileKey,
    required this.mediaUrl,
    this.onExpired,
  });

  final String fileKey;
  final String mediaUrl;
  final Future<void> Function()? onExpired;

  @override
  State<ChatServerImage> createState() => _ChatServerImageState();
}

class _ChatServerImageState extends State<ChatServerImage> {
  late Future<File> _file = _load();
  bool _askedFresh = false;

  Future<File> _load() => ChatImageCache.instance.resolve(
    fileKey: widget.fileKey,
    mediaUrl: widget.mediaUrl,
  );

  @override
  void didUpdateWidget(ChatServerImage old) {
    super.didUpdateWidget(old);
    // A fresh signed link came in with the re-read history.
    if (old.mediaUrl != widget.mediaUrl || old.fileKey != widget.fileKey) {
      setState(() => _file = _load());
    }
  }

  void _retry() {
    _askedFresh = false;
    setState(() => _file = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _file,
      builder: (context, snap) {
        if (snap.hasData) {
          final image = FileImage(snap.data!);
          return GestureDetector(
            onTap: () => openChatImageViewer(context, image),
            child: _Thumb(
              child: Image(image: image, fit: BoxFit.cover),
            ),
          );
        }
        if (snap.hasError) {
          if (!_askedFresh && widget.onExpired != null) {
            _askedFresh = true;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onExpired!(),
            );
          }
          return GestureDetector(
            onTap: _retry,
            child: _Placeholder(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: context.palette.textTertiary,
                    size: 36,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'แตะเพื่อโหลดรูปใหม่',
                    style: AppTypography.caption5.copyWith(
                      color: context.palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return _Placeholder(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.brand.red,
            ),
          ),
        );
      },
    );
  }
}

/// A photo still in [ChatImageOutbox]: the local JPEG with its progress,
/// "waiting for signal", or the error and a retry button.
class ChatPendingImage extends StatelessWidget {
  const ChatPendingImage({
    super.key,
    required this.item,
    required this.onRetry,
    required this.onDiscard,
  });

  final OutboxItem item;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final image = MemoryImage(item.bytes);
    final busy =
        item.status == OutboxStatus.uploading ||
        item.status == OutboxStatus.sending;
    final stuck =
        item.status == OutboxStatus.waiting ||
        item.status == OutboxStatus.failed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => openChatImageViewer(context, image),
          child: _Thumb(
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Image(image: image, fit: BoxFit.cover),
                if (busy || stuck)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: Center(
                        child: busy
                            ? SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  value: item.progress,
                                  strokeWidth: 3,
                                  color: Colors.white,
                                  backgroundColor: Colors.white24,
                                ),
                              )
                            : IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                                tooltip: 'ส่งใหม่',
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  color: context.brand.red,
                                ),
                                onPressed: onRetry,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (item.caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _thumbMaxWidth),
            child: Text(
              item.caption,
              style: AppTypography.body2.copyWith(color: Colors.white),
            ),
          ),
        ],
        if (stuck && item.message != null) ...[
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _thumbMaxWidth),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.status == OutboxStatus.waiting
                      ? Icons.wifi_off_rounded
                      : Icons.error_outline_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    item.message!,
                    style: AppTypography.caption5.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onDiscard,
            child: Text(
              'ยกเลิกรูปนี้',
              style: AppTypography.caption5.copyWith(
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _thumbMaxWidth,
          maxHeight: _thumbMaxHeight,
        ),
        child: child,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
