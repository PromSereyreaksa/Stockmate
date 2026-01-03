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
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          HomeScreen(key: ValueKey('home_$_refreshKey')),
          ProductListScreen(key: ValueKey('products_$_refreshKey')),
          AddProductScreen(
            onProductAdded: () {
              setState(() {
                _currentTab = Tab.items;
              });
              _refreshScreens();
            },
          ),
          AnalyticsScreen(key: ValueKey('analytics_$_refreshKey')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab.index,
        onTap: (index) {
          final previousTab = _currentTab;
          setState(() {
            _currentTab = Tab.values[index];
          });
          
          // Refresh when navigating FROM the Add tab (product was just added)
          if (previousTab == Tab.add && (index == Tab.items.index || index == Tab.home.index)) {
            _refreshScreens();
          }
          
          // Refresh when navigating FROM the Items tab (product might have been edited)
          if (previousTab == Tab.items && (index == Tab.home.index || index == Tab.reports.index)) {
            _refreshScreens();
          }
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
