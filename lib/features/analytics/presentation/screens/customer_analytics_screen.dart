import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../bloc/analytics_bloc.dart';
import '../../domain/entities/sales_report.dart';

class CustomerAnalyticsScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerAnalyticsScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerAnalyticsScreen> createState() => _CustomerAnalyticsScreenState();
}

class _CustomerAnalyticsScreenState extends State<CustomerAnalyticsScreen> {
  DateRangeModel _selectedRange = AppDateUtils.getThisMonth();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnalyticsBloc>()..add(LoadAnalyticsEvent(_selectedRange, customerId: widget.customerId)),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${widget.customerName} Report'),
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
                            context.read<AnalyticsBloc>().add(LoadAnalyticsEvent(_selectedRange, customerId: widget.customerId));
                          },
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              children: [
                                _CustomerOverviewStats(report: state.report),
                                const SizedBox(height: AppSizes.lg),
                                _CustomerSalesChart(dailySales: state.report.dailyBreakdown),
                                const SizedBox(height: AppSizes.lg),
                                _CustomerTopProductsList(products: state.report.topProducts),
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
                  context.read<AnalyticsBloc>().add(LoadAnalyticsEvent(opt, customerId: widget.customerId));
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
        context.read<AnalyticsBloc>().add(LoadAnalyticsEvent(range, customerId: widget.customerId));
      }
    }
  }

}

class _CustomerOverviewStats extends StatelessWidget {
  final SalesReport report;
  const _CustomerOverviewStats({required this.report});

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
          title: 'Total Spent',
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
          title: 'Days Active',
          value: report.dailyBreakdown.length.toString(),
          icon: Icons.today_outlined,
          backgroundColor: Colors.purple.shade50,
          iconColor: Colors.purple,
        ),
        SummaryCard(
          title: 'Avg per Order',
          value: CurrencyFormatter.formatCompact(report.avgOrderValue),
          icon: Icons.analytics_outlined,
          backgroundColor: Colors.green.shade50,
          iconColor: Colors.green,
        ),
      ],
    );
  }
}

class _CustomerSalesChart extends StatelessWidget {
  final List<DailySales> dailySales;
  const _CustomerSalesChart({required this.dailySales});

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
          const Text('Spending Trend', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _CustomerTopProductsList extends StatelessWidget {
  final List<ProductAnalytics> products;
  const _CustomerTopProductsList({required this.products});

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
          const Text('Favorite Products', style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          ...products.take(5).map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('${p.totalQuantity} items bought', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text(CurrencyFormatter.formatCompact(p.totalRevenue), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

