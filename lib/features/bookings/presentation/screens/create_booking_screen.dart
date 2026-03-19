import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/currency_formatter.dart';

import '../../../customers/domain/entities/customer.dart';
import '../../../customers/presentation/bloc/customer_bloc.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/bloc/product_bloc.dart';
import '../../domain/entities/booking.dart';
import '../bloc/booking_bloc.dart';

class CreateBookingScreen extends StatefulWidget {
  final Customer? initialCustomer;
  const CreateBookingScreen({super.key, this.initialCustomer});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  int _currentStep = 0;
  Customer? _selectedCustomer;
  final List<BookingItem> _selectedItems = [];
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomer != null) {
      _selectedCustomer = widget.initialCustomer;
      _currentStep = 1;
    }
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _selectedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _grandTotal => _subtotal - _discount;

  void _addOrUpdateItem(Product product, ProductVariant variant, int qty) {
    setState(() {
      final index = _selectedItems.indexWhere((item) =>
          item.productId == product.id && item.unit == variant.unit);
      if (index >= 0) {
        if (qty <= 0) {
          _selectedItems.removeAt(index);
        } else {
          _selectedItems[index] = BookingItem(
            productId: product.id,
            productName: product.name,
            unit: variant.unit,
            quantity: qty,
            unitPrice: variant.price,
            totalPrice: variant.price * qty,
          );
        }
      } else if (qty > 0) {
        _selectedItems.add(BookingItem(
          productId: product.id,
          productName: product.name,
          unit: variant.unit,
          quantity: qty,
          unitPrice: variant.price,
          totalPrice: variant.price * qty,
        ));
      }
    });
  }

  void _submit(BuildContext context, BookingBloc bloc) {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one product')));
      return;
    }

    final booking = Booking(
      id: '',
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      customerPhone: _selectedCustomer!.phone,
      items: _selectedItems,
      subtotal: _subtotal,
      discount: _discount,
      grandTotal: _grandTotal,
      status: 'confirmed',
      notes: _notesCtrl.text.trim(),
      bookingDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    bloc.add(CreateBookingEvent(booking));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CustomerBloc>()..add(LoadCustomersEvent())),
        BlocProvider(create: (_) => sl<ProductBloc>()..add(LoadProductsEvent())),
        BlocProvider(create: (_) => sl<BookingBloc>()),
      ],
      child: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking created successfully')));
            context.pop();
          }
          if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final bloc = context.read<BookingBloc>();
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.createBooking),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: AppColors.primaryLighter,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
            body: _buildStepContent(),
            bottomNavigationBar: _buildBottomNav(context, bloc, state),
          );
        },
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _StepSelectCustomer(
          onSelected: (c) => setState(() {
            _selectedCustomer = c;
            _currentStep = 1;
          }),
        );
      case 1:
        return _StepAddProducts(
          selectedItems: _selectedItems,
          onQuantityChanged: _addOrUpdateItem,
        );
      case 2:
        return _StepReviewOrder(
          selectedCustomer: _selectedCustomer!,
          selectedItems: _selectedItems,
          subtotal: _subtotal,
          discountCtrl: _discountCtrl,
          notesCtrl: _notesCtrl,
          grandTotal: _grandTotal,
          onDiscountChanged: (_) => setState(() {}),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav(BuildContext context, BookingBloc bloc, BookingState state) {
    if (_currentStep == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _selectedItems.isEmpty && _currentStep == 1
                    ? null
                    : () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _submit(context, bloc);
                        }
                      },
                child: state is BookingLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_currentStep == 2 ? 'Confirm Order' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepSelectCustomer extends StatelessWidget {
  final ValueChanged<Customer> onSelected;
  const _StepSelectCustomer({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is CustomerLoading) return const Center(child: CircularProgressIndicator());
        if (state is CustomerLoaded) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: state.customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (_, i) {
              final c = state.customers[i];
              return ListTile(
                title: Text(c.name),
                subtitle: Text(c.phone),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onSelected(c),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  side: const BorderSide(color: AppColors.border),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _StepAddProducts extends StatelessWidget {
  final List<BookingItem> selectedItems;
  final Function(Product, ProductVariant, int) onQuantityChanged;

  const _StepAddProducts({
    required this.selectedItems,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) return const Center(child: CircularProgressIndicator());
        if (state is ProductLoaded) {
          final activeProducts = state.products.where((p) => p.isActive).toList();
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: activeProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
            itemBuilder: (_, i) {
              final p = activeProducts[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                  ...p.variants.map((v) {
                    final bookingItem = selectedItems.firstWhere(
                      (item) => item.productId == p.id && item.unit == v.unit,
                      orElse: () => BookingItem(
                        productId: p.id,
                        productName: p.name,
                        unit: v.unit,
                        quantity: 0,
                        unitPrice: v.price,
                        totalPrice: 0,
                      ),
                    );
                    return _ProductVariantTile(
                      variant: v,
                      quantity: bookingItem.quantity,
                      onChanged: (q) => onQuantityChanged(p, v, q),
                    );
                  }),
                ],
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ProductVariantTile extends StatelessWidget {
  final ProductVariant variant;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _ProductVariantTile({
    required this.variant,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(variant.unit),
      subtitle: Text(
        '${CurrencyFormatter.format(variant.price)} • Stock: ${variant.stock}',
        style: TextStyle(
          color: variant.stock < 10 ? Colors.red : AppColors.textSecondary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
          ),
          Text(quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepReviewOrder extends StatelessWidget {
  final Customer selectedCustomer;
  final List<BookingItem> selectedItems;
  final double subtotal;
  final TextEditingController discountCtrl;
  final TextEditingController notesCtrl;
  final double grandTotal;
  final ValueChanged<String> onDiscountChanged;

  const _StepReviewOrder({
    required this.selectedCustomer,
    required this.selectedItems,
    required this.subtotal,
    required this.discountCtrl,
    required this.notesCtrl,
    required this.grandTotal,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.md),
      children: [
        _Section(title: 'Customer', children: [
          ListTile(
            title: Text(selectedCustomer.name),
            subtitle: Text(selectedCustomer.phone),
            leading: const Icon(Icons.person_rounded, color: AppColors.primary),
            contentPadding: EdgeInsets.zero,
          ),
        ]),
        const SizedBox(height: AppSizes.md),
        _Section(title: 'Items', children: [
          ...selectedItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text('${item.productName} (${item.unit}) x ${item.quantity}')),
                    Text(CurrencyFormatter.format(item.totalPrice)),
                  ],
                ),
              )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(CurrencyFormatter.format(subtotal)),
            ],
          ),
        ]),
        const SizedBox(height: AppSizes.md),
        _Section(title: 'Payment & Notes', children: [
          TextField(
            controller: discountCtrl,
            decoration: const InputDecoration(labelText: 'Discount (₹)', prefixIcon: Icon(Icons.label_outline_rounded)),
            keyboardType: TextInputType.number,
            onChanged: onDiscountChanged,
          ),
          const SizedBox(height: AppSizes.md),
          TextField(
            controller: notesCtrl,
            decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.note_alt_outlined)),
            maxLines: 2,
          ),
        ]),
        const SizedBox(height: AppSizes.lg),
        Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(CurrencyFormatter.format(grandTotal), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: AppSizes.sm),
        ...children,
      ],
    );
  }
}
