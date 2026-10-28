import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/chat/data/chat_image_outbox.dart';
import 'package:massdrive/features/chat/domain/chat_image_processing.dart';
import 'package:massdrive/features/chat/domain/entities/chat_message.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';
import 'package:massdrive/features/chat/domain/repositories/chat_repository.dart';
import 'package:massdrive/features/chat/presentation/controllers/chat_controller.dart';
import 'package:massdrive/features/chat/presentation/screens/chat_image_preview_screen.dart';
import 'package:massdrive/features/chat/presentation/widgets/chat_image_widgets.dart';
import 'package:massdrive/features/dependency_injection.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String passengerName;
  final ChatVertical vertical;

  /// UI-preview mode (dev/QA entry): render sample messages locally and echo
  /// sends into the list without touching the socket/REST backend. Lets the
  /// chat UI be checked on-device without a live job.
  final bool previewMode;

  const ChatScreen({
    super.key,
    required this.jobId,
    this.passengerName = 'ผู้โดยสาร',
    this.vertical = ChatVertical.ride,
    this.previewMode = false,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final List<String> _quickReplies = [
    'ฉันมาถึงจุดรับแล้วครับ',
    'กำลังเดินทางไปรับครับ',
    'รถติดเล็กน้อยนะครับ',
    'ได้รับออเดอร์แล้วครับ กำลังเดินทางไปส่ง',
  ];

  /// Local sample thread shown in preview mode (no backend).
  late final List<ChatMessage> _previewMessages = [
    _previewMsg('สวัสดีครับ กำลังไปรับเลยนะครับ', driver: true),
    _previewMsg('รับทราบค่ะ รออยู่หน้าปากซอยนะคะ', driver: false),
    _previewMsg('ถึงแล้วครับ รถสีขาว ป้ายแดง', driver: true),
  ];

  int _previewSeq = 0;

  /// The counterpart is blocked in this conversation (per-job, stored locally).
  /// Blocking hides their messages and disables sending. Report/Block satisfy
  /// the App Store's UGC safety requirement for the 1:1 job chat.
  bool _blocked = false;
  String get _blockKey => 'chat_blocked_${widget.jobId}';

  Future<void> _loadBlocked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) setState(() => _blocked = prefs.getBool(_blockKey) ?? false);
    } catch (_) {
      /* default: not blocked */
    }
  }

  Future<void> _setBlocked(bool value) async {
    setState(() => _blocked = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_blockKey, value);
    } catch (_) {}
    // Persist to backend (best-effort). Local prefs above stay the fallback so
    // block still works on-device if the endpoint isn't up yet.
    if (!widget.previewMode) {
      unawaited(
        getIt<ChatRepository>().setBlock(widget.jobId, widget.vertical, value),
      );
    }
  }

  ChatMessage _previewMsg(String text, {required bool driver}) => ChatMessage(
    id: 'preview-${_previewSeq++}',
    jobId: widget.jobId,
    senderId: driver ? 'driver' : 'customer',
    senderType: driver ? 'driver' : 'customer',
    content: text,
    msgType: 'text',
    mediaUrl: '',
    createdAt: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _loadBlocked();
    // Scroll to bottom when keyboard appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  /// Overflow menu (⋮) — report or block the customer in this job chat.
  Widget _buildChatMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: context.palette.textPrimary),
      onSelected: (v) {
        if (v == 'report') _reportUser();
        if (v == 'block') _confirmBlock();
        if (v == 'unblock') _setBlocked(false);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 20),
              SizedBox(width: 12),
              Text('รายงานผู้ใช้'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _blocked ? 'unblock' : 'block',
          child: Row(
            children: [
              Icon(_blocked ? Icons.lock_open_outlined : Icons.block, size: 20),
              const SizedBox(width: 12),
              Text(_blocked ? 'เลิกบล็อกผู้ใช้' : 'บล็อกผู้ใช้'),
            ],
          ),
        ),
      ],
    );
  }

  /// Report the counterpart — pick a reason, then submit. (Routed to support
  /// until a dedicated report endpoint ships — see SCRUM ticket.)
  void _reportUser() {
    const reasons = [
      'ข้อความไม่เหมาะสม / คุกคาม',
      'สแปมหรือหลอกลวง',
      'พฤติกรรมไม่ปลอดภัย',
      'อื่นๆ',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'รายงานผู้ใช้',
                style: AppTypography.heading6.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
            ),
            for (final r in reasons)
              ListTile(
                title: Text(
                  r,
                  style: AppTypography.body2.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _submitReport(r);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(String reason) async {
    // Send to the backend (SCRUM-107). We always acknowledge to the user — the
    // reporting mechanism is available even if the endpoint isn't up yet.
    bool ok = true;
    if (!widget.previewMode) {
      ok = await getIt<ChatRepository>().reportChat(
        widget.jobId,
        widget.vertical,
        reason,
      );
    }
    if (!ok) {
      debugPrint(
        'Chat report not persisted (endpoint pending?) reason=$reason',
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('รายงานแล้ว: "$reason" — ทีมงานจะตรวจสอบโดยเร็ว'),
          backgroundColor: AppColors.semanticSuccessBgHigh,
        ),
      );
    }
  }

  void _confirmBlock() {
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: context.palette.sheet,
        title: Text(
          'บล็อกผู้ใช้นี้?',
          style: AppTypography.heading6.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        content: Text(
          'เมื่อบล็อก คุณจะไม่เห็นข้อความจากผู้ใช้นี้ และส่งข้อความไม่ได้ '
          'จนกว่าจะเลิกบล็อก',
          style: AppTypography.body2.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text(
              'ยกเลิก',
              style: AppTypography.label2.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              _setBlocked(true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บล็อกผู้ใช้แล้ว')),
                );
              }
            },
            child: Text(
              'บล็อก',
              style: AppTypography.label2.copyWith(
                color: AppColors.semanticErrorFgHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _preparing = false;

  /// Camera (the default — the pickup point, the parcel) or the gallery →
  /// resize to ≤1600 px and re-encode JPEG without EXIF (GPS) off the UI
  /// thread → preview with an optional caption → queue it. The photo shows
  /// as a bubble right away and keeps uploading if the driver leaves.
  Future<void> _pickImage(ImageSource source) async {
    if (_preparing) return;
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        // Native downscale first so decoding here stays cheap.
        maxWidth: chatImageMaxSide.toDouble(),
        maxHeight: chatImageMaxSide.toDouble(),
        imageQuality: 95,
        requestFullMetadata: false,
      );
    } catch (e) {
      _snack(
        source == ImageSource.camera
            ? 'เปิดกล้องไม่ได้ กรุณาอนุญาตการใช้กล้องในการตั้งค่า'
            : 'เปิดคลังภาพไม่ได้ กรุณาอนุญาตการเข้าถึงรูปภาพในการตั้งค่า',
      );
      return;
    }
    if (picked == null || !mounted) return;

    setState(() => _preparing = true);
    Uint8List jpeg;
    try {
      jpeg = await compute(prepareChatImage, await picked.readAsBytes());
    } catch (_) {
      if (mounted) setState(() => _preparing = false);
      _snack('ไฟล์รูปไม่ถูกต้อง กรุณาเลือกรูปอื่น');
      return;
    }
    if (!mounted) return;
    setState(() => _preparing = false);

    final caption = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ChatImagePreviewScreen(jpeg: jpeg)),
    );
    if (caption == null || !mounted) return;

    if (widget.previewMode) {
      setState(() => _previewImages.add(jpeg));
      _scrollToBottom();
      return;
    }
    ref
        .read(chatControllerProvider(widget.jobId, widget.vertical).notifier)
        .sendImage(jpeg, caption: caption);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  /// Photos "sent" in preview mode (no backend): shown as local bubbles.
  final List<Uint8List> _previewImages = [];

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _sendText(text);
    _messageController.clear();
  }

  void _sendText(String text) {
    if (widget.previewMode) {
      setState(() => _previewMessages.add(_previewMsg(text, driver: true)));
      _scrollToBottom();
      return;
    }
    ref
        .read(chatControllerProvider(widget.jobId, widget.vertical).notifier)
        .sendMessage(text);
    _scrollToBottom();
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Scroll to bottom when new messages arrive (skipped in preview — no backend).
    if (!widget.previewMode) {
      ref.listen<ChatState>(
        chatControllerProvider(widget.jobId, widget.vertical),
        (prev, next) {
          if (prev != null && prev.messages.length < next.messages.length) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _scrollToBottom();
            });
          }
        },
      );
    }

    return Scaffold(
      appBar: CommonAppBar(
        titleText: 'แชทกับ ${widget.passengerName}',
        showLeftIcon: true,
        rightWidgets: [_buildChatMenu()],
      ),
      backgroundColor: context.palette.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Connection error notice banner (no backend in preview mode)
            if (!widget.previewMode)
              Consumer(
                builder: (context, ref, child) {
                  final error = ref.watch(
                    chatControllerProvider(
                      widget.jobId,
                      widget.vertical,
                    ).select((s) => s.error),
                  );
                  if (error == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    color: AppColors.semanticErrorBgHigh.withOpacity(0.2),
                    child: Text(
                      'การเชื่อมต่อมีปัญหา: $error',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticErrorFgHigh,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),

            // Messages List Area
            Expanded(
              child: widget.previewMode
                  ? _buildMessageList(_previewMessages)
                  : Consumer(
                      builder: (context, ref, child) {
                        final chat = ref.watch(
                          chatControllerProvider(widget.jobId, widget.vertical),
                        );
                        return chat.isLoading && chat.pending.isEmpty
                            ? const Center(child: MassLoadingM(size: 72))
                            : _buildMessageList(chat.messages, chat.pending);
                      },
                    ),
            ),

            // Resizing / stripping the picked photo before its preview.
            if (_preparing)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: context.palette.surfaceAlt,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.foundationOrange600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'กำลังเตรียมรูปภาพ...',
                      style: AppTypography.caption4.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

            // When blocked, hide the composer entirely and show an unblock bar
            // instead of quick replies + input.
            if (_blocked)
              _buildBlockedBar()
            else ...[
              // Quick replies horizontal bar
              _buildQuickRepliesBar(),

              // Chat input bar
              _buildInputBar(),
            ],
          ],
        ),
      ),
    );
  }

  /// Shown in place of the composer while the counterpart is blocked.
  Widget _buildBlockedBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(
          top: BorderSide(color: context.palette.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.block, size: 18, color: context.palette.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'คุณบล็อกผู้ใช้นี้แล้ว',
              style: AppTypography.caption4.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _setBlocked(false),
            child: Text(
              'เลิกบล็อก',
              style: AppTypography.label2.copyWith(
                color: AppColors.semanticSuccessBgHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    List<ChatMessage> messages, [
    List<OutboxItem> pending = const [],
  ]) {
    // While blocked, hide the counterpart's messages (keep the driver's own).
    final shown = _blocked
        ? messages.where((m) => m.isDriver).toList()
        : messages;
    final local = widget.previewMode ? _previewImages : const <Uint8List>[];
    final count = shown.length + pending.length + local.length;
    if (count == 0) return _buildEmptyState();
    final controller = widget.previewMode
        ? null
        : ref.read(
            chatControllerProvider(widget.jobId, widget.vertical).notifier,
          );
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (context, index) {
        if (index < shown.length) {
          return _MessageBubble(
            message: shown[index],
            onImageExpired: controller?.refreshMediaUrls,
          );
        }
        final i = index - shown.length;
        if (i < pending.length) {
          final item = pending[i];
          return _BubbleFrame(
            isMe: true,
            time: item.createdAt,
            padding: const EdgeInsets.all(6),
            child: ChatPendingImage(
              item: item,
              onRetry: () => controller?.retryImage(item.localId),
              onDiscard: () => controller?.discardImage(item.localId),
            ),
          );
        }
        final bytes = local[i - pending.length];
        return _BubbleFrame(
          isMe: true,
          time: DateTime.now(),
          padding: const EdgeInsets.all(6),
          child: GestureDetector(
            onTap: () => openChatImageViewer(context, MemoryImage(bytes)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 220,
                  maxHeight: 260,
                ),
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: context.palette.border,
          ),
          const SizedBox(height: 16),
          Text(
            'เริ่มแชทคุยกับลูกค้าเพื่อประสานงานรับส่ง',
            style: AppTypography.caption3.copyWith(
              color: context.palette.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRepliesBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Ghost pills: outlined, transparent fill — reads cleanly against the dark
    // background instead of the near-invisible white-10% fill.
    final chipBorder = isDark
        ? Colors.white.withOpacity(0.24)
        : context.palette.border;
    return Container(
      height: 48,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(color: context.palette.bg),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickReplies.length,
        itemBuilder: (context, index) {
          final replyText = _quickReplies[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                replyText,
                style: AppTypography.caption4.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              backgroundColor: Colors.transparent,
              onPressed: () => _sendText(replyText),
              side: BorderSide(color: chipBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Ghost input: a solid, slightly-elevated fill with a hairline border so the
    // field and "+" button stand off the background (the old white-10% fill was
    // barely visible). Bar itself matches the screen bg (bg + top hairline).
    final fieldFill = isDark
        ? const Color(0xFF2A2D34)
        : context.palette.surfaceAlt;
    final fieldBorder = isDark
        ? Colors.white.withOpacity(0.10)
        : context.palette.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.bg,
        border: Border(
          top: BorderSide(color: context.palette.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Camera is the default attachment (the pickup point, the parcel);
          // the gallery sits next to it.
          _attachButton(
            icon: Icons.photo_camera_outlined,
            tooltip: 'ถ่ายรูป',
            fill: fieldFill,
            border: fieldBorder,
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(width: 8),
          _attachButton(
            icon: Icons.photo_library_outlined,
            tooltip: 'เลือกจากคลังภาพ',
            fill: fieldFill,
            border: fieldBorder,
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(width: 10),

          // Message text field
          Expanded(
            child: TextField(
              controller: _messageController,
              style: AppTypography.body2.copyWith(
                color: context.palette.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'เขียนข้อความ...',
                hintStyle: AppTypography.body2.copyWith(
                  color: context.palette.textTertiary,
                ),
                filled: true,
                fillColor: fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),

          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.foundationOrange700,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on _ChatScreenState {
  Widget _attachButton({
    required IconData icon,
    required String tooltip,
    required Color fill,
    required Color border,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: _preparing ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          child: Icon(icon, color: context.palette.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  /// Re-reads the chat for fresh signed media URLs (they last 5 minutes).
  final Future<void> Function()? onImageExpired;

  const _MessageBubble({required this.message, this.onImageExpired});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isDriver;
    final textStyle = AppTypography.body2.copyWith(
      color: isMe ? Colors.white : context.palette.textPrimary,
    );
    if (message.msgType != 'image') {
      return _BubbleFrame(
        isMe: isMe,
        time: message.createdAt,
        child: Text(message.content, style: textStyle),
      );
    }
    return _BubbleFrame(
      isMe: isMe,
      time: message.createdAt,
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.mediaUrl.isEmpty && message.fileKey.isEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: context.palette.textTertiary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'ไม่มีรูปภาพ',
                  style: AppTypography.caption4.copyWith(
                    color: context.palette.textTertiary,
                  ),
                ),
              ],
            )
          else
            ChatServerImage(
              fileKey: message.fileKey,
              mediaUrl: message.mediaUrl,
              onExpired: onImageExpired,
            ),
          if (message.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(message.content, style: textStyle),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A chat bubble (driver orange on the right, customer on the left with an
/// avatar) and its time underneath.
class _BubbleFrame extends StatelessWidget {
  const _BubbleFrame({
    required this.isMe,
    required this.time,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final bool isMe;
  final DateTime time;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? AppColors.foundationOrange700
        : context.palette.surfaceAlt;
    final timeStr = DateFormat('HH:mm').format(time.toLocal());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.foundationOrange700,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : Radius.zero,
                      bottomRight: isMe
                          ? Radius.zero
                          : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
              if (isMe) const SizedBox(width: 8),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 44,
              right: isMe ? 4 : 0,
              top: 4,
            ),
            child: Text(
              timeStr,
              style: AppTypography.caption5.copyWith(
                color: context.palette.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
