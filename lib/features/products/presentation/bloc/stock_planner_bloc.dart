import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/usecases/get_customers_usecase.dart';
import '../../../customers/domain/usecases/update_customer_stats_usecase.dart';
import '../../domain/entities/daily_requirement.dart';
import '../../domain/usecases/get_daily_requirements_use_case.dart';
import '../../domain/usecases/save_daily_requirement_use_case.dart';
import '../../domain/usecases/add_stock_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/update_stock_usecase.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../bookings/domain/usecases/create_booking_usecase.dart';
import '../../../bookings/domain/entities/booking.dart';
import 'package:uuid/uuid.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class StockPlannerEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadPlannerEvent extends StockPlannerEvent {
  final DateTime date;
  LoadPlannerEvent(this.date);
  @override List<Object?> get props => [date];
}

class SaveCustomerRequirementEvent extends StockPlannerEvent {
  final DailyRequirement requirement;
  SaveCustomerRequirementEvent(this.requirement);
  @override List<Object?> get props => [requirement];
}

class ConfirmProductionEvent extends StockPlannerEvent {
  final List<ProductionBatchItem> items;
  ConfirmProductionEvent(this.items);
  @override List<Object?> get props => [items];
}

class QuickSaleEvent extends StockPlannerEvent {
  final List<BookingItem> items;
  final double subtotal;
  final double discount;
  final double grandTotal;

  QuickSaleEvent({
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.grandTotal,
  });

  @override List<Object?> get props => [items, grandTotal];
}

class ConvertRequirementsToBookingsEvent extends StockPlannerEvent {
  final List<DailyRequirement> requirements;
  ConvertRequirementsToBookingsEvent(this.requirements);
  @override List<Object?> get props => [requirements];
}

class ProductionBatchItem {
  final String productId;
  final String variantUnit;
  final int quantity;
  ProductionBatchItem({required this.productId, required this.variantUnit, required this.quantity});
}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class StockPlannerState extends Equatable {
  @override List<Object?> get props => [];
}

class StockPlannerInitial extends StockPlannerState {}
class StockPlannerLoading extends StockPlannerState {}
class StockPlannerLoaded extends StockPlannerState {
  final List<Customer> customers;
  final List<DailyRequirement> requirements;
  final Map<String, int> totalRequirements; // productId -> quantity
  final DateTime date;

  StockPlannerLoaded({
    required this.customers,
    required this.requirements,
    required this.totalRequirements,
    required this.date,
  });

  @override List<Object?> get props => [customers, requirements, totalRequirements, date];
}

class StockPlannerOperationSuccess extends StockPlannerState {
  final String message;
  StockPlannerOperationSuccess(this.message);
  @override List<Object?> get props => [message];
}

class StockPlannerError extends StockPlannerState {
  final String message;
  StockPlannerError(this.message);
  @override List<Object?> get props => [message];
}

class _InternalRequirementsUpdatedEvent extends StockPlannerEvent {
  final List<DailyRequirement> requirements;
  _InternalRequirementsUpdatedEvent(this.requirements);
  @override List<Object?> get props => [requirements];
}

