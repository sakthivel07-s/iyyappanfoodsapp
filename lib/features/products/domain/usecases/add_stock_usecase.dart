import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/product_repository.dart';

class AddStockUseCase {
  final ProductRepository repository;
  AddStockUseCase(this.repository);

  Future<Either<Failure, void>> call(String productId, String variantUnit, int increment) {
    return repository.addStock(productId, variantUnit, increment);
  }
}
