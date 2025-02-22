class Product {
  final String id; // Using String ID but ensuring it's a valid integer string
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool available;
  final String type;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.type,
    this.available = true,
  }) {
    // Validate that id is a valid integer string
    assert(int.tryParse(id) != null, 'Product ID must be a valid integer string');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'list_price': price,
        'image_128': imageUrl,
        'categ_id': [0, category], // Match Odoo format
        'available_in_pos': available,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    // Ensure ID is converted to string properly
    final id = json['id'] is int ? json['id'].toString() : json['id'] as String;
    
    // Handle price field which might come as list_price from API
    final price = json.containsKey('list_price') 
        ? (json['list_price'] as num).toDouble()
        : (json['price'] as num? ?? 0.0).toDouble();

    // Handle description which might be boolean false from API
    String description = '';
    if (json['description'] != null && json['description'] != false) {
      description = json['description'] as String;
    }

    // Handle image URL
    String imageUrl = '';
    if (json['image_128'] != null && json['image_128'] != false) {
      imageUrl = json['image_128'] as String;
    } else if (json['imageUrl'] != null) {
      imageUrl = json['imageUrl'] as String;
    }

    // Handle category which might come as categ_id from API
    String category = 'Uncategorized';
    if (json['categ_id'] != null && json['categ_id'] != false) {
      final categId = json['categ_id'];
      if (categId is List && categId.length > 1) {
        category = categId[1] as String;
      }
    } else if (json['category'] != null) {
      category = json['category'] as String;
    }

    return Product(
      id: id,
      name: json['name'] as String,
      description: description,
      price: price,
      imageUrl: imageUrl,
      category: category,
      type: category, // Use category as type for consistency
      available: json['available_in_pos'] as bool? ?? true,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    bool? available,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      available: available ?? this.available,
    );
  }
}