class _InternalErrorEvent extends StockPlannerEvent {
  final String message;
  _InternalErrorEvent(this.message);
  @override List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class StockPlannerBloc extends Bloc<StockPlannerEvent, StockPlannerState> {
  final GetCustomersUseCase getCustomersUseCase;
  final GetDailyRequirementsUseCase getDailyRequirementsUseCase;
  final SaveDailyRequirementUseCase saveDailyRequirementUseCase;
  final AddStockUseCase addStockUseCase;
  final CreateBookingUseCase createBookingUseCase;
  final GetProductsUseCase getProductsUseCase;
  final DeductStockUseCase deductStockUseCase;
  final UpdateCustomerStatsUseCase updateCustomerStatsUseCase;

  StockPlannerBloc({
    required this.getCustomersUseCase,
    required this.getDailyRequirementsUseCase,
    required this.saveDailyRequirementUseCase,
    required this.addStockUseCase,
    required this.createBookingUseCase,
    required this.getProductsUseCase,
    required this.deductStockUseCase,
    required this.updateCustomerStatsUseCase,
  }) : super(StockPlannerInitial()) {
    on<LoadPlannerEvent>(_onLoad);
    on<SaveCustomerRequirementEvent>(_onSave);
    on<ConfirmProductionEvent>(_onConfirmProduction);
    on<QuickSaleEvent>(_onQuickSale);
    on<_InternalRequirementsUpdatedEvent>(_onRequirementsUpdated);
    on<_InternalErrorEvent>(_onError);
    on<ConvertRequirementsToBookingsEvent>(_onConvertRequirements);
  }

  List<Customer> _cachedCustomers = [];

  void _onLoad(LoadPlannerEvent event, Emitter<StockPlannerState> emit) async {
    emit(StockPlannerLoading());
    
    // 1. Get Customers (once)
    final customersResult = await getCustomersUseCase().first;
    customersResult.fold(
      (failure) {
        emit(StockPlannerError(failure.message));
      },
      (customers) {
        _cachedCustomers = customers;
        // 2. Start listening to requirements
        _startRequirementsSubscription(event.date);
      },
    );
  }

  void _startRequirementsSubscription(DateTime date) {
    getDailyRequirementsUseCase(date).listen((result) {
      result.fold(
        (f) => add(_InternalErrorEvent(f.message)),
        (requirements) => add(_InternalRequirementsUpdatedEvent(requirements)),
      );
    });
  }

  void _onRequirementsUpdated(_InternalRequirementsUpdatedEvent event, Emitter<StockPlannerState> emit) {
    if (state is StockPlannerLoading || state is StockPlannerLoaded) {
      final totals = _calculateTotals(event.requirements);
      DateTime date = DateTime.now();
      if (state is StockPlannerLoaded) date = (state as StockPlannerLoaded).date;
      
      emit(StockPlannerLoaded(
        customers: _cachedCustomers,
        requirements: event.requirements,
        totalRequirements: totals,
        date: date,
      ));
    }
  }

  void _onError(_InternalErrorEvent event, Emitter<StockPlannerState> emit) {
    emit(StockPlannerError(event.message));
  }

  Map<String, int> _calculateTotals(List<DailyRequirement> requirements) {
    final Map<String, int> totals = {};
    for (final req in requirements) {
      for (final item in req.items) {
        totals[item.productId] = (totals[item.productId] ?? 0) + item.quantity;
      }
    }
    return totals;
  }

  Future<void> _onSave(SaveCustomerRequirementEvent event, Emitter<StockPlannerState> emit) async {
    await saveDailyRequirementUseCase(event.requirement);
  }

  Future<void> _onConfirmProduction(ConfirmProductionEvent event, Emitter<StockPlannerState> emit) async {
    emit(StockPlannerLoading());
    try {
      for (final item in event.items) {
        await addStockUseCase(item.productId, item.variantUnit, item.quantity);
      }
      emit(StockPlannerOperationSuccess('Stock updated successfully!'));
      add(LoadPlannerEvent(DateTime.now()));
    } catch (e) {
      emit(StockPlannerError('Failed to update stock: $e'));
      add(LoadPlannerEvent(DateTime.now()));
    }
  }

  Future<void> _onQuickSale(QuickSaleEvent event, Emitter<StockPlannerState> emit) async {
    // 1. Stock Validation
    final productsResult = await getProductsUseCase().first;
    String? stockError;
    
    productsResult.fold(
      (f) => stockError = f.message,
      (products) {
        for (final item in event.items) {
          try {
            final product = products.firstWhere((p) => p.id == item.productId);
            final variant = product.variants.firstWhere((v) => v.unit == item.unit);
            if (variant.stock < item.quantity) {
              stockError = 'Insufficient stock for ${product.name} (${item.unit}). Available: ${variant.stock}';
              break;
            }
          } catch (_) {
            stockError = 'Product or variant not found';
            break;
          }
        }
      },
    );

    if (stockError != null) {
      emit(StockPlannerError(stockError!));
      // Reset state to loaded after a short delay so user can try again
      final currentState = state;
      if (currentState is StockPlannerLoaded) {
        emit(currentState);
      }
      return;
    }

    // 2. Create a booking for 'Walk-in Customer'
    final booking = Booking(
      id: const Uuid().v4(),
      customerId: 'walk-in',
      customerName: 'Walk-in Customer',
      customerPhone: '0000000000',
      bookingDate: DateTime.now(),
      items: event.items,
      subtotal: event.subtotal,
      discount: event.discount,
      grandTotal: event.grandTotal,
      status: 'confirmed',
      notes: 'Quick sale',
      createdAt: DateTime.now(),
    );

    final result = await createBookingUseCase(booking);
    
    if (result.isRight()) {
      // 3. Deduct Stock
      final deductions = event.items.map((item) => StockDeduction(
        productId: item.productId,
        variantUnit: item.unit,
        quantity: item.quantity,
      )).toList();
      await deductStockUseCase(deductions);

      // 4. Update Customer Stats
      if (booking.customerId != 'walk-in') {
        await updateCustomerStatsUseCase(booking.customerId, booking.grandTotal);
      }
      
      emit(StockPlannerOperationSuccess('Quick sale recorded successfully'));
      
      // Re-emit loaded state to refresh UI
      final currentState = state;
      if (currentState is StockPlannerLoaded) {
        emit(currentState);
      }
    } else {
      result.fold(
        (f) => emit(StockPlannerError(f.message)),
        (_) => null,
      );
    }
  }

  Future<void> _onConvertRequirements(ConvertRequirementsToBookingsEvent event, Emitter<StockPlannerState> emit) async {
    emit(StockPlannerLoading());

    // 1. Stock Validation (Total for all requirements)
    final productsResult = await getProductsUseCase().first;
    String? stockError;
    
    await productsResult.fold(
      (f) async => stockError = f.message,
      (products) async {
        // Build a map of total needed per product variant
        final Map<String, int> totalNeeded = {}; // "productId_unit" -> qty
        for (final req in event.requirements) {
          for (final item in req.items) {
            final key = '${item.productId}_${item.unit}';
            totalNeeded[key] = (totalNeeded[key] ?? 0) + item.quantity;
          }
        }

        // Validate each
        for (final entry in totalNeeded.entries) {
          try {
            final parts = entry.key.split('_');
            final product = products.firstWhere((p) => p.id == parts[0]);
            final variant = product.variants.firstWhere((v) => v.unit == parts[1]);
            if (variant.stock < entry.value) {
              stockError = 'Insufficient stock for ${product.name} (${variant.unit}). Available: ${variant.stock}, Needed: ${entry.value}';
              break;
            }
          } catch (_) {
            stockError = 'Product or variant not found';
            break;
          }
        }
      },
    );

    if (stockError != null) {
      emit(StockPlannerError(stockError!));
      add(LoadPlannerEvent(DateTime.now()));
      return;
    }

    // 2. Process each requirement into a booking
    int successCount = 0;
    for (final req in event.requirements) {
      if (req.items.isEmpty) continue;

      double subtotal = 0;
      final List<BookingItem> bookingItems = [];
      
      final products = (await getProductsUseCase().first).getOrElse(() => []);
      
      for (final item in req.items) {
        try {
          final p = products.firstWhere((p) => p.id == item.productId);
          final v = p.variants.firstWhere((v) => v.unit == item.unit);
          bookingItems.add(BookingItem(
            productId: item.productId,
            productName: item.productName,
            unit: item.unit,
            quantity: item.quantity,
            unitPrice: v.price,
            totalPrice: v.price * item.quantity,
          ));
          subtotal += v.price * item.quantity;
        } catch (_) {
          continue;
        }
      }

      if (bookingItems.isEmpty) continue;

      final booking = Booking(
        id: const Uuid().v4(),
        customerId: req.customerId,
        customerName: req.customerName,
        customerPhone: '', 
        bookingDate: DateTime.now(),
        items: bookingItems,
        subtotal: subtotal,
        discount: 0,
        grandTotal: subtotal,
        status: 'confirmed',
        notes: 'Bulk booked from planner',
        createdAt: DateTime.now(),
      );

      final result = await createBookingUseCase(booking);
      if (result.isRight()) {
        final deductions = bookingItems.map((item) => StockDeduction(
          productId: item.productId,
          variantUnit: item.unit,
          quantity: item.quantity,
        )).toList();
        await deductStockUseCase(deductions);
        await updateCustomerStatsUseCase(req.customerId, subtotal);
        successCount++;
        
        // Clear processed requirement
        await saveDailyRequirementUseCase(DailyRequirement(
          id: req.id,
          customerId: req.customerId,
          customerName: req.customerName,
          date: req.date,
          items: const [],
          updatedAt: DateTime.now(),
        ));
      }
    }

    emit(StockPlannerOperationSuccess('$successCount orders booked successfully!'));
    add(LoadPlannerEvent(DateTime.now()));
  }
}
