import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/add_customer_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import '../../domain/usecases/delete_customer_usecase.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class CustomerEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadCustomersEvent extends CustomerEvent {}
class AddCustomerEvent extends CustomerEvent {
  final Customer customer;
  AddCustomerEvent(this.customer);
  @override List<Object?> get props => [customer];
}
class UpdateCustomerEvent extends CustomerEvent {
  final Customer customer;
  UpdateCustomerEvent(this.customer);
  @override List<Object?> get props => [customer];
}
class DeleteCustomerEvent extends CustomerEvent {
  final String id;
  DeleteCustomerEvent(this.id);
  @override List<Object?> get props => [id];
}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class CustomerState extends Equatable {
  @override List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}
class CustomerLoading extends CustomerState {}
class CustomerLoaded extends CustomerState {
  final List<Customer> customers;
  CustomerLoaded(this.customers);
  @override List<Object?> get props => [customers];
}
class CustomerOperationSuccess extends CustomerState {
  final String message;
  CustomerOperationSuccess(this.message);
  @override List<Object?> get props => [message];
}
class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
  @override List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final GetCustomersUseCase getCustomersUseCase;
  final AddCustomerUseCase addCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeleteCustomerUseCase deleteCustomerUseCase;

  CustomerBloc({
    required this.getCustomersUseCase,
    required this.addCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deleteCustomerUseCase,
  }) : super(CustomerInitial()) {
    on<LoadCustomersEvent>(_onLoad);
    on<AddCustomerEvent>(_onAdd);
    on<UpdateCustomerEvent>(_onUpdate);
    on<DeleteCustomerEvent>(_onDelete);
  }

  void _onLoad(LoadCustomersEvent event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    await emit.forEach<Either<Failure, List<Customer>>>(
      getCustomersUseCase(),
      onData: (result) => result.fold(
        (f) => CustomerError(f.message),
        (list) => CustomerLoaded(list),
      ),
    );
  }

  void _onAdd(AddCustomerEvent event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    final result = await addCustomerUseCase(event.customer);
    result.fold(
      (f) => emit(CustomerError(f.message)),
      (_) => emit(CustomerOperationSuccess('Customer added')),
    );
  }

  void _onUpdate(UpdateCustomerEvent event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    final result = await updateCustomerUseCase(event.customer);
    result.fold(
      (f) => emit(CustomerError(f.message)),
      (_) => emit(CustomerOperationSuccess('Customer updated')),
    );
  }

  void _onDelete(DeleteCustomerEvent event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    final result = await deleteCustomerUseCase(event.id);
    result.fold(
      (f) => emit(CustomerError(f.message)),
      (_) => emit(CustomerOperationSuccess('Customer deleted')),
    );
  }
}
