import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/daily_requirement.dart';

class RequirementItemModel extends RequirementItem {
  const RequirementItemModel({
    required super.productId,
    required super.productName,
    required super.unit,
    required super.quantity,
  });

  factory RequirementItemModel.fromJson(Map<String, dynamic> json) => RequirementItemModel(
        productId: json['productId'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'unit': unit,
        'quantity': quantity,
      };
}

class DailyRequirementModel extends DailyRequirement {
  const DailyRequirementModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.date,
    required super.items,
    required super.updatedAt,
  });

  factory DailyRequirementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyRequirementModel(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => RequirementItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'customerId': customerId,
        'customerName': customerName,
        'date': Timestamp.fromDate(date),
        'items': items.map((i) => RequirementItemModel(
              productId: i.productId,
              productName: i.productName,
              unit: i.unit,
              quantity: i.quantity,
            ).toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
