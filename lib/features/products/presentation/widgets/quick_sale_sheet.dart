import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../bloc/stock_planner_bloc.dart';
import '../bloc/product_bloc.dart';
import '../../../bookings/domain/entities/booking.dart';

class QuickSaleSheet extends StatefulWidget {
  const QuickSaleSheet({super.key});

  @override
  State<QuickSaleSheet> createState() => _QuickSaleSheetState();
}

class _QuickSaleSheetState extends State<QuickSaleSheet> {
  // Key: productId_unit
  final Map<String, int> _selectedQuantities = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      padding: EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, MediaQuery.of(context).viewInsets.bottom + AppSizes.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: AppSizes.md),
          Text('Walk-in Customer Sale', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Text('Select items and quantities for walk-in sale', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.md),
          BlocListener<StockPlannerBloc, StockPlannerState>(
            listener: (context, state) {
              if (state is StockPlannerOperationSuccess) {
                Navigator.pop(context);
              }
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoaded) {
                    final products = state.products.where((p) => p.isActive).toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                            ...product.variants.map((v) {
                              final key = '${product.id}_${v.unit}';
                              final qty = _selectedQuantities[key] ?? 0;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(v.unit),
                                subtitle: Text(
                                  '₹${v.price} / unit • Stock: ${v.stock}',
                                  style: TextStyle(
                                    color: v.stock < 10 ? Colors.red : AppColors.textSecondary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: qty > 0 ? () => setState(() => _selectedQuantities[key] = qty - 1) : null,
                                    ),
                                    Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => setState(() => _selectedQuantities[key] = qty + 1),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final List<BookingItem> items = [];
                double subtotal = 0;
                final state = context.read<ProductBloc>().state;
                if (state is! ProductLoaded) return;
                
                final products = state.products;

                _selectedQuantities.forEach((key, qty) {
                  if (qty > 0) {
                    final parts = key.split('_');
                    final pid = parts[0];
                    final unit = parts[1];
                    try {
                      final p = products.firstWhere((p) => p.id == pid);
                      final v = p.variants.firstWhere((v) => v.unit == unit);
                      
                      items.add(BookingItem(
                        productId: pid,
                        productName: p.name,
                        unit: unit,
                        quantity: qty,
                        unitPrice: v.price,
                        totalPrice: v.price * qty,
                      ));
                      subtotal += v.price * qty;
                    } catch (_) {}
                  }
                });

                if (items.isEmpty) return;

                context.read<StockPlannerBloc>().add(QuickSaleEvent(
                  items: items,
                  subtotal: subtotal,
                  grandTotal: subtotal,
                ));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSizes.md),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
              child: const Text('Confirm Sale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
