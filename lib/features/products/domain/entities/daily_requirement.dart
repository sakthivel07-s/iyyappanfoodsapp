import 'package:equatable/equatable.dart';

class DailyRequirement extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final DateTime date;
  final List<RequirementItem> items;
  final DateTime updatedAt;

  const DailyRequirement({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.items,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, customerId, customerName, date, items, updatedAt];
}

class RequirementItem extends Equatable {
  final String productId;
  final String productName;
  final String unit;
  final int quantity;

  const RequirementItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, productName, unit, quantity];
}
