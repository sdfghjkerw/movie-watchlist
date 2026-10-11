import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';

/// Shared responsive shell for the five persistent navigation branches.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (Icons.home_outlined, Icons.home_rounded, 'Главная'),
    (Icons.search_rounded, Icons.search_rounded, 'Поиск'),
    (Icons.bookmarks_outlined, Icons.bookmarks_rounded, 'Коллекция'),
    (Icons.rate_review_outlined, Icons.rate_review, 'Отзывы'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;
    final destinations = [
      for (final item in _destinations)
        NavigationRailDestination(
          icon: Icon(item.$1),
          selectedIcon: Icon(item.$2),
          label: Text(item.$3.tr(context)),
        ),
    ];

    void selectBranch(int index) => navigationShell.goBranch(
      index,
      initialLocation: index == selectedIndex,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: selectBranch,
                    labelType: NavigationRailLabelType.all,
                    destinations: destinations,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: selectBranch,
            destinations: [
              for (final item in _destinations)
                NavigationDestination(
                  icon: Icon(item.$1),
                  selectedIcon: Icon(item.$2),
                  label: item.$3.tr(context),
                ),
            ],
          ),
        );
      },
    );
  }
}
