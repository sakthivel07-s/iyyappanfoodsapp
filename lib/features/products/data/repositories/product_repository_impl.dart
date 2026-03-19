import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _dataSource;
  ProductRepositoryImpl(this._dataSource);

  @override
  Stream<Either<Failure, List<Product>>> getProducts() =>
      _dataSource.getProducts();

  @override
  Future<Either<Failure, void>> addProduct(Product product) {
    final now = DateTime.now();
    final model = ProductModel(
      id: product.id.isEmpty ? const Uuid().v4() : product.id,
      name: product.name,
      description: product.description,
      variants: product.variants,
      isActive: product.isActive,
      createdAt: now,
      updatedAt: now,
    );
    return _dataSource.addProduct(model);
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) {
    final model = ProductModel(
      id: product.id,
      name: product.name,
      description: product.description,
      variants: product.variants,
      isActive: product.isActive,
      createdAt: product.createdAt,
      updatedAt: DateTime.now(),
    );
    return _dataSource.updateProduct(model);
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) =>
      _dataSource.deleteProduct(id);

  @override
  Future<Either<Failure, void>> updateStock(String productId, String variantUnit, int newStock) =>
      _dataSource.updateStock(productId, variantUnit, newStock);

  @override
  Future<Either<Failure, void>> addStock(String productId, String variantUnit, int increment) =>
      _dataSource.addStock(productId, variantUnit, increment);

  @override
  Future<Either<Failure, void>> deductStock(List<StockDeduction> items) =>
      _dataSource.deductStock(items);
}
