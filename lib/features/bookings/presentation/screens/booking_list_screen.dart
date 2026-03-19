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
import '../bloc/booking_bloc.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  DateRangeModel _selectedRange = AppDateUtils.getToday();
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingBloc>()
        ..add(LoadBookingsEvent(dateRange: _selectedRange, status: _selectedStatus)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.bookings),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: () => _showDateFilter(context),
              ),
            ),
          ],
        ),
        body: Builder(
          builder: (context) => Column(
            children: [
              _buildFilters(context),
              Expanded(child: _BookingList()),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/bookings/create'),
          child: const Icon(Icons.add_shopping_cart_rounded),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      height: 60, // Slight increase for better spacing
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        children: [
          _FilterChip(
            label: _selectedRange.label,
            selected: true,
            onSelected: () => _showDateFilter(context),
            icon: Icons.calendar_today_rounded,
          ),
          const SizedBox(width: AppSizes.sm),
          _FilterChip(
            label: 'All Status',
            selected: _selectedStatus == null,
            onSelected: () => _setStatus(context, null),
          ),
          const SizedBox(width: AppSizes.sm),
          _FilterChip(
            label: 'Pending',
            selected: _selectedStatus == 'pending',
            onSelected: () => _setStatus(context, 'pending'),
          ),
          const SizedBox(width: AppSizes.sm),
          _FilterChip(
            label: 'Confirmed',
            selected: _selectedStatus == 'confirmed',
            onSelected: () => _setStatus(context, 'confirmed'),
          ),
          const SizedBox(width: AppSizes.sm),
          _FilterChip(
            label: 'Delivered',
            selected: _selectedStatus == 'delivered',
            onSelected: () => _setStatus(context, 'delivered'),
          ),
        ],
      ),
    );
  }

  void _setStatus(BuildContext context, String? status) {
    setState(() => _selectedStatus = status);
    context.read<BookingBloc>().add(LoadBookingsEvent(
          dateRange: _selectedRange,
          status: _selectedStatus,
        ));
  }

  void _showDateFilter(BuildContext context) async {
    final range = await showModalBottomSheet<DateRangeModel>(
      context: context,
      builder: (_) => _DateFilterSheet(selectedRange: _selectedRange),
    );
    if (range != null) {
      setState(() => _selectedRange = range);
      if (!mounted) return;
      context.read<BookingBloc>().add(LoadBookingsEvent(
            dateRange: _selectedRange,
            status: _selectedStatus,
          ));
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: icon != null ? Icon(icon, size: 16, color: selected ? Colors.white : AppColors.primary) : null,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      ),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _BookingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (_, __) => const ShimmerCard(height: 80),
          );
        }
        if (state is BookingLoaded) {
          if (state.bookings.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No bookings found',
              subtitle: 'Try a different date range or status filter.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: state.bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (_, i) => _BookingListTile(booking: state.bookings[i]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BookingListTile extends StatelessWidget {
  final dynamic booking;
  const _BookingListTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/bookings/${booking.id}'),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.customerName, style: Theme.of(context).textTheme.titleMedium),
                  Text('${booking.items.length} item(s) • ${AppDateUtils.formatDateTime(booking.bookingDate)}',
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

class _DateFilterSheet extends StatelessWidget {
  final DateRangeModel selectedRange;
  const _DateFilterSheet({required this.selectedRange});

  @override
  Widget build(BuildContext context) {
    final options = [
      AppDateUtils.getToday(),
      AppDateUtils.getYesterday(),
      AppDateUtils.getThisWeek(),
      AppDateUtils.getLastWeek(),
      AppDateUtils.getThisMonth(),
      AppDateUtils.getLastMonth(),
      AppDateUtils.getThisYear(),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: Text('Select Date Range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...options.map((opt) => ListTile(
                  title: Text(opt.label),
                  selected: selectedRange.label == opt.label,
                  onTap: () => Navigator.pop(context, opt),
                )),
            ListTile(
              title: const Text('Custom Range'),
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  Navigator.pop(context, AppDateUtils.getCustomRange(picked.start, picked.end));
                }
              },
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }
}
