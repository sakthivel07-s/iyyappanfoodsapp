import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_bookings_usecase.dart';
import '../../domain/usecases/update_booking_status_usecase.dart';
import '../../domain/usecases/get_booking_by_id_usecase.dart';
import '../../../customers/domain/usecases/get_customer_by_id_usecase.dart';
import '../../../products/domain/usecases/update_stock_usecase.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../customers/domain/usecases/update_customer_stats_usecase.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../../core/utils/app_date_utils.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class BookingEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadBookingsEvent extends BookingEvent {
  final DateRangeModel? dateRange;
  final String? status;
  final String? customerId;
  LoadBookingsEvent({this.dateRange, this.status, this.customerId});
  @override List<Object?> get props => [dateRange, status, customerId];
}

class LoadSingleBookingEvent extends BookingEvent {
  final String id;
  LoadSingleBookingEvent(this.id);
  @override List<Object?> get props => [id];
}

class LoadCustomerForDirectionsEvent extends BookingEvent {
  final String customerId;
  LoadCustomerForDirectionsEvent(this.customerId);
  @override List<Object?> get props => [customerId];
}

class CreateBookingEvent extends BookingEvent {
  final Booking booking;
  CreateBookingEvent(this.booking);
  @override List<Object?> get props => [booking];
}

class UpdateBookingStatusEvent extends BookingEvent {
  final String id;
  final String status;
  UpdateBookingStatusEvent(this.id, this.status);
  @override List<Object?> get props => [id, status];
}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class BookingState extends Equatable {
  @override List<Object?> get props => [];
}

class BookingInitial extends BookingState {}
class BookingLoading extends BookingState {}
class BookingLoaded extends BookingState {
  final List<Booking> bookings;
  BookingLoaded(this.bookings);
  @override List<Object?> get props => [bookings];
}
class BookingCreated extends BookingState {
  final String bookingId;
  BookingCreated(this.bookingId);
  @override List<Object?> get props => [bookingId];
}
class BookingOperationSuccess extends BookingState {
  final String message;
  final dynamic extra; // Optional extra data (e.g. Customer)
  BookingOperationSuccess(this.message, {this.extra});
  @override List<Object?> get props => [message, extra];
}
class BookingError extends BookingState {
  final String message;
  BookingError(this.message);
  @override List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final CreateBookingUseCase createBookingUseCase;
  final GetBookingsUseCase getBookingsUseCase;
  final UpdateBookingStatusUseCase updateBookingStatusUseCase;
  final GetProductsUseCase getProductsUseCase;
  final UpdateCustomerStatsUseCase updateCustomerStatsUseCase;
  final GetBookingByIdUseCase getBookingByIdUseCase;
  final GetCustomerByIdUseCase getCustomerByIdUseCase;

  BookingBloc({
    required this.createBookingUseCase,
    required this.getBookingsUseCase,
    required this.updateBookingStatusUseCase,
    required this.getProductsUseCase,
    required this.updateCustomerStatsUseCase,
    required this.getBookingByIdUseCase,
    required this.getCustomerByIdUseCase,
  }) : super(BookingInitial()) {
    on<LoadBookingsEvent>(_onLoad);
    on<CreateBookingEvent>(_onCreate);
    on<UpdateBookingStatusEvent>(_onUpdateStatus);
    on<LoadSingleBookingEvent>(_onLoadSingle);
    on<LoadCustomerForDirectionsEvent>(_onLoadCustomer);
  }

  void _onLoad(LoadBookingsEvent event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    await emit.forEach<Either<Failure, List<Booking>>>(
      getBookingsUseCase(
        dateRange: event.dateRange ?? AppDateUtils.getToday(),
        status: event.status,
        customerId: event.customerId,
      ),
      onData: (result) => result.fold(
        (f) => BookingError(f.message),
        (list) => BookingLoaded(list),
      ),
    );
  }

  void _onCreate(CreateBookingEvent event, Emitter<BookingState> emit) async {
    emit(BookingLoading());

    // 1. Stock Validation
    final productsResult = await getProductsUseCase().first;
    String? stockError;
    
    productsResult.fold(
      (f) => stockError = f.message,
      (products) {
        for (final item in event.booking.items) {
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
      emit(BookingError(stockError!));
      return;
    }

    // 2. Create Booking
    final result = await createBookingUseCase(event.booking);
    result.fold(
      (f) => emit(BookingError(f.message)),
      (_) async {
        // 3. Automatic stock deduction on creation
        final deductions = event.booking.items.map((item) => StockDeduction(
          productId: item.productId,
          variantUnit: item.unit,
          quantity: item.quantity,
        )).toList();
        await GetIt.I<DeductStockUseCase>().call(deductions);

        // 4. Update Customer Stats
        await updateCustomerStatsUseCase(event.booking.customerId, event.booking.grandTotal);
        
        emit(BookingOperationSuccess('Booking created successfully'));
        add(LoadBookingsEvent(dateRange: null));
      },
    );
  }

  void _onLoadSingle(LoadSingleBookingEvent event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    final result = await getBookingByIdUseCase(event.id);
    result.fold(
      (f) => emit(BookingError(f.message)),
      (booking) {
        if (booking != null) {
          emit(BookingLoaded([booking]));
        } else {
          emit(BookingError('Booking not found'));
        }
      },
    );
  }

  void _onUpdateStatus(UpdateBookingStatusEvent event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    final result = await updateBookingStatusUseCase(event.id, event.status);
    result.fold(
      (f) => emit(BookingError(f.message)),
      (_) {
        emit(BookingOperationSuccess('Status updated'));
        // Reload the specific booking to refresh UI
        add(LoadSingleBookingEvent(event.id));
      },
    );
  }

  void _onLoadCustomer(LoadCustomerForDirectionsEvent event, Emitter<BookingState> emit) async {
    final result = await getCustomerByIdUseCase(event.customerId);
    result.fold(
      (f) => emit(BookingError(f.message)),
      (customer) {
        if (customer != null) {
          emit(BookingOperationSuccess('Customer loaded', extra: customer));
        } else {
          emit(BookingError('Customer not found'));
        }
      },
    );
  }
}
