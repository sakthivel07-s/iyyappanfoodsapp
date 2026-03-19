import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/add_product_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../domain/usecases/update_stock_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class ProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProductsEvent extends ProductEvent {}
class AddProductEvent extends ProductEvent {
  final Product product;
  AddProductEvent(this.product);
  @override List<Object?> get props => [product];
}
class UpdateProductEvent extends ProductEvent {
  final Product product;
  UpdateProductEvent(this.product);
  @override List<Object?> get props => [product];
}
class DeleteProductEvent extends ProductEvent {
  final String id;
  DeleteProductEvent(this.id);
  @override List<Object?> get props => [id];
}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class ProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateStockEvent extends ProductEvent {
  final String productId;
  final String variantUnit;
  final int newStock;
  UpdateStockEvent(this.productId, this.variantUnit, this.newStock);
  @override List<Object?> get props => [productId, variantUnit, newStock];
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<Product> products;
  ProductLoaded(this.products);
  @override List<Object?> get props => [products];
}
class ProductOperationSuccess extends ProductState {
  final String message;
  ProductOperationSuccess(this.message);
  @override List<Object?> get props => [message];
}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
  @override List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase getProductsUseCase;
  final AddProductUseCase addProductUseCase;
  final UpdateProductUseCase updateProductUseCase;
  final DeleteProductUseCase deleteProductUseCase;

  StreamSubscription? _subscription;

  ProductBloc({
    required this.getProductsUseCase,
    required this.addProductUseCase,
    required this.updateProductUseCase,
    required this.deleteProductUseCase,
  }) : super(ProductInitial()) {
    on<LoadProductsEvent>(_onLoad);
    on<AddProductEvent>(_onAdd);
    on<UpdateProductEvent>(_onUpdate);
    on<DeleteProductEvent>(_onDelete);
    on<UpdateStockEvent>(_onUpdateStock);
  }

  void _onLoad(LoadProductsEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    await emit.forEach<Either<Failure, List<Product>>>(
      getProductsUseCase(),
      onData: (result) => result.fold(
        (failure) => ProductError(failure.message),
        (products) => ProductLoaded(products),
      ),
    );
  }

  void _onAdd(AddProductEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    final result = await addProductUseCase(event.product);
    result.fold(
      (f) => emit(ProductError(f.message)),
      (_) => emit(ProductOperationSuccess('Product added successfully')),
    );
  }

  void _onUpdateStock(UpdateStockEvent event, Emitter<ProductState> emit) async {
    final currentState = state;
    final result = await GetIt.I<UpdateStockUseCase>().call(event.productId, event.variantUnit, event.newStock);
    result.fold(
      (f) {
        emit(ProductError(f.message));
        if (currentState is ProductLoaded) {
          emit(currentState);
        }
      },
      (_) {
        add(LoadProductsEvent());
      },
    );
  }

  void _onUpdate(UpdateProductEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    final result = await updateProductUseCase(event.product);
    result.fold(
      (f) => emit(ProductError(f.message)),
      (_) => emit(ProductOperationSuccess('Product updated successfully')),
    );
  }

  void _onDelete(DeleteProductEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    final result = await deleteProductUseCase(event.id);
    result.fold(
      (f) => emit(ProductError(f.message)),
      (_) => emit(ProductOperationSuccess('Product deleted')),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
