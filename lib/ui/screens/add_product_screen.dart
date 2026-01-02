import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/products_repository.dart';
import '../../models/product.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ProductsRepository();

  // Controllers
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _costPriceController = TextEditingController(text: '0.00');
  final _sellingPriceController = TextEditingController(text: '0.00');
  final _minStockController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _supplierController = TextEditingController();

  // State
  ProductsCategory _selectedCategory = ProductsCategory.other;
  int _quantity = 1;
  String? _imagePath;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
      _quantityController.text = _quantity.toString();
    });
  }

  void _decrementQuantity() {
    if (_quantity > 0) {
      setState(() {
        _quantity--;
        _quantityController.text = _quantity.toString();
      });
    }
  }

  void _onQuantityChanged(String value) {
    final newValue = int.tryParse(value);
    if (newValue != null && newValue >= 0) {
      setState(() {
        _quantity = newValue;
      });
    }
  }

  Future<void> _pickImage() async {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image picker coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveProduct({bool isDraft = false}) async {
    if (!isDraft && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Generate product ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final productId = 'P${timestamp.toString().substring(7)}';

      // Parse prices
      final costPrice = double.tryParse(_costPriceController.text) ?? 0.0;
      final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;
      final minStock = int.tryParse(_minStockController.text) ?? 1;

      // Create product
      final product = Product(
        productId: productId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        currentQuantity: _quantity,
        expDate: DateTime.now().add(const Duration(days: 365)), // Default 1 year
        stock: _quantity,
        minStock: minStock,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        barcode: _skuController.text.trim(),
        brand: _brandController.text.trim(),
        supplier: _supplierController.text.trim(),
        imagePath: _imagePath ?? '',
        category: _selectedCategory,
      );

      // Save to database
      await _repository.insertProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDraft ? 'Saved as draft' : 'Product added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Clear form and reset to initial state
        _nameController.clear();
        _skuController.clear();
        _quantityController.text = '1';
        _costPriceController.text = '0.00';
        _sellingPriceController.text = '0.00';
        _minStockController.text = '1';
        _descriptionController.clear();
        _brandController.clear();
        _supplierController.clear();
        _imagePath = null;
        _quantity = 1;
        _selectedCategory = ProductsCategory.other;
        
        setState(() {});
      }
    } catch (e) {
      print('Error saving product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Add Stock Item',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : () => _saveProduct(isDraft: false),
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Section
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _imagePath == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Stock Photo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  _imagePath!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap camera to add photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Form Fields
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    const Text(
                      'Product Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter product name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // SKU/Barcode
                    const Text(
                      'SKU/Barcode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _skuController,
                      decoration: InputDecoration(
                        hintText: 'Enter SKU',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () {
                            // TODO: Implement barcode scanner
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Barcode scanner coming soon!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ProductsCategory>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      items: ProductsCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(_formatCategory(category)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Quantity
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: _decrementQuantity,
                            icon: const Icon(Icons.remove),
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: _onQuantityChanged,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: _incrementQuantity,
                            icon: const Icon(Icons.add),
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Cost Price & Selling Price
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cost Price',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _costPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selling Price',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _sellingPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Low Stock Alert
                    const Text(
                      'Low Stock Alert',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Minimum quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Brand
                    const Text(
                      'Brand',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        hintText: 'Enter brand name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Supplier
                    const Text(
                      'Supplier',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _supplierController,
                      decoration: InputDecoration(
                        hintText: 'Enter supplier name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Description (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter product description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Space for bottom buttons
            ],
          ),
        ),
      ),

      // Bottom Action Buttons
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveProduct(isDraft: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add to Stock',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => _saveProduct(isDraft: true),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text(
                    'Save as Draft',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCategory(ProductsCategory category) {
    final name = category.name;
    // Convert camelCase to Title Case
    final formatted = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim();
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}