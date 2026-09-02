import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/chat/domain/entities/chat_message.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';
import 'package:massdrive/features/chat/presentation/controllers/chat_controller.dart';

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
    // Scroll to bottom when keyboard appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (mounted) {
          if (widget.previewMode) {
            setState(() => _previewMessages.add(ChatMessage(
                  id: 'preview-${_previewSeq++}',
                  jobId: widget.jobId,
                  senderId: 'driver',
                  senderType: 'driver',
                  content: '',
                  msgType: 'image',
                  mediaUrl: file.path,
                  createdAt: DateTime.now(),
                )));
            _scrollToBottom();
            return;
          }
          await ref
              .read(chatControllerProvider(widget.jobId, widget.vertical).notifier)
              .sendImage(file);
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: $e')),
        );
      }
    }
  }

  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.palette.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: context.palette.textPrimary,
                ),
                title: Text(
                  'ถ่ายรูปภาพ',
                  style: AppTypography.body2.copyWith(color: context.palette.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: context.palette.textPrimary,
                ),
                title: Text(
                  'เลือกจากคลังภาพ',
                  style: AppTypography.body2.copyWith(color: context.palette.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
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
      ref.listen<ChatState>(chatControllerProvider(widget.jobId, widget.vertical), (prev, next) {
        if (prev != null && prev.messages.length < next.messages.length) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToBottom();
          });
        }
      });
    }

    return Scaffold(
      appBar: CommonAppBar(
        titleText: 'แชทกับ ${widget.passengerName}',
        showLeftIcon: true,
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
                  chatControllerProvider(widget.jobId, widget.vertical).select((s) => s.error),
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
                        final isLoading = ref.watch(
                          chatControllerProvider(
                            widget.jobId, widget.vertical,
                          ).select((s) => s.isLoading),
                        );
                        final messages = ref.watch(
                          chatControllerProvider(
                            widget.jobId, widget.vertical,
                          ).select((s) => s.messages),
                        );

                        return isLoading
                            ? const Center(child: MassLoadingM(size: 72))
                            : _buildMessageList(messages);
                      },
                    ),
            ),

            // Image uploading overlay indicator (no backend in preview mode)
            if (!widget.previewMode)
            Consumer(
              builder: (context, ref, child) {
                final isSending = ref.watch(
                  chatControllerProvider(
                    widget.jobId, widget.vertical,
                  ).select((s) => s.isSending),
                );
                if (!isSending) return const SizedBox.shrink();
                return Container(
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
                        'กำลังอัปโหลดรูปภาพ...',
                        style: AppTypography.caption4.copyWith(
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Quick replies horizontal bar
            _buildQuickRepliesBar(),

            // Chat input bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    if (messages.isEmpty) return _buildEmptyState();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) => _MessageBubble(message: messages[index]),
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
            style: AppTypography.caption3.copyWith(color: context.palette.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRepliesBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Ghost pills: outlined, transparent fill — reads cleanly against the dark
    // background instead of the near-invisible white-10% fill.
    final chipBorder =
        isDark ? Colors.white.withOpacity(0.24) : context.palette.border;
    return Container(
      height: 48,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: context.palette.bg,
      ),
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
                style: AppTypography.caption4.copyWith(color: context.palette.textPrimary),
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
    final fieldFill =
        isDark ? const Color(0xFF2A2D34) : context.palette.surfaceAlt;
    final fieldBorder =
        isDark ? Colors.white.withOpacity(0.10) : context.palette.border;
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
          // Plus/Attachment button
          GestureDetector(
            onTap: _showAttachmentBottomSheet,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: fieldFill,
                shape: BoxShape.circle,
                border: Border.all(color: fieldBorder),
              ),
              child: Icon(Icons.add, color: context.palette.textPrimary, size: 24),
            ),
          ),
          const SizedBox(width: 12),

          // Message text field
          Expanded(
            child: TextField(
              controller: _messageController,
              style: AppTypography.body2.copyWith(color: context.palette.textPrimary),
              decoration: InputDecoration(
                hintText: 'เขียนข้อความ...',
                hintStyle: AppTypography.body2.copyWith(color: context.palette.textTertiary),
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isDriver;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMe
        ? AppColors.foundationOrange700
        : context.palette.surfaceAlt;
    final textStyle = AppTypography.body2.copyWith(color: isMe ? Colors.white : context.palette.textPrimary);
    final timeStr = DateFormat('HH:mm').format(message.createdAt.toLocal());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: alignment,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: message.msgType == 'image'
                      ? _buildImageBubbleContent(context, message.mediaUrl)
                      : Text(message.content, style: textStyle),
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
              style: AppTypography.caption5.copyWith(color: context.palette.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubbleContent(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: context.palette.textTertiary, size: 16),
          const SizedBox(width: 8),
          Text(
            'ไม่มีรูปภาพ',
            style: AppTypography.caption4.copyWith(color: context.palette.textTertiary),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(child: Image.network(imageUrl)),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 250),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 150,
                height: 150,
                color: context.palette.surfaceAlt,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.foundationOrange600,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 150,
                height: 150,
                color: context.palette.surfaceAlt,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: context.palette.textTertiary,
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
