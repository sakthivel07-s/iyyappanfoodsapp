import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.address,
    required super.notes,
    required super.totalSpent,
    required super.orderCount,
    required super.createdAt,
    super.lastOrderDate,
  });

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      orderCount: (data['orderCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastOrderDate: (data['lastOrderDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
        'totalSpent': totalSpent,
        'orderCount': orderCount,
        'createdAt': Timestamp.fromDate(createdAt),
        if (lastOrderDate != null)
          'lastOrderDate': Timestamp.fromDate(lastOrderDate!),
      };

  factory CustomerModel.fromEntity(Customer c) => CustomerModel(
        id: c.id,
        name: c.name,
        phone: c.phone,
        address: c.address,
        notes: c.notes,
        totalSpent: c.totalSpent,
        orderCount: c.orderCount,
        createdAt: c.createdAt,
        lastOrderDate: c.lastOrderDate,
      );
}
