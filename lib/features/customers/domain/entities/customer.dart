import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final double totalSpent;
  final int orderCount;
  final DateTime createdAt;
  final DateTime? lastOrderDate;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.notes,
    required this.totalSpent,
    required this.orderCount,
    required this.createdAt,
    this.lastOrderDate,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    double? totalSpent,
    int? orderCount,
    DateTime? createdAt,
    DateTime? lastOrderDate,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      totalSpent: totalSpent ?? this.totalSpent,
      orderCount: orderCount ?? this.orderCount,
      createdAt: createdAt ?? this.createdAt,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, address, notes, totalSpent, orderCount];
}
