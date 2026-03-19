import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/entities/sales_report.dart';
import '../bloc/analytics_bloc.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateRangeModel _selectedRange = AppDateUtils.getThisMonth();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnalyticsBloc>()..add(LoadAnalyticsEvent(_selectedRange)),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.analytics),
            ),
            body: Column(
              children: [
                _buildFilterBar(context),
                Expanded(
                  child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
                    builder: (context, state) {
                      if (state is AnalyticsLoading) return const Center(child: CircularProgressIndicator());
                      if (state is AnalyticsError) return ErrorStateWidget(message: state.message);
                      if (state is AnalyticsLoaded) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<AnalyticsBloc>().add(LoadAnalyticsEvent(_selectedRange));
                          },
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              children: [
                                _OverviewStats(report: state.report),
                                const SizedBox(height: AppSizes.lg),
                                _SalesChart(dailySales: state.report.dailyBreakdown),
                                const SizedBox(height: AppSizes.lg),
                                _TopProductsList(products: state.report.topProducts),
                                const SizedBox(height: AppSizes.lg),
                                _TopCustomersList(customers: state.report.topCustomers),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final options = [
      AppDateUtils.getToday(),
      AppDateUtils.getYesterday(),
      AppDateUtils.getThisWeek(),
      AppDateUtils.getLastWeek(),
      AppDateUtils.getThisMonth(),
      AppDateUtils.getLastMonth(),
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        children: [
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(opt.label),
              selected: _selectedRange.label == opt.label,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedRange = opt);
                  context.read<AnalyticsBloc>().add(LoadAnalyticsEvent(opt));
                }
              },
              selectedColor: AppColors.primaryLight,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: _selectedRange.label == opt.label ? AppColors.primary : AppColors.textSecondary,
                fontWeight: _selectedRange.label == opt.label ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          )),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Custom'),
              selected: !options.any((o) => o.label == _selectedRange.label),
              onSelected: (_) => _showCustomDateRange(context),
              selectedColor: AppColors.primaryLight,
              backgroundColor: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _selectedRange.start, end: _selectedRange.end),
    );
    if (picked != null) {
      final range = AppDateUtils.getCustomRange(picked.start, picked.end);
      setState(() => _selectedRange = range);
      if (mounted) {
        context.read<AnalyticsBloc>().add(LoadAnalyticsEvent(range));
      }
    }
  }

}

class _OverviewStats extends StatelessWidget {
  final SalesReport report;
  const _OverviewStats({required this.report});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSizes.md,
      mainAxisSpacing: AppSizes.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        SummaryCard(
          title: 'Total Revenue',
          value: CurrencyFormatter.formatCompact(report.totalRevenue),
          icon: Icons.payments_outlined,
          backgroundColor: Colors.orange.shade50,
          iconColor: Colors.orange,
        ),
        SummaryCard(
          title: 'Total Orders',
          value: report.totalOrders.toString(),
          icon: Icons.shopping_bag_outlined,
          backgroundColor: Colors.blue.shade50,
          iconColor: Colors.blue,
        ),
        SummaryCard(
          title: 'Unique Customers',
          value: report.totalCustomers.toString(),
          icon: Icons.people_outline_rounded,
          backgroundColor: Colors.purple.shade50,
          iconColor: Colors.purple,
        ),
        SummaryCard(
          title: 'Avg Order Value',
          value: CurrencyFormatter.formatCompact(report.avgOrderValue),
          icon: Icons.analytics_outlined,
          backgroundColor: Colors.green.shade50,
          iconColor: Colors.green,
        ),
      ],
    );
  }
}

class _SalesChart extends StatelessWidget {
  final List<DailySales> dailySales;
  const _SalesChart({required this.dailySales});

  @override
  Widget build(BuildContext context) {
    if (dailySales.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Trend', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.md),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(dailySales.length, (i) => FlSpot(i.toDouble(), dailySales[i].revenue)),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsList extends StatelessWidget {
  final List<ProductAnalytics> products;
  const _TopProductsList({required this.products});

  @override
  Widget build(BuildContext context) {
    return _AnalyticsListCard(
      title: 'Top Products',
      items: products.take(5).map((p) => _AnalyticsItem(
            title: p.productName,
            subtitle: '${p.totalQuantity} items sold',
            value: CurrencyFormatter.formatCompact(p.totalRevenue),
          )).toList(),
    );
  }
}

class _TopCustomersList extends StatelessWidget {
  final List<CustomerAnalytics> customers;
  const _TopCustomersList({required this.customers});

  @override
  Widget build(BuildContext context) {
    return _AnalyticsListCard(
      title: 'Top Customers',
      items: customers.take(5).map((c) => _AnalyticsItem(
            title: c.customerName,
            subtitle: '${c.orderCount} orders',
            value: CurrencyFormatter.formatCompact(c.totalSpent),
            onTap: (context) => context.push('/customers/${c.customerId}/analytics?name=${Uri.encodeComponent(c.customerName)}'),
          )).toList(),
    );
  }
}

class _AnalyticsListCard extends StatelessWidget {
  final String title;
  final List<_AnalyticsItem> items;
  const _AnalyticsListCard({required this.title, required this.items});

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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          ...items.map((item) => InkWell(
                onTap: () => item.onTap?.call(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text(item.value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _AnalyticsItem {
  final String title;
  final String subtitle;
  final String value;
  final Function(BuildContext)? onTap;
  _AnalyticsItem({required this.title, required this.subtitle, required this.value, this.onTap});
}

