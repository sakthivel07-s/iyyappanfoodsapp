import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class AddCustomerUseCase {
  final CustomerRepository _repository;
  AddCustomerUseCase(this._repository);
  Future<Either<Failure, void>> call(Customer customer) =>
      _repository.addCustomer(customer);
}
