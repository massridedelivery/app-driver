import 'package:flutter/material.dart';

class HistoryToggle extends StatelessWidget {
  final bool isDaily;
  final ValueChanged<bool> onChanged;

  const HistoryToggle({required this.isDaily, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDaily ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("รายวัน"),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => onChanged(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: !isDaily ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("รายสัปดาห์"),
            ),
          ),
        ],
      ),
    );
  }
}
