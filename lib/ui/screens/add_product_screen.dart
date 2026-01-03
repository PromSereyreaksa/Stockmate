import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../../data/products_repository.dart';
import '../../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  final VoidCallback? onProductAdded;
  
  const AddProductScreen({super.key, this.product, this.onProductAdded});

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
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateForm(widget.product!);
    }
  }

  void _populateForm(Product product) {
    _nameController.text = product.name;
    _skuController.text = product.barcode;
    _quantityController.text = product.currentQuantity.toString();
    _costPriceController.text = product.costPrice.toStringAsFixed(2);
    _sellingPriceController.text = product.sellingPrice.toStringAsFixed(2);
    _minStockController.text = product.minStock.toString();
    _descriptionController.text = product.description;
    _brandController.text = product.brand;
    _supplierController.text = product.supplier;
    _selectedCategory = product.category;
    _quantity = product.currentQuantity;
    _imagePath = product.imagePath.isNotEmpty ? product.imagePath : null;
  }

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
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            // Only show camera option on mobile devices
            if (isMobile)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                    preferredCameraDevice: CameraDevice.rear,
                  );
                  if (image != null) {
                    // Copy to permanent storage immediately
                    final String permanentPath = await _copyImageToPermanentStorage(image.path);
                    setState(() {
                      _imagePath = permanentPath;
                    });
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(isMobile ? 'Choose from Gallery' : 'Choose Image'),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1024,
                  maxHeight: 1024,
                  imageQuality: 85,
                );
                if (image != null) {
                  // Copy to permanent storage immediately
                  final String permanentPath = await _copyImageToPermanentStorage(image.path);
                  setState(() {
                    _imagePath = permanentPath;
                  });
                }
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imagePath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String> _copyImageToPermanentStorage(String tempPath) async {
    try {
      final File tempFile = File(tempPath);
      if (!await tempFile.exists()) {
        print('❌ Temp file does not exist: $tempPath');
        return tempPath;
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = '${appDir.path}/product_images';
      await Directory(imagesDir).create(recursive: true);
      
      // Generate unique filename using timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'temp_$timestamp${path.extension(tempPath)}';
      final String newPath = '$imagesDir/$fileName';
      
      await tempFile.copy(newPath);
      print('✅ Image copied immediately to: $newPath');
      return newPath;
    } catch (e) {
      print('❌ Error copying image immediately: $e');
      return tempPath; // Return original path as fallback
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final bool isEditing = widget.product != null;
      
      // Generate or use existing product ID
      final String productId;
      if (isEditing) {
        productId = widget.product!.productId;
      } else {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        productId = 'P${timestamp.toString().substring(7)}';
      }

      // Parse prices
      final costPrice = double.tryParse(_costPriceController.text) ?? 0.0;
      final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;
      final minStock = int.tryParse(_minStockController.text) ?? 1;

      // Rename image file with product ID for better organization
      String? savedImagePath = _imagePath;
      if (_imagePath != null && !_imagePath!.startsWith('assets/') && _imagePath!.contains('product_images')) {
        try {
          // Rename temp file to use product ID
          final File currentFile = File(_imagePath!);
          if (await currentFile.exists()) {
            final Directory appDir = await getApplicationDocumentsDirectory();
            final String imagesDir = '${appDir.path}/product_images';
            final String fileName = '${productId}${path.extension(_imagePath!)}';
            final String newPath = '$imagesDir/$fileName';
            
            // Only rename if it's not already the correct name
            if (_imagePath != newPath) {
              await currentFile.copy(newPath);
              savedImagePath = newPath;
              print('✅ Image copy to: $newPath');
            }
          }
        } catch (e) {
          print('❌ Error renaming image: $e');
        }
      }

      // Create or update product
      final product = Product(
        productId: productId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? 'No description' 
            : _descriptionController.text.trim(),
        currentQuantity: _quantity,
        expDate: isEditing ? widget.product!.expDate : DateTime.now().add(const Duration(days: 365)),
        stock: _quantity,
        minStock: minStock,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        barcode: _skuController.text.trim(),
        brand: _brandController.text.trim().isEmpty 
            ? 'Not provided' 
            : _brandController.text.trim(),
        supplier: _supplierController.text.trim().isEmpty 
            ? 'Not provided' 
            : _supplierController.text.trim(),
        imagePath: savedImagePath ?? '',
        category: _selectedCategory,
      );

      // Save to database
      if (isEditing) {
        await _repository.updateProduct(product);
      } else {
        await _repository.insertProduct(product);
      }

      if (mounted) {
        final bool isEditing = widget.product != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Product updated successfully!' : 'Product added successfully!'),
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
        
        // Return to product list or trigger navigation to items tab
        if (isEditing) {
          Navigator.pop(context, true);
        } else {
          // Call callback to switch to items tab and see newly added product
          // Add small delay to avoid graphics context issues
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              widget.onProductAdded?.call();
            }
          });
        }
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
        title: Text(
          widget.product != null ? 'Edit Item' : 'Add Item',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: widget.product != null ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ) : null,
        actions: widget.product == null ? [
          IconButton(
            onPressed: () {
              // Clear the form when X is pressed (only for new products)
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
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Form cleared'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ] : null,
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
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
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
                                child: _imagePath!.startsWith('assets/')
                                    ? Image.asset(
                                        _imagePath!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_imagePath!),
                                        fit: BoxFit.cover,
                                      ),
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
                      'Product Name *',
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
                      'SKU/Barcode (Optional)',
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
                                'Cost Price (Optional)',
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
                                'Selling Price (Optional)',
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
                      'Brand (Optional)',
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
                      'Supplier (Optional)',
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
                    const SizedBox(height: 24),

                    // Add to Stock Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveProduct(),
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
                            : Text(
                                widget.product != null ? 'Update Item' : 'Add to Stock',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
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