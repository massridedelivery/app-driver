import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/features/income/presentation/screens/widgets/parallax_card.dart';

class EarningsSection extends StatefulWidget {
  final double earningsToday;
  final double earningsWeek;

  const EarningsSection({
    super.key,
    this.earningsToday = 10.0,
    this.earningsWeek = 20.0,
  });

  @override
  State<EarningsSection> createState() => _EarningsSectionState();
}

class _EarningsSectionState extends State<EarningsSection> {
  late final PageController _controller;

  List<Map<String, double>> get items => [
    {"today": widget.earningsToday, "week": widget.earningsWeek},
    {"today": 0.0, "week": 0.0}, // placeholder second card
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88, initialPage: 0);
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
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final currentPage = _controller.hasClients ? (_controller.page ?? 0.0) : 0.0;
              return PageView.builder(
                controller: _controller,
                padEnds: false,
                itemCount: items.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final offset = currentPage - index;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ParallaxCard(
                      today: items[index]["today"]!,
                      week: items[index]["week"]!,
                      offset: offset,
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final currentPageRound = _controller.hasClients ? (_controller.page ?? 0.0).round() : 0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (index) {
                final isActive = currentPageRound == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isActive ? 20 : 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.foundationOrange600
                        : AppColors.semanticGrayNeutralFgMidOnWhite,
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
