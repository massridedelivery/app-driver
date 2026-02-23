import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  const DateSelector();

  @override
  Widget build(BuildContext context) {
    final days = ["23", "24", "25", "26", "27", "28", "29"];

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final isSelected = days[index] == "25";

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Text(
                  days[index],
                  style: TextStyle(
                    color: isSelected ? Colors.green : Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                if (isSelected)
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      "25",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
