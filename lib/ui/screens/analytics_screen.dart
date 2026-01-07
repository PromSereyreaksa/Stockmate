import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/statistics_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../models/product.dart';
import '../../models/statistic.dart';
import '../../models/stock_movement.dart';
import '../widgets/stat_card.dart';
import '../widgets/stock_movement_chart.dart';
import '../widgets/product_card.dart';
import '../widgets/product_filter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final StatisticsRepository _statsRepo = StatisticsRepository();
  final StockRepository _stockRepo = StockRepository();

  Statistics? _statistics;
  StockMovementSummary? _movementSummary;
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedFilter = 'All Items';
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get statistics
      final stats = await _statsRepo.getStatistics();

      // Get stock movement data
      final movements = await _getStockMovements(_selectedDays);

      // Get initial products (all)
      final products = await _productRepo.getAllProducts();

      setState(() {
        _statistics = stats;
        _movementSummary = movements;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<StockMovementSummary> _getStockMovements(int days) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    // Get all products and their stock movements
    final products = await _productRepo.getAllProducts();
    final List<StockMovement> allMovements = [];

    for (var product in products) {
      final history = await _stockRepo.getStockHistory(product.productId);
      allMovements.addAll(history);
    }

    // Use the factory method to create the summary from movements
    return StockMovementSummary.fromMovements(allMovements, startDate, days);
  }

  Future<void> _applyFilter(String filter) async {
    setState(() {
      _selectedFilter = filter;
      _isLoading = true;
    });

    List<Product> products;

    switch (filter) {
      case 'Low Stock':
        products = await _statsRepo.getLowStockProducts();
        break;
      case 'Out of Stock':
        final allProducts = await _productRepo.getAllProducts();
        products = allProducts.where((p) => p.isOutOfStock).toList();
        break;
      case 'Categories':
        products = await _productRepo.getAllProducts();
        // Sort by category
        products.sort((a, b) => a.category.name.compareTo(b.category.name));
        break;
      default: // All Items
        products = await _productRepo.getAllProducts();
    }

    setState(() {
      _filteredProducts = products;
      _isLoading = false;
    });
  }

  Future<void> _changeDateRange(int days) async {
    setState(() => _selectedDays = days);
    final movements = await _getStockMovements(days);
    setState(() => _movementSummary = movements);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Stock Statistics',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading && _statistics == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Statistics Cards Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          StatCard(
                            label: 'Total',
                            value: _statistics?.totalItems.toString() ?? '0',
                            icon: Icons.inventory_2_outlined,
                            iconColor: Colors.blue,
                          ),
                          StatCard(
                            label: 'Low',
                            value: _statistics?.lowStockCount.toString() ?? '0',
                            icon: Icons.warning_amber_rounded,
                            iconColor: Colors.orange,
                          ),
                          StatCard(
                            label: 'Out',
                            value:
                                _statistics?.outOfStockCount.toString() ?? '0',
                            icon: Icons.error_outline,
                            iconColor: Colors.red,
                          ),
                          StatCard(
                            label: 'Value',
                            value:
                                '\$${_statistics?.totalValue.toStringAsFixed(0) ?? '0'}',
                            icon: Icons.attach_money,
                            iconColor: Colors.green,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Filter Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ProductFilter(
                            label: 'All Items',
                            isSelected: _selectedFilter == 'All Items',
                            onTap: () => _applyFilter('All Items'),
                          ),
                          const SizedBox(width: 8),
                          ProductFilter(
                            label: 'Low Stock',
                            isSelected: _selectedFilter == 'Low Stock',
                            onTap: () => _applyFilter('Low Stock'),
                          ),
                          const SizedBox(width: 8),
                          ProductFilter(
                            label: 'Out of Stock',
                            isSelected: _selectedFilter == 'Out of Stock',
                            onTap: () => _applyFilter('Out of Stock'),
                          ),
                          const SizedBox(width: 8),
                          ProductFilter(
                            label: 'Categories',
                            isSelected: _selectedFilter == 'Categories',
                            onTap: () => _applyFilter('Categories'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stock Movement Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Stock Movement',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<int>(
                                  value: _selectedDays,
                                  underline: const SizedBox(),
                                  isDense: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 20,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 7,
                                      child: Text(
                                        'Last 7 days',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 30,
                                      child: Text(
                                        'Last 30 days',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _changeDateRange(value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_movementSummary != null)
                            StockMovementChart(
                              data: _movementSummary!.dailyData,
                              totalIn: _movementSummary!.totalIn,
                              totalOut: _movementSummary!.totalOut,
                            )
                          else
                            const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Filtered Products List
                    if (_filteredProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_selectedFilter (${_filteredProducts.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return ProductCard(product: product);
                        },
                      ),
                    ] else if (!_isLoading) ...[
                      const SizedBox(height: 40),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }
}
