import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/data/products_repository.dart';
import '/models/product.dart';
import '/models/statistic.dart';
import '../widgets/stat_card.dart';
import '../widgets/stock_movement_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ProductsRepository _repository = ProductsRepository();

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
      final stats = await _repository.getStatistics();

      // Get stock movement data
      final movements = await _getStockMovements(_selectedDays);

      // Get initial products (all)
      final products = await _repository.getAllProducts();

      setState(() {
        _statistics = stats;
        _movementSummary = movements;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<StockMovementSummary> _getStockMovements(int days) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    // Get all products to access stock movements
    Map<String, int> dailyIn = {};
    Map<String, int> dailyOut = {};

    // Initialize dates
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      dailyIn[dateKey] = 0;
      dailyOut[dateKey] = 0;
    }

    // Get all products and their history
    final products = await _repository.getAllProducts();
    int totalIn = 0;
    int totalOut = 0;

    for (var product in products) {
      final history = await _repository.getStockHistory(product.productId);
      for (var movement in history) {
        final timestamp = DateTime.parse(movement['timestamp']);
        if (timestamp.isAfter(startDate)) {
          final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
          final changeType = movement['changeType'] as String;
          final change = (movement['newQty'] as int) - (movement['previousQty'] as int);

          if (changeType == 'add' && change > 0) {
            dailyIn[dateKey] = (dailyIn[dateKey] ?? 0) + change;
            totalIn += change;
          } else if (changeType == 'remove' && change < 0) {
            dailyOut[dateKey] = (dailyOut[dateKey] ?? 0) + change.abs();
            totalOut += change.abs();
          }
        }
      }
    }

    // Convert to list of StockMovementData
    List<StockMovementData> dailyData = [];
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      dailyData.add(StockMovementData(
        date: date,
        stockIn: dailyIn[dateKey] ?? 0,
        stockOut: dailyOut[dateKey] ?? 0,
      ));
    }

    return StockMovementSummary(
      totalIn: totalIn,
      totalOut: totalOut,
      dailyData: dailyData,
    );
  }

  Future<void> _applyFilter(String filter) async {
    setState(() {
      _selectedFilter = filter;
      _isLoading = true;
    });

    List<Product> products;

    switch (filter) {
      case 'Low Stock':
        products = await _repository.getLowStockProducts();
        break;
      case 'Out of Stock':
        final allProducts = await _repository.getAllProducts();
        products = allProducts.where((p) => p.isOutOfStock).toList();
        break;
      case 'Categories':
        products = await _repository.getAllProducts();
        // Sort by category
        products.sort((a, b) => a.category.name.compareTo(b.category.name));
        break;
      default: // All Items
        products = await _repository.getAllProducts();
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
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
                            value: _statistics?.outOfStockCount.toString() ?? '0',
                            icon: Icons.error_outline,
                            iconColor: Colors.red,
                          ),
                          StatCard(
                            label: 'Value',
                            value: '\$${_statistics?.totalValue.toStringAsFixed(0) ?? '0'}',
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
                          _buildFilterChip('All Items'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Low Stock'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Out of Stock'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Categories'),
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
                            color: Colors.black.withOpacity(0.04),
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
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
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
                          return _buildProductCard(product);
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _applyFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    Color statusColor = Colors.green;
    String statusText = 'In Stock';

    if (product.isOutOfStock) {
      statusColor = Colors.red;
      statusText = 'Out of Stock';
    } else if (product.isLowStock) {
      statusColor = Colors.orange;
      statusText = 'Low Stock';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.imagePath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      product.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey.shade400,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.grey.shade400,
                  ),
          ),
          const SizedBox(width: 12),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.brand,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stock: ${product.currentQuantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              product.category.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}