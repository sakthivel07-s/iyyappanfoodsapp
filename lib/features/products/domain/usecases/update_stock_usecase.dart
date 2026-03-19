import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/product_repository.dart';

class UpdateStockUseCase {
  final ProductRepository repository;
  UpdateStockUseCase(this.repository);

  Future<Either<Failure, void>> call(String productId, String variantUnit, int newStock) {
    return repository.updateStock(productId, variantUnit, newStock);
  }
}

class DeductStockUseCase {
  final ProductRepository repository;
  DeductStockUseCase(this.repository);

  Future<Either<Failure, void>> call(List<StockDeduction> items) {
    return repository.deductStock(items);
  }
}
