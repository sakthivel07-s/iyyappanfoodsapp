import 'package:equatable/equatable.dart';

class BookingItem extends Equatable {
  final String productId;
  final String productName;
  final String unit;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const BookingItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [productId, unit, quantity, unitPrice];
}

class Booking extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<BookingItem> items;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final String status; // confirmed | delivered | cancelled
  final String notes;
  final DateTime bookingDate;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.status,
    required this.notes,
    required this.bookingDate,
    required this.createdAt,
  });

  Booking copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<BookingItem>? items,
    double? subtotal,
    double? discount,
    double? grandTotal,
    String? status,
    String? notes,
    DateTime? bookingDate,
    DateTime? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      grandTotal: grandTotal ?? this.grandTotal,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      bookingDate: bookingDate ?? this.bookingDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, customerId, status, bookingDate];
}
