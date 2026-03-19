import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  final String unit;
  final double price;
  final int stock;

  const ProductVariant({
    required this.unit,
    required this.price,
    required this.stock,
  });

  ProductVariant copyWith({String? unit, double? price, int? stock}) {
    return ProductVariant(
      unit: unit ?? this.unit,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }

  @override
  List<Object?> get props => [unit, price, stock];
}

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<ProductVariant> variants;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.variants,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    List<ProductVariant>? variants,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      variants: variants ?? this.variants,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, description, variants, isActive];
}
