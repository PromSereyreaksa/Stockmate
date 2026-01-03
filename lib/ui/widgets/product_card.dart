import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/product.dart';
import '../../utils/stock_status.dart';
import '../screens/item_detail_screen.dart';

/// Reusable product card widget used in multiple screens
/// Consolidates duplicate code from analytics_screen.dart and product_list_screen.dart
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showPrice;
  final bool showCategory;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showPrice = true,
    this.showCategory = true,
  });

  static String formatCategoryName(ProductsCategory category) {
    final name = category.name;
    return name[0].toUpperCase() + name.substring(1).replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = StockStatus.fromProduct(product);
    final statusColor = status.color;
    final statusText = status.displayText;

    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ItemDetailScreen(productId: product.productId),
              ),
            );
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildProductImage(),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                          color: statusColor.withValues(alpha: 0.1),
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
                      if (showPrice) ...[
                        const SizedBox(width: 8),
                        Text(
                          '\$${product.sellingPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Category Badge (optional)
            if (showCategory)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formatCategoryName(product.category),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    if (product.imagePath.isEmpty) {
      return Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey.shade400,
      );
    }

    if (product.imagePath.startsWith('assets/')) {
      return Image.asset(
        product.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.inventory_2_outlined,
          color: Colors.grey.shade400,
        ),
      );
    }

    return Image.file(
      File(product.imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey.shade400,
      ),
    );
  }
}