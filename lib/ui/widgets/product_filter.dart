import 'package:flutter/material.dart';

/// Reusable filter chip widget using Material's FilterChip
/// Used in analytics_screen.dart and product_list_screen.dart
class ProductFilter extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ProductFilter({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: Colors.blue,
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.grey.shade300,
        width: 1,
      ),
      elevation: isSelected ? 4 : 0,
      shadowColor: Colors.blue.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}