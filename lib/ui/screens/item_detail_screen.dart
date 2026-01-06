import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../models/product.dart';
import '../../models/statistic.dart';
import '../../utils/stock_status.dart';
import '../widgets/info_row.dart';
import '../widgets/activity_item.dart';
import '../widgets/product_card.dart';
import '../dialogs/add_stock_dialog.dart';
import 'add_product_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final String productId;

  const ItemDetailScreen({super.key, required this.productId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final StockRepository _stockRepo = StockRepository();

  Product? _product;
  List<StockMovement> _recentActivity = [];
  bool _isLoading = true;
  bool _showAllActivity = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final product = await _productRepo.getProductById(widget.productId);
      final history = await _stockRepo.getStockHistory(widget.productId);

      setState(() {
        _product = product;
        _recentActivity = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddStockDialog() async {
    if (_product == null) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AddStockDialog(
        productName: _product!.name,
        currentStock: _product!.currentQuantity,
        onAdd: (quantity, reason) async {
          final messenger = ScaffoldMessenger.of(context);

          final newQuantity = _product!.currentQuantity + quantity;
          await _stockRepo.updateStock(_product!.productId, newQuantity);
          _loadData();

          if (!mounted) return;

          messenger.showSnackBar(
            SnackBar(
              content: Text('Added $quantity units to stock'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _navigateToEdit() async {
    if (_product == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: _product),
      ),
    );

    // Reload data if product was updated and notify parent
    if (result == true) {
      await _loadData();
      if (mounted) {
        Navigator.pop(
          context,
          true,
        ); // Return true to parent to trigger refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Item Details'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final product = _product!;

    // Determine status
    final stockStatus = StockStatus.fromProduct(product);
    final statusColor = stockStatus.color;
    final statusText = stockStatus.displayText;

    // Activity list (limit to 3 if not showing all)
    final displayedActivity = _showAllActivity
        ? _recentActivity
        : _recentActivity.take(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Item Details',
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
            // Product Image & Basic Info
            Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                children: [
                  // Product Image
                  Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey.shade100,
                    child: product.imagePath.isNotEmpty
                        ? (product.imagePath.startsWith('assets/')
                              ? Image.asset(
                                  product.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.inventory_2_outlined,
                                      size: 80,
                                      color: Colors.grey.shade400,
                                    );
                                  },
                                )
                              : Image.file(
                                  File(product.imagePath),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.inventory_2_outlined,
                                      size: 80,
                                      color: Colors.grey.shade400,
                                    );
                                  },
                                ))
                        : Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                  ),

                  // Product Name & Status
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stock Info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStockCard(
                            'Current Stock',
                            product.currentQuantity.toString(),
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStockCard(
                            'Min Stock',
                            product.minStock.toString(),
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Product Information
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  InfoRow(
                    label: 'Category',
                    value: ProductCard.formatCategoryName(product.category),
                  ),
                  InfoRow(label: 'Brand', value: product.brand),
                  InfoRow(
                    label: 'Cost Price',
                    value: '\$${product.costPrice.toStringAsFixed(2)}',
                  ),
                  InfoRow(
                    label: 'Selling Price',
                    value: '\$${product.sellingPrice.toStringAsFixed(2)}',
                  ),
                  InfoRow(label: 'Supplier', value: product.supplier),
                  InfoRow(label: 'Barcode', value: product.barcode),
                  InfoRow(
                    label: 'Exp Date',
                    value: DateFormat('MMM dd, yyyy').format(product.expDate),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recent Activity
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (_recentActivity.length > 3)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showAllActivity = !_showAllActivity;
                            });
                          },
                          child: Text(
                            _showAllActivity ? 'Show Less' : 'View All',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (displayedActivity.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No activity yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedActivity.length,
                      itemBuilder: (context, index) {
                        final activity = displayedActivity[index];
                        return ActivityItem(
                          type: activity.changeType,
                          previousQty: activity.previousQty,
                          newQty: activity.newQty,
                          timestamp: activity.timestamp,
                          reason: activity.reason,
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),

      // Bottom Action Buttons
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add Stock Button (Primary)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showAddStockDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Add Stock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Edit Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _navigateToEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Edit Item'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
