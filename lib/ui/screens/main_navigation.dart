import 'package:flutter/material.dart';
// import 'package:stockmate/ui/screens/product_list_screen.dart';
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
  Tab _currentTab = Tab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          HomeScreen(),
          Placeholder(),
          AddProductScreen(),
          AnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab.index,
        onTap: (index) {
          setState(() {
            _currentTab = Tab.values[index];
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
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
