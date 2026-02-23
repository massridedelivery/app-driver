import 'package:flutter/material.dart';
import 'package:massdrive/common/widgets/tappable.dart';

class Expandable extends StatefulWidget {
  /// The widget that is always visible and can be tapped.
  final Widget header;

  /// The widget that will be expanded or collapsed.
  final Widget body;

  /// Whether the body is expanded by default.
  final bool isInitiallyExpanded;

  const Expandable({
    required this.header,
    required this.body,
    this.isInitiallyExpanded = false,
    super.key,
  });

  @override
  State<Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<Expandable> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // This makes the Column only as tall as its children
      mainAxisSize: MainAxisSize.min,
      // This makes the children fill the width
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The Header
        Tappable(
          onTap: _toggleExpand,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                // Use Expanded so the header takes all available space
                Expanded(child: widget.header),
                // The Animated Arrow
                AnimatedRotation(
                  turns: _isExpanded
                      ? 0.5
                      : 0.0, // 0.0 = down, 0.5 = 180deg (up)
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.expand_more),
                ),
              ],
            ),
          ),
        ),

        // The Animated Body
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          // This prevents content from overflowing during the animation
          clipBehavior: Clip.hardEdge,
          child: _isExpanded
              ? widget.body
              : const SizedBox.shrink(), // Shows nothing when collapsed
        ),
      ],
    );
  }
}
