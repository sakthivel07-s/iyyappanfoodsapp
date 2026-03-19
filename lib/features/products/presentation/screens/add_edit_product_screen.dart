import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';

class AddEditProductScreen extends StatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isActive = true;
  final List<_VariantEntry> _variants = [_VariantEntry()];
  bool get _isEdit => widget.productId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (var v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  void _submit(BuildContext context, ProductBloc bloc) {
    if (!_formKey.currentState!.validate()) return;

    final variants = _variants
        .where((v) => v.unitCtrl.text.trim().isNotEmpty)
        .map((v) => ProductVariant(
              unit: v.unitCtrl.text.trim(),
              price: double.tryParse(v.priceCtrl.text) ?? 0,
              stock: v.initialStock, // Preserve initial/existing stock
            ))
        .toList();

    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one variant')));
      return;
    }

    final product = Product(
      id: widget.productId ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      variants: variants,
      isActive: _isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_isEdit) {
      bloc.add(UpdateProductEvent(product));
    } else {
      bloc.add(AddProductEvent(product));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<ProductBloc>();
        if (_isEdit) bloc.add(LoadProductsEvent());
        return bloc;
      },
      child: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            context.pop();
          }
          if (state is ProductLoaded && _isEdit) {
            final product = state.products
                .where((p) => p.id == widget.productId)
                .firstOrNull;
            if (product != null) {
              _nameCtrl.text = product.name;
              _descCtrl.text = product.description;
              _isActive = product.isActive;
              _variants.clear();
              for (var v in product.variants) {
                final entry = _VariantEntry();
                entry.unitCtrl.text = v.unit;
                entry.priceCtrl.text = v.price.toString();
                entry.initialStock = v.stock;
                _variants.add(entry);
              }
              setState(() {});
            }
          }
          if (state is ProductError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final bloc = context.read<ProductBloc>();
          return Scaffold(
            appBar: AppBar(
              title: Text(_isEdit ? AppStrings.editProduct : AppStrings.addProduct),
              actions: [
                TextButton(
                  onPressed: state is ProductLoading
                      ? null
                      : () => _submit(context, bloc),
                  child: state is ProductLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text(AppStrings.save),
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.md),
                children: [
                  _Section(title: 'Product Info', children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.productName,
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSizes.md),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.productDescription,
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSizes.md),
                    SwitchListTile(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      title: const Text(AppStrings.activeProduct),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ]),
                  const SizedBox(height: AppSizes.md),
                  _Section(
                    title: AppStrings.productVariants,
                    trailing: TextButton.icon(
                      onPressed: () =>
                          setState(() => _variants.add(_VariantEntry())),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(AppStrings.addVariant),
                    ),
                    children: [
                      ...List.generate(_variants.length, (i) {
                        final v = _variants[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.md),
                          child: _VariantRow(
                            entry: v,
                            onDelete: _variants.length > 1
                                ? () => setState(() => _variants.removeAt(i))
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  ElevatedButton(
                    onPressed: state is ProductLoading
                        ? null
                        : () => _submit(context, bloc),
                    child: state is ProductLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Update Product' : 'Add Product'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  final _VariantEntry entry;
  final VoidCallback? onDelete;

  const _VariantRow({required this.entry, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: entry.unitCtrl,
            decoration: const InputDecoration(labelText: 'Unit (e.g. 1kg)'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: entry.priceCtrl,
            decoration: const InputDecoration(labelText: '₹ Price'),
            keyboardType: TextInputType.number,
            validator: (v) =>
                v == null || double.tryParse(v) == null ? 'Enter valid price' : null,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        const Expanded(
          flex: 2,
          child: SizedBox.shrink(), // Stock managed in separate section
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 20),
            onPressed: onDelete,
          ),
      ],
    );
  }
}

class _VariantEntry {
  final unitCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  int initialStock = 0;

  void dispose() {
    unitCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _Section({required this.title, this.trailing, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleLarge),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSizes.md),
          ...children,
        ],
      ),
    );
  }
}
