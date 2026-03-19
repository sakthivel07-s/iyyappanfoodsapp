import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Stream<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, void>> addProduct(ProductModel product);
  Future<Either<Failure, void>> updateProduct(ProductModel product);
  Future<Either<Failure, void>> updateStock(String productId, String variantUnit, int newStock);
  Future<Either<Failure, void>> addStock(String productId, String variantUnit, int increment);
  Future<Either<Failure, void>> deductStock(List<StockDeduction> items);
  Future<Either<Failure, void>> deleteProduct(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const String _collection = 'products';

  ProductRemoteDataSourceImpl(this._firestore);

  @override
  Stream<Either<Failure, List<Product>>> getProducts() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map<Either<Failure, List<Product>>>((snapshot) {
      final products = snapshot.docs
          .map<Product>((doc) => ProductModel.fromFirestore(doc))
          .toList();
      return Right(products);
    }).handleError((e) => Left(ServerFailure(e.toString())));
  }

  @override
  Future<Either<Failure, void>> addProduct(ProductModel product) async {
    try {
      await _firestore.collection(_collection).doc(product.id).set(product.toFirestore());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(ProductModel product) async {
    try {
      await _firestore.collection(_collection).doc(product.id).update({
        ...product.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStock(String productId, String variantUnit, int newStock) async {
    try {
      final docRef = _firestore.collection(_collection).doc(productId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('Product not found');
        
        final data = snapshot.data()!;
        final variants = List<Map<String, dynamic>>.from(data['variants'] ?? []);
        
        final index = variants.indexWhere((v) => v['unit'] == variantUnit);
        if (index != -1) {
          variants[index]['stock'] = newStock;
        }
        
        transaction.update(docRef, {'variants': variants, 'updatedAt': FieldValue.serverTimestamp()});
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deductStock(List<StockDeduction> items) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final productIds = items.map((i) => i.productId).toSet();
        final snapshots = <String, DocumentSnapshot>{};
        
        for (final id in productIds) {
          snapshots[id] = await transaction.get(_firestore.collection(_collection).doc(id));
        }

        for (final item in items) {
          final snapshot = snapshots[item.productId];
          if (snapshot == null || !snapshot.exists) continue;
          
          final data = snapshot.data() as Map<String, dynamic>;
          final variants = List<Map<String, dynamic>>.from(data['variants'] ?? []);
          
          final index = variants.indexWhere((v) => v['unit'] == item.variantUnit);
          if (index != -1) {
            final currentStock = (variants[index]['stock'] as num).toInt();
            variants[index]['stock'] = currentStock - item.quantity;
          }
          
          transaction.update(_firestore.collection(_collection).doc(item.productId), {
            'variants': variants,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addStock(String productId, String variantUnit, int increment) async {
    try {
      final docRef = _firestore.collection(_collection).doc(productId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('Product not found');
        
        final data = snapshot.data()!;
        final variants = List<Map<String, dynamic>>.from(data['variants'] ?? []);
        
        final index = variants.indexWhere((v) => v['unit'] == variantUnit);
        if (index != -1) {
          final currentStock = (variants[index]['stock'] as num).toInt();
          variants[index]['stock'] = currentStock + increment;
        }
        
        transaction.update(docRef, {'variants': variants, 'updatedAt': FieldValue.serverTimestamp()});
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
