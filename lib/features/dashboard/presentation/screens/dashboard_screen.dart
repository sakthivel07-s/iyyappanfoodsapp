import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../../bookings/presentation/bloc/booking_bloc.dart';
import '../../../products/presentation/bloc/stock_planner_bloc.dart';
import '../../../products/presentation/bloc/product_bloc.dart';
import '../../../products/presentation/widgets/quick_sale_sheet.dart';
import '../../../bookings/presentation/pdf/delivery_report_generator.dart';
import 'package:printing/printing.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<BookingBloc>()
            ..add(LoadBookingsEvent(dateRange: AppDateUtils.getToday())),
        ),
        BlocProvider(
          create: (_) => sl<StockPlannerBloc>(),
        ),
        BlocProvider(
          create: (_) => sl<ProductBloc>()..add(LoadProductsEvent()),
        ),
      ],
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockPlannerBloc, StockPlannerState>(
      listener: (context, state) {
        if (state is StockPlannerOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Refresh bookings to show the new walk-in sale
          context.read<BookingBloc>().add(LoadBookingsEvent(dateRange: AppDateUtils.getToday()));
        } else if (state is StockPlannerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.all(AppSizes.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _HeroRevenueCard(),
                  const SizedBox(height: AppSizes.md),
                  _QuickActions(),
                  const SizedBox(height: AppSizes.md),
                  _MoreActions(),
                  const SizedBox(height: AppSizes.md),
                  const SectionHeader(title: AppStrings.recentBookings),
                  const SizedBox(height: AppSizes.sm),
                  _RecentBookingsList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.surface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  )),
          Text(AppDateUtils.formatDate(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 32),
          onPressed: () => context.push('/bookings/create'),
        ),
      ],
    );
  }
}

class _HeroRevenueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        double revenue = 0;
        int total = 0, delivered = 0, confirmed = 0;
        if (state is BookingLoaded) {
          for (final b in state.bookings) {
            revenue += b.grandTotal;
            if (b.status == 'delivered') delivered++;
            if (b.status == 'confirmed') confirmed++;
            total++;
          }
        }
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny_rounded, color: Colors.white70, size: 20),
                  const SizedBox(width: 6),
                  Text(AppStrings.todayRevenue,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                state is BookingLoading
                    ? '---'
                    : CurrencyFormatter.format(revenue),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSizes.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _StatPill(label: AppStrings.todayOrders, value: total.toString()),
                    const SizedBox(width: AppSizes.sm),
                    _StatPill(label: AppStrings.statusDelivered, value: delivered.toString()),
                    const SizedBox(width: AppSizes.sm),
                    _StatPill(label: AppStrings.statusConfirmed, value: confirmed.toString()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        children: [
          Text(value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add_shopping_cart_rounded,
            label: AppStrings.newBooking,
            color: AppColors.primary,
            onTap: () => context.push('/bookings/create'),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _ActionCard(
            icon: Icons.bar_chart_rounded,
            label: AppStrings.viewAnalytics,
            color: AppColors.info,
            onTap: () => context.go('/analytics'),
          ),
        ),
      ],
    );
  }
}

class _MoreActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.inventory_2_rounded,
            label: 'Stock Management',
            color: Colors.orange,
            onTap: () => context.push('/stock'),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _ActionCard(
            icon: Icons.flash_on_rounded,
            label: 'Walk-in Customer',
            color: Colors.purple,
            onTap: () => _showWalkInSaleSheet(context),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _ActionCard(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Delivery Report',
            color: Colors.redAccent,
            onTap: () => _showTodayDeliveryReport(context),
          ),
        ),
      ],
    );
  }

  void _showTodayDeliveryReport(BuildContext context) async {
    final state = context.read<BookingBloc>().state;
    if (state is BookingLoaded) {
      if (state.bookings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No bookings yet today')),
        );
        return;
      }

      final pdfBytes = await DeliveryReportGenerator.generate(
        bookings: state.bookings,
        dateRangeLabel: 'Today (${AppDateUtils.formatDate(DateTime.now())})',
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'delivery_report_today.pdf',
      );
    }
  }

  void _showWalkInSaleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<StockPlannerBloc>()),
          BlocProvider.value(value: context.read<ProductBloc>()),
        ],
        child: const QuickSaleSheet(),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md, horizontal: AppSizes.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentBookingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return Column(
            children: List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: const ShimmerCard(height: 80),
              ),
            ),
          );
        }
        if (state is BookingLoaded) {
          if (state.bookings.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.noBookings,
              subtitle: 'No bookings yet today. Tap + to create one.',
            );
          }
          final recent = state.bookings.take(8).toList();
          return Column(
            children: recent
                .map((b) => _BookingListTile(booking: b))
                .toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BookingListTile extends StatelessWidget {
  final Booking booking;
  const _BookingListTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/bookings/${booking.id}'),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.customerName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${booking.items.length} item(s) • ${AppDateUtils.formatTime(booking.bookingDate)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyFormatter.format(booking.grandTotal),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 4),
                StatusBadge(status: booking.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
