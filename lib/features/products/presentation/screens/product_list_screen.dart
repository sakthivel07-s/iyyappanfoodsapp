import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductBloc>()..add(LoadProductsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.products),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => context.push('/products/add'),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: AppSizes.sm),
              child: AppSearchField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            Expanded(child: _ProductGrid(query: _query)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/products/add'),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final String query;
  const _ProductGrid({required this.query});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (_, __) => const ShimmerCard(height: 88),
          );
        }
        if (state is ProductError) {
          return ErrorStateWidget(message: state.message);
        }
        if (state is ProductLoaded) {
          final products = state.products
              .where((p) =>
                  p.name.toLowerCase().contains(query) ||
                  p.description.toLowerCase().contains(query))
              .where((p) => p.isActive)
              .toList();

          if (products.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.inventory_2_outlined,
              title: AppStrings.noProducts,
              subtitle: AppStrings.addFirstProduct,
              actionLabel: AppStrings.addProduct,
              onAction: () => context.push('/products/add'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (_, i) => _ProductCard(product: products[i]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductBloc>();
    final cheapest = product.variants.fold<double>(
        double.infinity, (min, v) => v.price < min ? v.price : min);
    final displayedPrice = cheapest == double.infinity ? 0.0 : cheapest;

    return InkWell(
      onTap: () => context.push('/products/${product.id}'),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Center(
                child: Text(
                  product.name.isNotEmpty ? product.name[0].toUpperCase() : 'P',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: product.variants
                        .map((v) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLighter,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusFull),
                              ),
                              child: Text(
                                '${v.unit} • ${CurrencyFormatter.format(v.price)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.primaryDark),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyFormatter.format(displayedPrice),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 12,
                      color: product.variants.any((v) => v.stock < 10) ? Colors.red : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: ${product.variants.fold(0, (sum, v) => sum + v.stock)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: product.variants.any((v) => v.stock < 10) ? Colors.red : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => context.push('/products/edit/${product.id}'),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18,
                          color: AppColors.error),
                      onPressed: () async {
                        final confirm = await ConfirmDialog.show(context,
                            message: 'Delete "${product.name}"?');
                        if (confirm == true) {
                          bloc.add(DeleteProductEvent(product.id));
                        }
                      },
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
