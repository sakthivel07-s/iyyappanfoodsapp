import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class UpdateProductUseCase {
  final ProductRepository _repository;
  UpdateProductUseCase(this._repository);
  Future<Either<Failure, void>> call(Product product) => _repository.updateProduct(product);
}
