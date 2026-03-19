import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/entities/customer.dart';
import '../bloc/customer_bloc.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
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
      create: (_) => sl<CustomerBloc>()..add(LoadCustomersEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.customers),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              onPressed: () => context.push('/customers/add'),
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
            Expanded(child: _CustomerList(query: _query)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/customers/add'),
          child: const Icon(Icons.person_add_alt_1_rounded),
        ),
      ),
    );
  }
}

class _CustomerList extends StatelessWidget {
  final String query;
  const _CustomerList({required this.query});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is CustomerLoading) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (_, __) => const ShimmerCard(height: 80),
          );
        }
        if (state is CustomerError) {
          return ErrorStateWidget(message: state.message);
        }
        if (state is CustomerLoaded) {
          final customers = state.customers
              .where((c) =>
                  c.name.toLowerCase().contains(query) ||
                  c.phone.contains(query))
              .toList();

          if (customers.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.people_outline_rounded,
              title: AppStrings.noCustomers,
              subtitle: AppStrings.addFirstCustomer,
              actionLabel: AppStrings.addCustomer,
              onAction: () => context.push('/customers/add'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (_, i) => _CustomerCard(customer: customers[i]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CustomerBloc>();
    return InkWell(
      onTap: () => context.push('/customers/${customer.id}'),
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
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Center(
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
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
                  Text(customer.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(customer.phone, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatCompact(customer.totalSpent),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => context.push('/customers/edit/${customer.id}'),
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
                            message: 'Delete "${customer.name}"?');
                        if (confirm == true) {
                          bloc.add(DeleteCustomerEvent(customer.id));
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
