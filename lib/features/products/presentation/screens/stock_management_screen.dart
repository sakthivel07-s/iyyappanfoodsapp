import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/di/service_locator.dart';
import '../bloc/product_bloc.dart';

class StockManagementScreen extends StatelessWidget {
  const StockManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProductBloc>()..add(LoadProductsEvent()),
      child: const _StockManagementView(),
    );
  }
}

class _StockManagementView extends StatefulWidget {
  const _StockManagementView();

  @override
  State<_StockManagementView> createState() => _StockManagementViewState();
}

class _StockManagementViewState extends State<_StockManagementView> {
  final Map<String, Map<String, TextEditingController>> _controllers = {};

  @override
  void dispose() {
    for (var p in _controllers.values) {
      for (var c in p.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        actions: [
          TextButton.icon(
            onPressed: () => _showFreshLoadDialog(context),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            label: const Text('Fresh Load', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) return const Center(child: CircularProgressIndicator());
          if (state is ProductLoaded) {
            if (state.products.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.inventory_2_outlined,
                title: 'No Products',
                subtitle: 'Add products first to manage stock.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                _buildPlannerShortcut(context),
                const SizedBox(height: AppSizes.md),
                const SectionHeader(title: 'Update Stock Levels'),
                const SizedBox(height: AppSizes.md),
                ...state.products.map((product) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: AppSizes.xs),
                        Text(product.description, style: Theme.of(context).textTheme.bodySmall),
                        const Divider(height: AppSizes.lg),
                        ...product.variants.map((v) {
                          final pId = product.id;
                          final vUnit = v.unit;
                          _controllers.putIfAbsent(pId, () => {});
                          _controllers[pId]!.putIfAbsent(vUnit, () => TextEditingController(text: v.stock.toString()));
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(vUnit, style: Theme.of(context).textTheme.titleMedium),
                                      Text('Current: ${v.stock}', 
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: v.stock < 10 ? Colors.red : AppColors.textSecondary
                                        )
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: TextField(
                                    controller: _controllers[pId]![vUnit],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(44, 44),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                                  ),
                                  onPressed: () {
                                    final newStock = int.tryParse(_controllers[pId]![vUnit]!.text) ?? v.stock;
                                    context.read<ProductBloc>().add(UpdateStockEvent(pId, vUnit, newStock));
                                  },
                                  child: const Icon(Icons.check_rounded, size: 20),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showFreshLoadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Fresh Load'),
        content: const Text('This will help you update all stocks based on today\'s requirements. Would you like to proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Update stock levels for each item in the list below.')),
              );
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerShortcut(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: const BorderSide(color: AppColors.primary, width: 1),
      ),
      child: InkWell(
        onTap: () => context.push('/stock-planner'),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: const Padding(
          padding: EdgeInsets.all(AppSizes.lg),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.phone_in_talk_rounded, color: Colors.white),
              ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock Requirement Planner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Call customers and note daily needs', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
