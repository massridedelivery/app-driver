import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/brand_colors.dart';

/// The photo about to be sent, with an optional caption. Pops the caption
/// ('' when none) to send, or null when the driver backs out.
class ChatImagePreviewScreen extends StatefulWidget {
  const ChatImagePreviewScreen({super.key, required this.jpeg});

  final Uint8List jpeg;

  @override
  State<ChatImagePreviewScreen> createState() => _ChatImagePreviewScreenState();
}

class _ChatImagePreviewScreenState extends State<ChatImagePreviewScreen> {
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _send() => Navigator.of(context).pop(_caption.text.trim());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'ส่งรูปภาพ',
          style: AppTypography.heading6.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(child: Image.memory(widget.jpeg)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caption,
                      maxLength: 200,
                      style: AppTypography.body2.copyWith(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'เพิ่มคำบรรยาย (ไม่บังคับ)',
                        hintStyle: AppTypography.body2.copyWith(
                          color: Colors.white54,
                        ),
                        filled: true,
                        fillColor: BrandColors.dark.fill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: BrandColors.dark.red,
                    ),
                    tooltip: 'ส่ง',
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
