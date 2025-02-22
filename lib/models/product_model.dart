class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String type;
  final String imageUrl;
  final String category;
  final bool available;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.imageUrl,
    required this.category,
    this.available = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(), // Convert to String
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      type: json['type'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? 'https://somalijobs.com/assets/employer-images/a603a699b915d515491930a0c88d922a/nagaad-cafe-and-restaurant_15.jpeg',
      category: json['category'] as String? ?? 'Uncategorized',
      available: json['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'type': type,
    'imageUrl': imageUrl,
    'category': category,
    'available': available,
  };
}
