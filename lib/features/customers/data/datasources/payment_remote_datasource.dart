import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iyyappan_foods/features/customers/data/models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<void> addPayment(PaymentModel payment);
  Stream<List<PaymentModel>> getCustomerPayments(String customerId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore _firestore;

  PaymentRemoteDataSourceImpl(this._firestore);

  @override
  Future<void> addPayment(PaymentModel payment) async {
    await _firestore.collection('payments').add(payment.toJson());
  }

  @override
  Stream<List<PaymentModel>> getCustomerPayments(String customerId) {
    return _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
            .toList());
  }
}
