import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/product_repository.dart';

class DeleteProductUseCase {
  final ProductRepository _repository;
  DeleteProductUseCase(this._repository);
  Future<Either<Failure, void>> call(String id) => _repository.deleteProduct(id);
}
