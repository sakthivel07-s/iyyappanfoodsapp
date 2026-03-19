import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository _repository;
  GetProductsUseCase(this._repository);
  Stream<Either<Failure, List<Product>>> call() => _repository.getProducts();
}
