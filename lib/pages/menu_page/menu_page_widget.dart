import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'menu_page_model.dart';
import 'package:nguat/models/product_model.dart';
import '../../models/cart_item.dart';
import '../../models/order_item.dart';
import 'package:nguat/widgets/receipt_widget.dart';


class MenuPageWidget extends StatelessWidget {
  const MenuPageWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuPageModel>(
      builder: (context, model, child) {
        // Initialize the model when the widget is first built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          model.initState(context);
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Menu'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => model.fetchProducts(forceRefresh: true),
              ),
              DropdownButton<String>(
                value: model.selectedCategory,
                hint: const Text('Select Category'),
                onChanged: (value) => model.selectCategory(value),
                items: model.getCategories().map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => _showCartDialog(context, model),
                  ),
                  if (model.cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${model.cartItemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) => model.filterProducts(value),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: model.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : model.filteredProducts.isEmpty
                        ? const Center(
                            child: Text(
                              'No products available',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(8.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: model.filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = model.filteredProducts[index];
                              return _buildProductCard(context, product, model);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(
      BuildContext context, Product product, MenuPageModel model) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                image: DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) => const Icon(Icons.error),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => model.addToCart(product),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCartDialog(BuildContext context, MenuPageModel model) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Shopping Cart',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Consumer<MenuPageModel>(
              builder: (context, model, child) => SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (model.isCartEmpty)
                      const Text('Your cart is empty')
                    else
                      Column(
                        children: model.cartItems.map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '\$${item.product.price.toStringAsFixed(2)} x ${item.quantity}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: Colors.red),
                                onPressed: () => model.decrementQuantity(item.product),
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.green),
                                onPressed: () => model.incrementQuantity(item.product),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    if (!model.isCartEmpty) ...[
                      const Divider(),
                      Text(
                        'Subtotal: \$${model.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Tax: \$${model.tax.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Total: \$${model.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                if (!model.isCartEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: model.isSubmitting
                        ? null
                        : () async {
                            try {
                              await model.submitOrder(context);
                              await ReceiptWidget.showReceiptDialog(
                                context: context,
                                orderReference: model.lastOrderId ?? 'N/A',
                                orderItems: model.cartItems.map((item) => {
                                  'name': item.product.name,
                                  'quantity': item.quantity,
                                  'price': item.product.price,
                                }).toList(),
                                cashierName: model.employeeName ?? 'Unknown',
                                subtotal: model.subtotal,
                                tax: model.tax,
                                total: model.total,
                              );
                              model.clearCart();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(model.error ?? 'Failed to submit order'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: model.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Checkout'),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}}