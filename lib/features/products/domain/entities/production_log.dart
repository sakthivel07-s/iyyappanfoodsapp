import 'package:equatable/equatable.dart';

class ProductionLog extends Equatable {
  final String id;
  final DateTime date;
  final List<ProductionItem> items;
  final String? notes;

  const ProductionLog({
    required this.id,
    required this.date,
    required this.items,
    this.notes,
  });

  @override
  List<Object?> get props => [id, date, items, notes];
}

class ProductionItem extends Equatable {
  final String productId;
  final String productName;
  final String unit;
  final int quantity;

  const ProductionItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, productName, unit, quantity];
}
