import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/customer.dart';
import '../bloc/customer_bloc.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final String? customerId;
  const AddEditCustomerScreen({super.key, this.customerId});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool get _isEdit => widget.customerId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, CustomerBloc bloc) {
    if (!_formKey.currentState!.validate()) return;

    final customer = Customer(
      id: widget.customerId ?? '',
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      totalSpent: 0,
      orderCount: 0,
      createdAt: DateTime.now(),
    );

    if (_isEdit) {
      bloc.add(UpdateCustomerEvent(customer));
    } else {
      bloc.add(AddCustomerEvent(customer));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<CustomerBloc>();
        if (_isEdit) bloc.add(LoadCustomersEvent());
        return bloc;
      },
      child: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            context.pop();
          }
          if (state is CustomerLoaded && _isEdit) {
            final customer = state.customers
                .where((c) => c.id == widget.customerId)
                .firstOrNull;
            if (customer != null) {
              _nameCtrl.text = customer.name;
              _phoneCtrl.text = customer.phone;
              _addressCtrl.text = customer.address;
              _notesCtrl.text = customer.notes;
            }
          }
          if (state is CustomerError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final bloc = context.read<CustomerBloc>();
          return Scaffold(
            appBar: AppBar(
              title: Text(_isEdit ? AppStrings.editCustomer : AppStrings.addCustomer),
              actions: [
                TextButton(
                  onPressed: state is CustomerLoading
                      ? null
                      : () => _submit(context, bloc),
                  child: state is CustomerLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text(AppStrings.save),
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.md),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: AppStrings.customerName,
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: AppSizes.md),
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: AppStrings.phone,
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length < 10) return 'Invalid phone number';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.md),
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: AppStrings.address,
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppSizes.md),
                        TextFormField(
                          controller: _notesCtrl,
                          decoration: const InputDecoration(
                            labelText: AppStrings.notes,
                            prefixIcon: Icon(Icons.sticky_note_2_outlined),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  ElevatedButton(
                    onPressed: state is CustomerLoading
                        ? null
                        : () => _submit(context, bloc),
                    child: state is CustomerLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Update Customer' : 'Add Customer'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
