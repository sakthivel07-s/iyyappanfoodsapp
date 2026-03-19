import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iyyappan_foods/features/customers/domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.customerId,
    required super.amount,
    required super.date,
    required super.paymentMethod,
    super.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json, String id) {
    return PaymentModel(
      id: id,
      customerId: json['customerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: (json['date'] as Timestamp).toDate(),
      paymentMethod: json['paymentMethod'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }
}
