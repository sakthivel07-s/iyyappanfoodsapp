import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../bloc/ledger_bloc.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/entities/payment.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_date_utils.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final Customer customer;
  const CustomerLedgerScreen({super.key, required this.customer});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _activeFilter = 'Last 30 Days';

  @override
  void initState() {
    super.initState();
    // Initialize with last 30 days but normalized
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
    _endDate = now;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LedgerBloc>()..add(LoadLedgerEvent(
        customerId: widget.customer.id,
        start: _startDate,
        end: _endDate,
      )),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${widget.customer.name}\'s Ledger'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  onPressed: () {
                    // TODO: Implement PDF Export for statement
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Statement export coming soon!'))
                    );
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                _buildFilterBar(context),
                Expanded(
                  child: BlocBuilder<LedgerBloc, LedgerState>(
                    builder: (context, state) {
                      if (state is LedgerLoading) return const Center(child: CircularProgressIndicator());
                      if (state is LedgerError) return ErrorStateWidget(message: state.message);
                      if (state is LedgerLoaded) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<LedgerBloc>().add(LoadLedgerEvent(
                              customerId: widget.customer.id,
                              start: _startDate,
                              end: _endDate,
                            ));
                          },
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: _buildBalanceSummary(state),
                              ),
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm),
                                  child: SectionHeader(title: 'Transaction History'),
                                ),
                              ),
                              if (state.entries.isEmpty)
                                const SliverFillRemaining(
                                  child: EmptyStateWidget(
                                    icon: Icons.history_rounded,
                                    title: 'No transactions found',
                                    subtitle: 'Try changing the date range.',
                                  ),
                                )
                              else
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final entry = state.entries[index];
                                      return _LedgerEntryTile(entry: entry);
                                    },
                                    childCount: state.entries.length,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showRecordPaymentSheet(context),
              label: const Text('Record Payment'),
              icon: const Icon(Icons.add_rounded),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        children: [
          _FilterChip(
            label: 'Today',
            isActive: _activeFilter == 'Today',
            onTap: () {
              final range = AppDateUtils.getToday();
              _applyFilter(context, 'Today', range.start, range.end);
            },
          ),
          _FilterChip(
            label: 'This Week',
            isActive: _activeFilter == 'This Week',
            onTap: () {
              final range = AppDateUtils.getThisWeek();
              _applyFilter(context, 'This Week', range.start, range.end);
            },
          ),
          _FilterChip(
            label: 'This Month',
            isActive: _activeFilter == 'This Month',
            onTap: () {
              final range = AppDateUtils.getThisMonth();
              _applyFilter(context, 'This Month', range.start, range.end);
            },
          ),
          _FilterChip(
            label: 'Last 30 Days',
            isActive: _activeFilter == 'Last 30 Days',
            onTap: () {
              final now = DateTime.now();
              final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
              _applyFilter(context, 'Last 30 Days', start, now);
            },
          ),
          _FilterChip(
            label: 'Custom',
            isActive: _activeFilter == 'Custom',
            onTap: () => _selectCustomDateRange(context),
          ),
        ],
      ),
    );
  }

  void _applyFilter(BuildContext context, String label, DateTime start, DateTime end) {
    setState(() {
      _activeFilter = label;
      _startDate = start;
      _endDate = end;
    });
    
    // Refresh the ledger data with new dates
    if (mounted) {
      // Use the context passed from build/builder which has the LedgerBloc
      context.read<LedgerBloc>().add(LoadLedgerEvent(
        customerId: widget.customer.id,
        start: _startDate,
        end: _endDate,
      ));
    }
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      _applyFilter(context, 'Custom', picked.start, picked.end);
    }
  }

  Widget _buildBalanceSummary(LedgerLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Pending Balance',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(state.pendingBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Total Billed',
                  value: CurrencyFormatter.format(state.totalBilled),
                  icon: Icons.receipt_long_rounded,
                  backgroundColor: AppColors.infoLight,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: SummaryCard(
                  title: 'Total Paid',
                  value: CurrencyFormatter.format(state.totalPaid),
                  icon: Icons.account_balance_wallet_rounded,
                  backgroundColor: AppColors.successLight,
                  iconColor: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<LedgerBloc>(),
        child: _RecordPaymentSheet(customer: widget.customer),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryLight,
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _LedgerEntryTile extends StatelessWidget {
  final LedgerEntry entry;
  const _LedgerEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final bool isBooking = entry.type == LedgerEntryType.booking;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBooking ? AppColors.infoLight : AppColors.successLight,
          child: Icon(
            isBooking ? Icons.shopping_basket_outlined : Icons.payments_outlined,
            color: isBooking ? AppColors.info : AppColors.success,
          ),
        ),
        title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${DateFormat('dd MMM, yyyy').format(entry.date)} • ${entry.subtitle}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          (isBooking ? '+' : '-') + CurrencyFormatter.format(entry.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isBooking ? AppColors.error : AppColors.success,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _RecordPaymentSheet extends StatefulWidget {
  final Customer customer;
  const _RecordPaymentSheet({required this.customer});

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentMethod = 'Cash';

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
          Text('Record Payment', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text('For ${widget.customer.name}', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.lg),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount Received (₹)',
              prefixIcon: Icon(Icons.currency_rupee_rounded),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              prefixIcon: Icon(Icons.payment_rounded),
            ),
            items: ['Cash', 'UPI', 'Bank Transfer', 'Cheque']
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          const SizedBox(height: AppSizes.md),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              prefixIcon: Icon(Icons.note_add_outlined),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(_amountCtrl.text) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                  return;
                }

                final payment = Payment(
                  id: '',
                  customerId: widget.customer.id,
                  amount: amount,
                  date: DateTime.now(),
                  paymentMethod: _paymentMethod,
                  notes: _notesCtrl.text.trim(),
                );

                context.read<LedgerBloc>().add(RecordPaymentEvent(payment));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSizes.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
              child: const Text('Confirm Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
