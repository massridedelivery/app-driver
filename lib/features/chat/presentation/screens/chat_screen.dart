import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/chat/domain/entities/chat_message.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';
import 'package:massdrive/features/chat/presentation/controllers/chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String passengerName;
  final ChatVertical vertical;

  const ChatScreen({
    super.key,
    required this.jobId,
    this.passengerName = 'ผู้โดยสาร',
    this.vertical = ChatVertical.ride,
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
      backgroundColor: AppColors.semanticGrayNeutralFgMidOnBlack,
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                ),
                title: Text(
                  'ถ่ายรูปภาพ',
                  style: AppTypography.body2.copyWith(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white,
                ),
                title: Text(
                  'เลือกจากคลังภาพ',
                  style: AppTypography.body2.copyWith(color: Colors.white),
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

    ref.read(chatControllerProvider(widget.jobId, widget.vertical).notifier).sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Scroll to bottom when new messages arrive
    ref.listen<ChatState>(chatControllerProvider(widget.jobId, widget.vertical), (prev, next) {
      if (prev != null && prev.messages.length < next.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      }
    });

    return Scaffold(
      appBar: CommonAppBar(
        titleText: 'แชทกับ ${widget.passengerName}',
        showLeftIcon: true,
      ),
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      body: SafeArea(
        child: Column(
          children: [
            // Connection error notice banner
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
              child: Consumer(
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
                      ? const Center(child: CircularProgressIndicator())
                      : messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            return _MessageBubble(message: msg);
                          },
                        );
                },
              ),
            ),

            // Image uploading overlay indicator
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
                  color: AppColors.foundationAlphaWhite100,
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
                          color: Colors.white70,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            'เริ่มแชทคุยกับลูกค้าเพื่อประสานงานรับส่ง',
            style: AppTypography.caption3.copyWith(color: Colors.white30),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRepliesBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: const BoxDecoration(
        color: AppColors.semanticGrayNeutralFgHigh,
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
                style: AppTypography.caption4.copyWith(color: Colors.black),
              ),
              backgroundColor: AppColors.foundationAlphaWhite100,
              onPressed: () {
                ref
                    .read(chatControllerProvider(widget.jobId, widget.vertical).notifier)
                    .sendMessage(replyText);
                _scrollToBottom();
              },
              side: BorderSide.none,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.semanticGrayNeutralFgMidOnBlack,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Plus/Attachment button
          GestureDetector(
            onTap: _showAttachmentBottomSheet,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.foundationAlphaWhite100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),

          // Message text field
          Expanded(
            child: TextField(
              controller: _messageController,
              style: AppTypography.body2.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'เขียนข้อความ...',
                hintStyle: AppTypography.body2.copyWith(color: Colors.white30),
                filled: true,
                fillColor: AppColors.foundationAlphaWhite100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
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
        : AppColors.foundationAlphaWhite100;
    final textStyle = AppTypography.body2.copyWith(color: Colors.white);
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
              style: AppTypography.caption5.copyWith(color: Colors.white30),
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
          const Icon(Icons.error_outline, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Text(
            'ไม่มีรูปภาพ',
            style: AppTypography.caption4.copyWith(color: Colors.white54),
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
                color: Colors.white12,
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
                color: Colors.white12,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white30,
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
