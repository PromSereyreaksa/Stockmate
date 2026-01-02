import 'package:flutter/material.dart';
import '../../data/products_repository.dart';
import '../../models/product.dart';
import '../widgets/summary_card.dart';
import '../widgets/stock_alert_card.dart';
import '../widgets/recent_item_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductsRepository _repository = ProductsRepository();
  
  int _totalItems = 0;
  int _lowStockCount = 0;
  List<Product> _stockAlerts = [];
  List<Product> _recentItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final stats = await _repository.getStatistics();
    final alerts = await _repository.getLowStockProducts();
    final products = await _repository.getAllProducts();
    
    setState(() {
      _totalItems = stats.totalItems;
      _lowStockCount = stats.lowStockCount;
      _stockAlerts = alerts;
      _recentItems = products.take(3).toList();
      _isLoading = false;
    });
  }

  Future<void> _updateStock(Product product, int change) async {
    final newQuantity = (product.currentQuantity + change).clamp(0, 999);
    await _repository.updateStock(product.productId, newQuantity);
    _loadData();
  }

  Future<void> _deleteProduct(Product product) async {
    await _repository.deleteProduct(product.productId);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} deleted'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                      value: _totalItems.toString(),
                      icon: Icons.shopping_bag_outlined,
                      iconColor: Colors.blue,
                      iconBackground: Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      label: 'Low Stock',
                      value: _lowStockCount.toString(),
                      icon: Icons.warning_amber_outlined,
                      iconColor: Colors.orange,
                      iconBackground: Colors.orange.withValues(alpha: 0.1),
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
                    '${_stockAlerts.length} items',
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
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _stockAlerts.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text('No stock alerts'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _stockAlerts.length,
                        itemBuilder: (context, index) {
                          final product = _stockAlerts[index];
                          return StockAlertCard(
                            product: product,
                            onTap: () {},
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
                      // Navigate to products tab in main navigation
                      final mainNav = context.findAncestorStateOfType<State>();
                      if (mainNav != null && mainNav.mounted) {
                        // Access parent MainNavigation to switch tab
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Recent Items List
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _recentItems.length,
                    itemBuilder: (context, index) {
                      final product = _recentItems[index];
                      return Dismissible(
                        key: Key(product.productId),
                        direction: DismissDirection.startToEnd,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Product'),
                              content: Text('Are you sure you want to delete ${product.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          _deleteProduct(product);
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          child: const Row(
                            children: [
                              Icon(Icons.delete, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        child: RecentItemCard(
                          product: product,
                          onDecrement: () => _updateStock(product, -1),
                          onIncrement: () => _updateStock(product, 1),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
