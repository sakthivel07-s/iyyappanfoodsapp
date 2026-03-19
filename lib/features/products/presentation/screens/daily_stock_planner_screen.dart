import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../bloc/stock_planner_bloc.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../domain/entities/daily_requirement.dart';
import '../../presentation/bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../bookings/domain/entities/booking.dart';

class DailyStockPlannerScreen extends StatelessWidget {
  const DailyStockPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<StockPlannerBloc>()..add(LoadPlannerEvent(DateTime.now())),
        ),
        BlocProvider(
          create: (_) => sl<ProductBloc>()..add(LoadProductsEvent()),
        ),
      ],
      child: BlocListener<StockPlannerBloc, StockPlannerState>(
        listener: (context, state) {
          if (state is StockPlannerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is StockPlannerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Daily Stock Planner'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Customer Calls', icon: Icon(Icons.phone_in_talk_outlined)),
                  Tab(text: 'Stock Summary', icon: Icon(Icons.inventory_2_outlined)),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                _CustomerChecklistTab(),
                _RequirementsSummaryTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerChecklistTab extends StatelessWidget {
  const _CustomerChecklistTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockPlannerBloc, StockPlannerState>(
      builder: (context, state) {
        if (state is StockPlannerLoading) return const Center(child: CircularProgressIndicator());
        if (state is StockPlannerLoaded) {
          if (state.customers.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.person_off_outlined,
              title: 'No customers found',
              subtitle: 'Add customers in the Customers tab first.',
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.md),
                  itemCount: state.customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, index) {
                    final customer = state.customers[index];
                    final requirement = _getRequirementForCustomer(state.requirements, customer.id);
                    final isDone = requirement != null && requirement.items.isNotEmpty;

                    return _CustomerPlannerTile(
                      customer: customer,
                      isDone: isDone,
                      requirement: requirement,
                      onTap: () => _showRequirementDialog(context, customer, requirement),
                    );
                  },
                ),
              ),
              const _QuickSaleCard(),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  DailyRequirement? _getRequirementForCustomer(List<DailyRequirement> requirements, String customerId) {
    try {
      return requirements.firstWhere((r) => r.customerId == customerId);
    } catch (_) {
      return null;
    }
  }

  void _showRequirementDialog(BuildContext context, Customer customer, DailyRequirement? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<StockPlannerBloc>(),
        child: BlocProvider.value(
          value: context.read<ProductBloc>(),
          child: _RequirementEntrySheet(customer: customer, existing: existing),
        ),
      ),
    );
  }
}

class _CustomerPlannerTile extends StatelessWidget {
  final Customer customer;
  final bool isDone;
  final DailyRequirement? requirement;
  final VoidCallback onTap;

  const _CustomerPlannerTile({
    required this.customer,
    required this.isDone,
    this.requirement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: isDone ? AppColors.success.withOpacity(0.5) : AppColors.border),
      ),
      color: isDone ? AppColors.successLight.withOpacity(0.1) : AppColors.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xs),
        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
          isDone 
            ? '${requirement!.items.fold(0, (sum, i) => sum + i.quantity)} total unit(s)' 
            : 'No requirements recorded',
          style: TextStyle(color: isDone ? AppColors.success : AppColors.textSecondary),
        ),
        trailing: Icon(
          isDone ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
          color: isDone ? AppColors.success : AppColors.primary,
          size: 28,
        ),
        onTap: onTap,
      ),
    );
  }
}

// Add a new widget for Random Customer Sales at the bottom of the list
class _QuickSaleCard extends StatelessWidget {
  const _QuickSaleCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(AppSizes.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: AppColors.primary),
                const SizedBox(width: AppSizes.sm),
                Text('Quick Sale (Random Customer)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            ElevatedButton.icon(
              onPressed: () => _showQuickSaleSheet(context),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add Random Sale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSizes.md),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickSaleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<StockPlannerBloc>(),
        child: BlocProvider.value(
          value: context.read<ProductBloc>(),
          child: const _QuickSaleSheet(),
        ),
      ),
    );
  }
}

