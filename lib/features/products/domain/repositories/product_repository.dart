import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Stream<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, void>> addProduct(Product product);
  Future<Either<Failure, void>> updateProduct(Product product);
  Future<Either<Failure, void>> deleteProduct(String id);
  Future<Either<Failure, void>> updateStock(String productId, String variantUnit, int newStock);
  Future<Either<Failure, void>> addStock(String productId, String variantUnit, int increment);
  Future<Either<Failure, void>> deductStock(List<StockDeduction> items);
}

class StockDeduction {
  final String productId;
  final String variantUnit;
  final int quantity;
  StockDeduction({required this.productId, required this.variantUnit, required this.quantity});
}
