import 'package:flutter/material.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/statistics_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../models/product.dart';
import '../widgets/stock_alert_card.dart';
import '../widgets/recent_item_card.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToItems;

  const HomeScreen({super.key, this.onNavigateToItems});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final StatisticsRepository _statsRepo = StatisticsRepository();
  final StockRepository _stockRepo = StockRepository();

  int _totalItems = 0;
  int _lowStockCount = 0;
  int _nearlyExpiredCount = 0;
  int _expiredCount = 0;
  List<Product> _stockAlerts = [];
  List<Product> _nearlyExpiredProducts = [];
  List<Product> _recentItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stats = await _statsRepo.getStatistics();
    final alerts = await _statsRepo.getLowStockProducts();
    final nearlyExpired = await _statsRepo.getNearlyExpiredProducts();
    final expired = await _statsRepo.getExpiredProducts();
    final products = await _productRepo.getAllProducts();

    setState(() {
      _totalItems = stats.totalItems;
      _lowStockCount = stats.lowStockCount;
      _nearlyExpiredCount = nearlyExpired.length;
      _expiredCount = expired.length;
      _stockAlerts = alerts;
      _nearlyExpiredProducts = nearlyExpired;
      _recentItems = products.take(3).toList();
      _isLoading = false;
    });
  }

  Future<void> _updateStock(Product product, int change) async {
    final newQuantity = (product.currentQuantity + change).clamp(0, 999);
    await _stockRepo.updateStock(product.productId, newQuantity);
    _loadData();
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
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Summary Cards Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total Items',
                          value: _totalItems.toString(),
                          icon: Icons.shopping_bag_outlined,
                          iconColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Low Stock',
                          value: _lowStockCount.toString(),
                          icon: Icons.warning_amber_outlined,
                          iconColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Almost Expired',
                          value: _nearlyExpiredCount.toString(),
                          icon: Icons.event_busy_outlined,
                          iconColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Expired',
                          value: _expiredCount.toString(),
                          icon: Icons.cancel_outlined,
                          iconColor: Colors.red,
                        ),
                      ),
                    ],
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
                    style: TextStyle(fontSize: 14, color: Colors.black54),
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
                    child: Center(child: Text('No stock alerts')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _stockAlerts.length,
                    itemBuilder: (context, index) {
                      final product = _stockAlerts[index];
                      return StockAlertCard(product: product, onTap: () {});
                    },
                  ),

            const SizedBox(height: 24),

            // Nearly Expired Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nearly Expired (Cases)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${_nearlyExpiredProducts.length} items',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Nearly Expired Products List
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _nearlyExpiredProducts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(child: Text('No nearly expired products')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _nearlyExpiredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _nearlyExpiredProducts[index];
                      return StockAlertCard(product: product, onTap: () {});
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
                    onPressed: widget.onNavigateToItems,
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
                      return RecentItemCard(
                        product: product,
                        onDecrement: () => _updateStock(product, -1),
                        onIncrement: () => _updateStock(product, 1),
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