class _RequirementsSummaryTab extends StatelessWidget {
  const _RequirementsSummaryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockPlannerBloc, StockPlannerState>(
      builder: (context, state) {
        if (state is StockPlannerLoaded) {
          if (state.totalRequirements.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.analytics_outlined,
              title: 'No requirements yet',
              subtitle: 'Start recording customer needs to see the total stock summary.',
            );
          }

          return BlocBuilder<ProductBloc, ProductState>(
            builder: (context, productState) {
              if (productState is ProductLoaded) {
                // We need to group totals by productId and variantUnit
                // But my StockPlannerBloc totals is Map<String, int> (productId -> qty)
                // Wait, I should have grouped by productId + unit.
                
                final requirements = state.requirements;
                final Map<String, Map<String, int>> groupedTotals = {}; // productId -> {unit -> total}

                for (final req in requirements) {
                  for (final item in req.items) {
                    if (!groupedTotals.containsKey(item.productId)) {
                      groupedTotals[item.productId] = {};
                    }
                    groupedTotals[item.productId]![item.unit] = 
                        (groupedTotals[item.productId]![item.unit] ?? 0) + item.quantity;
                  }
                }

                final productIds = groupedTotals.keys.toList();

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSizes.md),
                        itemCount: productIds.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                        itemBuilder: (context, index) {
                          final pid = productIds[index];
                          final unitsMap = groupedTotals[pid]!;
                          final product = productState.products.firstWhere((p) => p.id == pid, 
                              orElse: () => Product(
                                id: pid, 
                                name: 'Deleted Product', 
                                description: '', 
                                variants: [], 
                                isActive: false, 
                                createdAt: DateTime.now(), 
                                updatedAt: DateTime.now()
                              ));

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const Divider(),
                                  ...unitsMap.entries.map((e) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(e.key, style: const TextStyle(fontSize: 16)),
                                        Text(
                                          '${e.value} Unit(s)',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showBulkBookingDialog(context, productState.products, state.requirements),
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Review & Book All Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(AppSizes.md),
                            side: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showProductionDialog(context, productState.products, groupedTotals),
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Confirm Daily Production', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(AppSizes.md),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _showProductionDialog(BuildContext context, List<Product> products, Map<String, Map<String, int>> requirements) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<StockPlannerBloc>(),
        child: _ProductionEntrySheet(products: products, requirements: requirements),
      ),
    );
  }

  void _showBulkBookingDialog(BuildContext context, List<Product> products, List<DailyRequirement> requirements) {
    if (requirements.every((r) => r.items.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No requirements to book!')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<StockPlannerBloc>(),
        child: _BulkBookingReviewSheet(products: products, requirements: requirements),
      ),
    );
  }
}

class _RequirementEntrySheet extends StatefulWidget {
  final Customer customer;
  final DailyRequirement? existing;

  const _RequirementEntrySheet({required this.customer, this.existing});

  @override
  State<_RequirementEntrySheet> createState() => _RequirementEntrySheetState();
}

class _RequirementEntrySheetState extends State<_RequirementEntrySheet> {
  // Key: productId_unit
  final Map<String, int> _selectedQuantities = {};

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      for (final item in widget.existing!.items) {
        _selectedQuantities['${item.productId}_${item.unit}'] = item.quantity;
      }
    }
  }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Needs', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(widget.customer.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) return const Center(child: CircularProgressIndicator());
                if (state is ProductLoaded) {
                  final products = state.products.where((p) => p.isActive).toList();
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          ),
                          ...product.variants.map((variant) {
                            final key = '${product.id}_${variant.unit}';
                            final qty = _selectedQuantities[key] ?? 0;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              title: Text(variant.unit),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                                    onPressed: qty > 0 ? () => setState(() => _selectedQuantities[key] = qty - 1) : null,
                                  ),
                                  SizedBox(width: 32, child: Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
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
                return const SizedBox.shrink();
              },
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final List<RequirementItem> items = [];
                final products = (context.read<ProductBloc>().state as ProductLoaded).products;
                
                _selectedQuantities.forEach((key, qty) {
                  if (qty > 0) {
                    final parts = key.split('_');
                    final pid = parts[0];
                    final unit = parts[1];
                    final p = products.firstWhere((p) => p.id == pid);
                    items.add(RequirementItem(
                      productId: pid,
                      productName: p.name,
                      unit: unit,
                      quantity: qty,
                    ));
                  }
                });

                context.read<StockPlannerBloc>().add(SaveCustomerRequirementEvent(DailyRequirement(
                  id: '', 
                  customerId: widget.customer.id,
                  customerName: widget.customer.name,
                  date: DateTime.now(),
                  items: items,
                  updatedAt: DateTime.now(),
                )));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSizes.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
              child: const Text('Save Customer Needs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductionEntrySheet extends StatefulWidget {
  final List<Product> products;
  final Map<String, Map<String, int>> requirements;

  const _ProductionEntrySheet({required this.products, required this.requirements});

  @override
  State<_ProductionEntrySheet> createState() => _ProductionEntrySheetState();
}

class _ProductionEntrySheetState extends State<_ProductionEntrySheet> {
  final Map<String, int> _producedQuantities = {};

  @override
  void initState() {
    super.initState();
    // Initialize with requirements
    widget.requirements.forEach((pid, units) {
      units.forEach((unit, qty) {
        _producedQuantities['${pid}_$unit'] = qty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsWithNeeds = widget.products.where((p) => widget.requirements.containsKey(p.id)).toList();

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
          Text('Enter Produced Quantities', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Text('Include extra packets/buffer for random sales', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.md),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: productsWithNeeds.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final product = productsWithNeeds[index];
                final needs = widget.requirements[product.id]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ...needs.keys.map((unit) {
                      final key = '${product.id}_$unit';
                      final needed = needs[unit] ?? 0;
                      final prod = _producedQuantities[key] ?? needed;
                      return ListTile(
                        title: Text(unit),
                        subtitle: Text('Needed: $needed'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => setState(() => _producedQuantities[key] = (prod > 0 ? prod - 1 : 0)),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                '$prod',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: prod > needed ? AppColors.success : (prod < needed ? AppColors.error : AppColors.textPrimary),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => _producedQuantities[key] = prod + 1),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final List<ProductionBatchItem> items = [];
                _producedQuantities.forEach((key, qty) {
                  if (qty > 0) {
                    final parts = key.split('_');
                    items.add(ProductionBatchItem(
                      productId: parts[0],
                      variantUnit: parts[1],
                      quantity: qty,
                    ));
                  }
                });
                context.read<StockPlannerBloc>().add(ConfirmProductionEvent(items));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Production confirmed and stock updated!')));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSizes.md),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & Add to Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkBookingReviewSheet extends StatelessWidget {
  final List<Product> products;
  final List<DailyRequirement> requirements;

  const _BulkBookingReviewSheet({required this.products, required this.requirements});

  @override
  Widget build(BuildContext context) {
    final activeRequirements = requirements.where((r) => r.items.isNotEmpty).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      padding: EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, MediaQuery.of(context).padding.bottom + AppSizes.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: AppSizes.md),
          Text('Review Bulk Booking', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Text('The following customer needs will be converted into official orders.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.md),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: activeRequirements.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final req = activeRequirements[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(req.customerName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(req.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(req.items.map((i) => '${i.quantity} x ${i.unit}').join(', ')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.infoLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: AppSizes.md),
                const Expanded(
                  child: Text(
                    'Confirming will deduct stock and update customer totals automatically.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<StockPlannerBloc>().add(ConvertRequirementsToBookingsEvent(activeRequirements));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSizes.md),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
              child: const Text('Confirm & Book All', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSaleSheet extends StatefulWidget {
  const _QuickSaleSheet();

  @override
  State<_QuickSaleSheet> createState() => _QuickSaleSheetState();
}

class _QuickSaleSheetState extends State<_QuickSaleSheet> {
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
          Text('Random Customer Sale', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
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
                final products = (context.read<ProductBloc>().state as ProductLoaded).products;

                _selectedQuantities.forEach((key, qty) {
                  if (qty > 0) {
                    final parts = key.split('_');
                    final pid = parts[0];
                    final unit = parts[1];
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
