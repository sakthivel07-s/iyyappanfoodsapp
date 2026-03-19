import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../bookings/presentation/bloc/booking_bloc.dart';
import '../bloc/customer_bloc.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<CustomerBloc>()..add(LoadCustomersEvent()),
        ),
        BlocProvider(
          create: (_) => sl<BookingBloc>()
            ..add(LoadBookingsEvent(customerId: customerId, dateRange: null)),
        ),
      ],
      child: _CustomerDetailView(customerId: customerId),
    );
  }
}

class _CustomerDetailView extends StatelessWidget {
  final String customerId;
  const _CustomerDetailView({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is CustomerLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (state is CustomerLoaded) {
          final customer = state.customers
              .where((c) => c.id == customerId)
              .firstOrNull;
          if (customer == null) {
            return const Scaffold(body: ErrorStateWidget(message: 'Customer not found'));
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(customer.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  tooltip: 'View Reports',
                  onPressed: () => context.push('/customers/${customer.id}/analytics?name=${Uri.encodeComponent(customer.name)}'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/customers/edit/${customer.id}'),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _CustomerInfoCard(customer: customer),
                  const SizedBox(height: AppSizes.md),
                  _CustomerStats(customer: customer),
                  const SizedBox(height: AppSizes.md),
                  _buildLedgerAction(context, customer),
                  const SizedBox(height: AppSizes.lg),
                  const SectionHeader(title: 'Order History'),
                  const SizedBox(height: AppSizes.sm),
                  _CustomerOrdersList(),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.push('/bookings/create', extra: customer),
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('New Order'),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLedgerAction(BuildContext context, dynamic customer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.successLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.successLight,
            child: const Icon(Icons.account_balance_rounded, color: AppColors.success),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ledger & Payments', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('View statements and collect payments', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/customers/${customer.id}/ledger', extra: customer),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('View List'),
          ),
        ],
      ),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  final dynamic customer;
  const _CustomerInfoCard({required this.customer});

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
        children: [
          _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: customer.phone),
          const Divider(height: AppSizes.lg),
          _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: customer.address.isEmpty ? 'Not provided' : customer.address),
          const Divider(height: AppSizes.lg),
          _InfoRow(icon: Icons.sticky_note_2_outlined, label: 'Notes', value: customer.notes.isEmpty ? 'No notes' : customer.notes),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomerStats extends StatelessWidget {
  final dynamic customer;
  const _CustomerStats({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: AppStrings.totalSpent,
            value: CurrencyFormatter.formatCompact(customer.totalSpent),
            icon: Icons.account_balance_wallet_outlined,
            backgroundColor: AppColors.primaryLighter,
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: SummaryCard(
            title: AppStrings.totalOrders,
            value: customer.orderCount.toString(),
            icon: Icons.shopping_basket_outlined,
            backgroundColor: AppColors.infoLight,
            iconColor: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _CustomerOrdersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return const ShimmerCard(height: 200);
        }
        if (state is BookingLoaded) {
          if (state.bookings.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.xl),
                child: Text('No orders found for this customer'),
              ),
            );
          }
          return Column(
            children: state.bookings
                .map((b) => _BookingItemTile(booking: b))
                .toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BookingItemTile extends StatelessWidget {
  final dynamic booking;
  const _BookingItemTile({required this.booking});

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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppDateUtils.formatDate(booking.bookingDate),
                    style: Theme.of(context).textTheme.titleSmall),
                Text('${booking.items.length} items',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: booking.status),
              const SizedBox(height: 4),
              Text(CurrencyFormatter.format(booking.grandTotal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      )),
            ],
          ),
        ],
      ),
    );
  }
}
