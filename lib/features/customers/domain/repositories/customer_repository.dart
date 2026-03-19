import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/customer.dart';

abstract class CustomerRepository {
  Stream<Either<Failure, List<Customer>>> getCustomers();
  Future<Either<Failure, Customer>> getCustomerById(String id);
  Future<Either<Failure, void>> addCustomer(Customer customer);
  Future<Either<Failure, void>> updateCustomer(Customer customer);
  Future<Either<Failure, void>> deleteCustomer(String id);
  Future<Either<Failure, void>> updateCustomerStats(
      String id, double addedAmount);
}
