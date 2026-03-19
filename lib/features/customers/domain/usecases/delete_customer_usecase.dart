import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/customer_repository.dart';

class DeleteCustomerUseCase {
  final CustomerRepository _repository;
  DeleteCustomerUseCase(this._repository);
  Future<Either<Failure, void>> call(String id) =>
      _repository.deleteCustomer(id);
}
