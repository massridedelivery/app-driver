import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/main/controllers/navigation_cubit.dart';
import 'package:massdrive/features/main/screens/named_nav_bar_item_widget.dart';

class MainScreen extends StatelessWidget {
  final Widget screen;

  MainScreen({super.key, required this.screen});

  final tabs = [
    NamedNavigationBarItemWidget(
      initialLocation: AppRoutes.homeNamedPage,
      icon: const Icon(Icons.home_filled),
      label: 'หน้าแรก',
    ),
    NamedNavigationBarItemWidget(
      initialLocation: AppRoutes.incomeNamedPage,
      icon: const Icon(Icons.shopping_bag),
      label: 'รายได้',
    ),
    NamedNavigationBarItemWidget(
      initialLocation: AppRoutes.profileNamedPage,
      icon: const Icon(Icons.person_sharp),
      label: 'โปรไฟล์',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screen,
      bottomNavigationBar: _buildBottomNavigation(context, tabs),
    );
  }
}

BlocBuilder<NavigationCubit, NavigationState> _buildBottomNavigation(
  mContext,
  List<NamedNavigationBarItemWidget> tabs,
) => BlocBuilder<NavigationCubit, NavigationState>(
  buildWhen: (previous, current) => previous.index != current.index,
  builder: (context, state) {
    return BottomNavigationBar(
      onTap: (value) {
        if (state.index != value) {
          context.read<NavigationCubit>().getNavBarItem(value);
          context.go(tabs[value].initialLocation);
        }
      },
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 0,
      backgroundColor: Colors.black,
      unselectedItemColor: Colors.white,
      selectedItemColor: AppColors.foundationOrange600,
      selectedIconTheme: IconThemeData(
        size: ((IconTheme.of(mContext).size)! * 1.2),
      ),
      selectedLabelStyle: AppTypography.caption4.copyWith(
        color: AppColors.semanticGrayNeutralBgWhite,
      ),
      unselectedLabelStyle: AppTypography.caption4.copyWith(
        color: AppColors.semanticGrayNeutralBgWhite,
      ),
      items: tabs,
      currentIndex: state.index,
      type: BottomNavigationBarType.fixed,
    );
  },
);
