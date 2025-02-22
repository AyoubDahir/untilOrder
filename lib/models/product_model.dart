class Product {
  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final String category;
  final String description;
  final bool available;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.description = '',
    this.available = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? 'https://somalijobs.com/assets/employer-images/a603a699b915d515491930a0c88d922a/nagaad-cafe-and-restaurant_15.jpeg',
      category: json['category'] as String? ?? 'Uncategorized',
      description: json['description'] as String? ?? '',
      available: json['available'] as bool? ?? true,
    );
  }
}
