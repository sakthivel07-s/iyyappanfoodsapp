import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/customer.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Stream<Either<Failure, List<Customer>>> getCustomers();
  Future<Either<Failure, Customer>> getCustomerById(String id);
  Future<Either<Failure, void>> addCustomer(CustomerModel customer);
  Future<Either<Failure, void>> updateCustomer(CustomerModel customer);
  Future<Either<Failure, void>> deleteCustomer(String id);
  Future<Either<Failure, void>> updateCustomerStats(String id, double addedAmount);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const String _collection = 'customers';

  CustomerRemoteDataSourceImpl(this._firestore);

  @override
  Stream<Either<Failure, List<Customer>>> getCustomers() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map<Either<Failure, List<Customer>>>((snap) {
      final list = snap.docs.map((d) => CustomerModel.fromFirestore(d)).toList();
      return Right(list);
    }).handleError((e) => Left(ServerFailure(e.toString())));
  }

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return const Left(NotFoundFailure());
      return Right(CustomerModel.fromFirestore(doc));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCustomer(CustomerModel customer) async {
    try {
      await _firestore.collection(_collection).doc(customer.id).set(customer.toFirestore());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(CustomerModel customer) async {
    try {
      await _firestore.collection(_collection).doc(customer.id).update(customer.toFirestore());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomerStats(String id, double addedAmount) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'totalSpent': FieldValue.increment(addedAmount),
        'orderCount': FieldValue.increment(1),
        'lastOrderDate': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
