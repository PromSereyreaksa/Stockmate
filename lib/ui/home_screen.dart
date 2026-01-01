import 'package:flutter/material.dart';
import '../data/mock_data_source.dart';
import '../models/product.dart';
import '../models/stock_summary.dart';
import 'widgets/summary_card.dart';
import 'widgets/stock_alert_card.dart';
import 'widgets/recent_item_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StockSummary summary;
  late List<Product> stockAlerts;
  late List<Product> recentItems;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    summary = MockDataSource.getStockSummary();
    stockAlerts = MockDataSource.getStockAlerts();
    recentItems = MockDataSource.getRecentItems();
  }

  void _onNavigationTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Navigate to other screens when implemented
  }

  void _updateStock(Product product, int change) {
    setState(() {
      // Update the stock in the data source
      final newStock = (product.stock + change).clamp(0, 999);
      // In a real app, this would update the database
      // For now, just refresh the data
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with App Info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.show_chart,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'StockMate',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Stock Management System',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Summary Cards Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: 'Total Items',
                      value: summary.totalItems.toString(),
                      icon: Icons.shopping_bag_outlined,
                      iconColor: Colors.blue,
                      iconBackground: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      label: 'Low Stock',
                      value: summary.lowStockCount.toString(),
                      icon: Icons.warning_amber_outlined,
                      iconColor: Colors.orange,
                      iconBackground: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stock Alerts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stock Alerts (Cases)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${stockAlerts.length} items',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Stock Alerts List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stockAlerts.length,
              itemBuilder: (context, index) {
                final product = stockAlerts[index];
                return StockAlertCard(
                  product: product,
                  onTap: () {
                    // TODO: Navigate to product details
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Recent Items Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all items
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Recent Items List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recentItems.length,
              itemBuilder: (context, index) {
                final product = recentItems[index];
                return RecentItemCard(
                  product: product,
                  onDecrement: () => _updateStock(product, -1),
                  onIncrement: () => _updateStock(product, 1),
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavigationTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
