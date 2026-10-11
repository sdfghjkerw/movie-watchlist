import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';
import 'reviews_screen.dart';
import 'profile_screen.dart';
import '../localization/app_strings.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const SearchScreen(),
      const WatchlistScreen(),
      const ReviewsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Главная'.tr(context),
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Поиск'.tr(context),
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined),
            selectedIcon: Icon(Icons.bookmarks_rounded),
            label: 'Коллекция'.tr(context),
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'Отзывы'.tr(context),
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Профиль'.tr(context),
          ),
        ],
      ),
    );
  }
}
