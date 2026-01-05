import 'package:flutter/material.dart';
import 'package:stockmate/ui/screens/product_list_screen.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'add_product_screen.dart';

enum Tab { home, items, add, reports }

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTab.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Tab _currentTab = Tab.home;
  int _refreshKey = 0;

  void _refreshScreens() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentTab = Tab.values[index];
          });
        },
        children: [
          HomeScreen(
            key: ValueKey('home_$_refreshKey'),
            onNavigateToItems: () {
              _pageController.animateToPage(
                Tab.items.index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
          ),
          ProductListScreen(key: ValueKey('products_$_refreshKey')),
          AddProductScreen(
            onProductAdded: () {
              _pageController.animateToPage(
                Tab.items.index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
              _refreshScreens();
            },
          ),
          AnalyticsScreen(key: ValueKey('analytics_$_refreshKey')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab.index,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Items',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
