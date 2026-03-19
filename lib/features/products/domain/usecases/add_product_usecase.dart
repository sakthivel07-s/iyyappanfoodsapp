import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class AddProductUseCase {
  final ProductRepository _repository;
  AddProductUseCase(this._repository);
  Future<Either<Failure, void>> call(Product product) => _repository.addProduct(product);
}
