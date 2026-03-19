import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../customers/domain/usecases/get_customer_by_id_usecase.dart';
import '../../domain/entities/booking.dart';
import '../bloc/booking_bloc.dart';
import '../pdf/bill_pdf_generator.dart';

class BookingDetailScreen extends StatelessWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingBloc>()..add(LoadSingleBookingEvent(bookingId)),
      child: _BookingDetailView(bookingId: bookingId),
    );
  }
}

class _BookingDetailView extends StatefulWidget {
  final String bookingId;
  const _BookingDetailView({required this.bookingId});

  @override
  State<_BookingDetailView> createState() => _BookingDetailViewState();
}

class _BookingDetailViewState extends State<_BookingDetailView> {
  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        Booking? booking;
        if (state is BookingLoaded) {
          booking = state.bookings.where((b) => b.id == widget.bookingId).firstOrNull;
        }

        if (state is BookingLoading && booking == null) {
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (booking == null && state is! BookingLoading) {
           return const Scaffold(body: ErrorStateWidget(message: 'Booking not found'));
        }

        if (booking != null) {
          final b = booking; // Local variable for promotion
          return Scaffold(
            appBar: AppBar(
              title: const Text('Order Details'),
              actions: [
                if (_isGeneratingPdf)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () => _generateBill(b),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  _StatusHeader(booking: b),
                  const SizedBox(height: AppSizes.md),
                  _CustomerSummary(booking: b),
                  const SizedBox(height: AppSizes.md),
                  _ItemsList(booking: b),
                  const SizedBox(height: AppSizes.md),
                  _CostBreakdown(booking: b),
                  const SizedBox(height: AppSizes.xl),
                  _ActionButtons(booking: b, state: state, onGetDirections: () => _openMap(context, b.customerId)),
                ],
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  void _generateBill(Booking booking) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await BillPdfGenerator.generate(booking);
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _openMap(BuildContext context, String customerId) async {
    final getCustomerByIdUseCase = sl<GetCustomerByIdUseCase>();
    final result = await getCustomerByIdUseCase(customerId);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${f.message}'))),
      (customer) {
        if (customer != null) {
          _launchMaps(customer.address);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer not found')));
        }
      },
    );
  }

  Future<void> _launchMaps(String address) async {
    if (address.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer address is empty')));
      }
      return;
    }
    
    Uri? directUri;
    
    if (address.startsWith('http://') || address.startsWith('https://')) {
      directUri = Uri.parse(address);
    } else {
      final encodedAddress = Uri.encodeComponent(address);
      directUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encodedAddress');
    }

    try {
      if (await canLaunchUrl(directUri)) {
        await launchUrl(directUri, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch maps';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening maps: $e')));
      }
    }
  }
}

class _StatusHeader extends StatelessWidget {
  final Booking booking;
  const _StatusHeader({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text('Status', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              StatusBadge(status: booking.status),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Date & Time', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(AppDateUtils.formatDateTime(booking.bookingDate), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerSummary extends StatelessWidget {
  final Booking booking;
  const _CustomerSummary({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(color: AppColors.primaryLighter, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(booking.customerPhone, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  final Booking booking;
  const _ItemsList({required this.booking});

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
          const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          ...booking.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('${item.quantity} x ${item.unit} @ ${CurrencyFormatter.format(item.unitPrice)}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text(CurrencyFormatter.format(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _CostBreakdown extends StatelessWidget {
  final Booking booking;
  const _CostBreakdown({required this.booking});

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
          _CostRow(label: 'Subtotal', value: booking.subtotal),
          if (booking.discount > 0) _CostRow(label: 'Discount', value: -booking.discount, color: AppColors.success),
          const Divider(height: AppSizes.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              Text(CurrencyFormatter.format(booking.grandTotal),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  const _CostRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(CurrencyFormatter.format(value), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Booking booking;
  final BookingState state;
  final VoidCallback onGetDirections;
  const _ActionButtons({required this.booking, required this.state, required this.onGetDirections});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BookingBloc>();
    return Column(
      children: [
        if (booking.status == 'confirmed')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state is BookingLoading
                  ? null
                  : () => bloc.add(UpdateBookingStatusEvent(booking.id, 'delivered')),
              icon: state is BookingLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded),
              label: const Text('Mark as Delivered'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
          ),
        const SizedBox(height: AppSizes.md),
        if (booking.status != 'cancelled')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGetDirections,
              icon: const Icon(Icons.directions_rounded),
              label: const Text('Get Directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        const SizedBox(height: AppSizes.md),
        if (booking.status != 'cancelled')
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state is BookingLoading
                  ? null
                  : () async {
                      final confirm = await ConfirmDialog.show(context, message: 'Cancel this order?');
                      if (confirm == true) bloc.add(UpdateBookingStatusEvent(booking.id, 'cancelled'));
                    },
              icon: state is BookingLoading && booking.status == 'confirmed'
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cancel_rounded),
              label: const Text('Cancel Order'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
            ),
          ),
      ],
    );
  }
}
