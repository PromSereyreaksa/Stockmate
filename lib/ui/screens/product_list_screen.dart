import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/products_repository.dart';
import '../../models/product.dart';
import 'item_detail_screen.dart';

enum ProductFilter { all, inStock, lowStock, outOfStock }

enum SortOption { name, price, stock }

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with AutomaticKeepAliveClientMixin {
  final ProductsRepository _repository = ProductsRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;

  ProductFilter _currentFilter = ProductFilter.all;
  SortOption _currentSort = SortOption.name;
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    final products = await _repository.getAllProducts();

    setState(() {
      _allProducts = products.where((p) => !p.isDeleted).toList();
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    List<Product> filtered = List.from(_allProducts);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(_searchQuery) ||
            product.category.name.toLowerCase().contains(_searchQuery) ||
            product.brand.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply stock filter
    switch (_currentFilter) {
      case ProductFilter.inStock:
        filtered = filtered
            .where((p) => !p.isLowStock && !p.isOutOfStock)
            .toList();
        break;
      case ProductFilter.lowStock:
        filtered = filtered
            .where((p) => p.isLowStock && !p.isOutOfStock)
            .toList();
        break;
      case ProductFilter.outOfStock:
        filtered = filtered.where((p) => p.isOutOfStock).toList();
        break;
      case ProductFilter.all:
        break;
    }

    // Apply sorting
    switch (_currentSort) {
      case SortOption.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.price:
        filtered.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case SortOption.stock:
        filtered.sort((a, b) => b.currentQuantity.compareTo(a.currentQuantity));
        break;
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort by',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSortOption('Name', SortOption.name),
            _buildSortOption('Price', SortOption.price),
            _buildSortOption('Stock', SortOption.stock),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, SortOption option) {
    final isSelected = _currentSort == option;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        setState(() {
          _currentSort = option;
          _applyFilters();
        });
        Navigator.pop(context);
      },
    );
  }

  String _getStockStatus(Product product) {
    if (product.isOutOfStock) return 'Out of stock';
    if (product.isLowStock) return 'Low stock';
    return '${product.currentQuantity} in stock';
  }

  Color _getStockColor(Product product) {
    if (product.isOutOfStock) return Colors.red;
    if (product.isLowStock) return Colors.orange;
    return Colors.green;
  }

  String _formatCategoryName(ProductsCategory category) {
    switch (category) {
      case ProductsCategory.rice:
        return 'Rice';
      case ProductsCategory.noodles:
        return 'Noodles';
      case ProductsCategory.snacks:
        return 'Snacks';
      case ProductsCategory.beverages:
        return 'Beverages';
      case ProductsCategory.condiments:
        return 'Condiments';
      case ProductsCategory.cannedGoods:
        return 'Canned Goods';
      case ProductsCategory.dairy:
        return 'Dairy';
      case ProductsCategory.frozen:
        return 'Frozen';
      case ProductsCategory.bakery:
        return 'Bakery';
      case ProductsCategory.household:
        return 'Household';
      case ProductsCategory.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: _showSortMenu,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All Items', ProductFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip('In Stock', ProductFilter.inStock),
                const SizedBox(width: 8),
                _buildFilterChip('Low Stock', ProductFilter.lowStock),
                const SizedBox(width: 8),
                _buildFilterChip('Out of Stock', ProductFilter.outOfStock),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Results Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProducts.length} products found',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                GestureDetector(
                  onTap: _showSortMenu,
                  child: Row(
                    children: [
                      Icon(Icons.swap_vert, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Sort by ${_currentSort.name.substring(0, 1).toUpperCase()}${_currentSort.name.substring(1)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ProductFilter filter) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(productId: product.productId),
          ),
        );
        
        // Reload products if item was edited
        if (result == true) {
          _loadProducts();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.imagePath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.imagePath.startsWith('assets/')
                        ? Image.asset(
                            product.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey[400],
                              size: 30,
                            ),
                          )
                        : Image.file(
                            File(product.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey[400],
                              size: 30,
                            ),
                          ),
                  )
                : Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.grey[400],
                    size: 30,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCategoryName(product.category),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${product.sellingPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStockColor(product),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStockStatus(product),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
