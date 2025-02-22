import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../menu_page/menu_page_model.dart';
import 'checkout_page_model.dart';

class CheckoutPageWidget extends StatelessWidget {
  const CheckoutPageWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutPageModel(),
      child: const CheckoutPageContent(),
    );
  }
}

class CheckoutPageContent extends StatelessWidget {
  const CheckoutPageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final menuModel = Provider.of<MenuPageModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Consumer<CheckoutPageModel>(
        builder: (context, model, child) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: menuModel.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = menuModel.cartItems[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('${item.quantity}x \$${item.product.price}'),
                      trailing: Text(
                        '\$${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: \$${menuModel.cartTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Customer Information Form
              const Text(
                'Delivery Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: model.nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: model.phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: model.addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Error Message
              if (model.error != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[100],
                  child: Text(
                    model.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: model.isLoading
                      ? null
                      : () async {
                          // Validate inputs
                          if (model.nameController.text.isEmpty ||
                              model.phoneController.text.isEmpty ||
                              model.addressController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all fields'),
                              ),
                            );
                            return;
                          }

                          // Prepare order items
                          final items = menuModel.cartItems
                              .map((item) => {
                                    'product_id': item.product.id,
                                    'quantity': item.quantity,
                                    'price': item.product.price,
                                  })
                              .toList();

                          // Place order
                          if (await model.placeOrder(
                            items,
                            menuModel.cartTotal,
                          )) {
                            // Clear cart and navigate back to dashboard
                            menuModel.clearCart();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/dashboard',
                                (route) => false,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Order placed successfully!'),
                                ),
                              );
                            }
                          }
                        },
                  child: model.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
