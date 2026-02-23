import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/features/income/presentation/screens/widgets/parallax_card.dart';

class EarningsSection extends StatefulWidget {
  const EarningsSection({super.key});

  @override
  State<EarningsSection> createState() => _EarningsSectionState();
}

class _EarningsSectionState extends State<EarningsSection> {
  late final PageController _controller;
  double currentPage = 0;

  final items = const [
    {"today": 0.0, "week": 0.0},
    {"today": 1200.0, "week": 5400.0},
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88, initialPage: 0);
    _controller.addListener(() {
      setState(() {
        currentPage = _controller.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final offset = currentPage - index;

              return Padding(
                padding: const EdgeInsets.only(right: 12), // 👈 เว้นแค่ขวา
                child: ParallaxCard(
                  today: items[index]["today"]!,
                  week: items[index]["week"]!,
                  offset: offset,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            final isActive = currentPage.round() == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isActive ? 20 : 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors
                          .foundationOrange600 //
                    : AppColors.semanticGrayNeutralFgMidOnWhite,
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }
}
