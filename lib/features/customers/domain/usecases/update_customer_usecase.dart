import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomerUseCase {
  final CustomerRepository _repository;
  UpdateCustomerUseCase(this._repository);
  Future<Either<Failure, void>> call(Customer customer) =>
      _repository.updateCustomer(customer);
}
