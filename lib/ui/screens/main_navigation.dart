import 'package:flutter/material.dart';
import '../navigation/stock_tab.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  StockTab _currentTab = StockTab.home;

  final _tabs = [
    const HomeScreen(),
    const AnalyticsScreen(),
    const SizedBox(), // placeholder for Add
    const AnalyticsScreen(), // placeholder for Reports
  ];

  void _onTabSelected(int index) {
    final selectedTab = StockTab.values[index];

    if (selectedTab == StockTab.add) {
      // TODO: Implement add product navigation
      return;
    }

    setState(() {
      _currentTab = selectedTab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab.index,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Items'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}
