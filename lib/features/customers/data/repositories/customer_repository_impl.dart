import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource _dataSource;
  CustomerRepositoryImpl(this._dataSource);

  @override
  Stream<Either<Failure, List<Customer>>> getCustomers() =>
      _dataSource.getCustomers();

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) =>
      _dataSource.getCustomerById(id);

  @override
  Future<Either<Failure, void>> addCustomer(Customer customer) {
    final model = CustomerModel(
      id: customer.id.isEmpty ? const Uuid().v4() : customer.id,
      name: customer.name,
      phone: customer.phone,
      address: customer.address,
      notes: customer.notes,
      totalSpent: 0,
      orderCount: 0,
      createdAt: DateTime.now(),
    );
    return _dataSource.addCustomer(model);
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) {
    final model = CustomerModel.fromEntity(customer);
    return _dataSource.updateCustomer(model);
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) =>
      _dataSource.deleteCustomer(id);

  @override
  Future<Either<Failure, void>> updateCustomerStats(String id, double addedAmount) =>
      _dataSource.updateCustomerStats(id, addedAmount);
}
