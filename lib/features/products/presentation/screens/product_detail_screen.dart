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

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductBloc>()..add(LoadProductsEvent()),
      child: _ProductDetailView(productId: productId),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  final String productId;
  const _ProductDetailView({required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (state is ProductLoaded) {
          final product = state.products.where((p) => p.id == productId).firstOrNull;
          if (product == null) return const Scaffold(body: ErrorStateWidget(message: 'Product not found'));

          return Scaffold(
            appBar: AppBar(
              title: Text(product.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/products/edit/${product.id}'),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _HeaderSection(product: product),
                  const SizedBox(height: AppSizes.lg),
                  const SectionHeader(title: AppStrings.productVariants),
                  const SizedBox(height: AppSizes.sm),
                  ...product.variants.map((v) => _VariantCard(variant: v)),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final Product product;
  const _HeaderSection({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Center(
              child: Text(
                product.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(product.description.isEmpty ? 'No description' : product.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                StatusBadge(status: product.isActive ? 'active' : 'inactive'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  final ProductVariant variant;
  const _VariantCard({required this.variant});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(variant.unit, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Stock: ${variant.stock}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          Text(CurrencyFormatter.format(variant.price),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
        ],
      ),
    );
  }
}
