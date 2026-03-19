import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String customerId;
  final double amount;
  final DateTime date;
  final String paymentMethod; // e.g., 'Cash', 'Online', 'UPI'
  final String? notes;

  const Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.notes,
  });

  @override
  List<Object?> get props => [id, customerId, amount, date, paymentMethod, notes];
}
