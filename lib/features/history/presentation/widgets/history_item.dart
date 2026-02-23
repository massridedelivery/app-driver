import 'package:flutter/material.dart';
import 'package:massdrive/features/history/domain/models/history_item_model.dart';

class HistoryItemWidget extends StatelessWidget {
  final HistoryItemModel item;
  final VoidCallback? onTap;

  const HistoryItemWidget({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          children: [
            Text(
              "${item.dateTime.hour}:${item.dateTime.minute}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (item.status == HistoryStatus.cancelled)
              const Text("ยกเลิก", style: TextStyle(color: Colors.red))
            else
              Row(
                children: [
                  Text(
                    "${item.amount}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
