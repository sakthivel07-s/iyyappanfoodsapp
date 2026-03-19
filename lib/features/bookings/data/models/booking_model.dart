import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking.dart';

class BookingItemModel extends BookingItem {
  const BookingItemModel({
    required super.productId,
    required super.productName,
    required super.unit,
    required super.quantity,
    required super.unitPrice,
    required super.totalPrice,
  });

  factory BookingItemModel.fromJson(Map<String, dynamic> json) {
    return BookingItemModel(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'unit': unit,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
      };
}

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.customerPhone,
    required super.items,
    required super.subtotal,
    required super.discount,
    required super.grandTotal,
    required super.status,
    required super.notes,
    required super.bookingDate,
    required super.createdAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((i) => BookingItemModel.fromJson(i as Map<String, dynamic>))
        .toList();

    return BookingModel(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      items: itemsList,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (data['grandTotal'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'confirmed',
      notes: data['notes'] as String? ?? '',
      bookingDate: (data['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'items': items
            .map((i) => BookingItemModel(
                  productId: i.productId,
                  productName: i.productName,
                  unit: i.unit,
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                  totalPrice: i.totalPrice,
                ).toJson())
            .toList(),
        'subtotal': subtotal,
        'discount': discount,
        'grandTotal': grandTotal,
        'status': status,
        'notes': notes,
        'bookingDate': Timestamp.fromDate(bookingDate),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory BookingModel.fromEntity(Booking b) => BookingModel(
        id: b.id,
        customerId: b.customerId,
        customerName: b.customerName,
        customerPhone: b.customerPhone,
        items: b.items,
        subtotal: b.subtotal,
        discount: b.discount,
        grandTotal: b.grandTotal,
        status: b.status,
        notes: b.notes,
        bookingDate: b.bookingDate,
        createdAt: b.createdAt,
      );
}
