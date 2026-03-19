import 'package:equatable/equatable.dart';

enum LedgerEntryType { booking, payment }

class LedgerEntry extends Equatable {
  final String id;
  final String customerId;
  final double amount; // Positive for Debit (Booking), Negative for Credit (Payment)? 
  // Actually, let's keep it simple: type determines the sign for calculation
  final DateTime date;
  final String title;
  final String subtitle;
  final LedgerEntryType type;

  const LedgerEntry({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.type,
  });

  @override
  List<Object?> get props => [id, customerId, amount, date, title, subtitle, type];
}
