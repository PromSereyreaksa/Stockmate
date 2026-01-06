import 'package:flutter/material.dart';
import '../../data/repositories/product_repository.dart';
import '../../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_filter.dart';
import 'item_detail_screen.dart';

enum StockFilterType { all, inStock, lowStock, outOfStock, expired, almostExpired }

enum SortOption { name, price, stock }

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
        // Keeps this screen alive when switching tabs/pages
        // so search text, filters, sorting, scroll position,
        // and loaded products are not reset.
        with
        AutomaticKeepAliveClientMixin {
  // i need to keep filter/search/sort state when switching tabs
  final ProductRepository _productRepo = ProductRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;

  StockFilterType _currentFilter = StockFilterType.all;
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
      _searchQuery = _searchController.text.trim().toLowerCase();
      _applyFilters();
    });
  }

  // Load all products from repository and update UI
  Future<void> _loadProducts() async {
    //show a loading indicator while fetching data
    setState(() => _isLoading = true);

    //fetch all products from the repository
    final products = await _productRepo.getAllProducts();

    setState(() {
      //remove deleted products from the list
      _allProducts = products.where((p) => !p.isDeleted).toList();

      _applyFilters();

      _isLoading = false;
    });
  }

  // Apply search, filter, and sorting logic to products
  void _applyFilters() {
    List<Product> filtered = List.from(_allProducts);

    // filtered products based on the search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name
            .toLowerCase()
            .contains(_searchQuery);
      }).toList();
    }

    // Apply filter using repository
    String filterKey = _currentFilter.name;
    filtered = _productRepo.filterByStockStatus(filtered, filterKey);

    // Apply sorting using repository
    String sortKey = _currentSort.name;
    filtered = _productRepo.sortProducts(filtered, sortKey);

    // update the UI with the filtered and sorted products
    setState(() {
      _filteredProducts = filtered;
    });
  }

  Future<void> _deleteProduct(Product product) async {
    // delete the product from the repository using its ID
    await _productRepo.deleteProduct(product.productId);

    // calling loadProducts to reload the product list after deletion
    _loadProducts();

    // sure the widget is still mounted before showing a message
    // Only show the message if still on this screen.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} deleted'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
              // TextField so slightly better for performance, don't need any validation so textfield is fine
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
                ProductFilter(
                  label: 'All Items',
                  isSelected: _currentFilter == StockFilterType.all,
                  onTap: () {
                    setState(() {
                      _currentFilter = StockFilterType.all;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ProductFilter(
                  label: 'In Stock',
                  isSelected: _currentFilter == StockFilterType.inStock,
                  onTap: () {
                    setState(() {
                      _currentFilter = StockFilterType.inStock;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ProductFilter(
                  label: 'Low Stock',
                  isSelected: _currentFilter == StockFilterType.lowStock,
                  onTap: () {
                    setState(() {
                      _currentFilter = StockFilterType.lowStock;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ProductFilter(
                  label: 'Out of Stock',
                  isSelected: _currentFilter == StockFilterType.outOfStock,
                  onTap: () {
                    setState(() {
                      _currentFilter = StockFilterType.outOfStock;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ProductFilter(
                  label: 'Expired',
                  isSelected: _currentFilter == StockFilterType.expired,
                  onTap: () {
                    setState(() {
                      _currentFilter = StockFilterType.expired;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ProductFilter(
                  label: 'Almost Expired',
                  isSelected: _currentFilter == StockFilterType.almostExpired,
                  onTap: () {
                    setState(() {
                      _currentFilter = StockFilterType.almostExpired;
                      _applyFilters();
                    });
                  },
                ),
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
                      return Dismissible(
                        key: Key(product.productId),
                        direction: DismissDirection.startToEnd,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Product'),
                              content: Text(
                                'Are you sure you want to delete ${product.name}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
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
                        child: ProductCard(
                          product: product,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemDetailScreen(
                                  productId: product.productId,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadProducts();
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  
}
