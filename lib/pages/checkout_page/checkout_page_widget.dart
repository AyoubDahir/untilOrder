import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'checkout_page_model.dart';

class CheckoutPageWidget extends StatelessWidget {
  const CheckoutPageWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartItems = ModalRoute.of(context)!.settings.arguments as List<Map<String, dynamic>>;
    
    return Consumer<CheckoutPageModel>(
      builder: (context, model, child) {
        // Initialize cart items if not already done
        if (model.cartItems.isEmpty) {
          model.setCartItems(cartItems);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Checkout'),
          ),
          body: model.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: model.formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (model.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            model.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                        onSaved: (value) => model.name = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                        onSaved: (value) => model.phone = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                        onSaved: (value) => model.address = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        onSaved: (value) => model.email = value ?? '',
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...model.cartItems.map((item) => ListTile(
                            title: Text(item['name'] as String),
                            subtitle: Text('Quantity: ${item['quantity']}'),
                            trailing: Text(
                              '\$${((item['price'] as double) * (item['quantity'] as int)).toStringAsFixed(2)}',
                            ),
                          )),
                      const Divider(),
                      ListTile(
                        title: const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Text(
                          '\$${model.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (await model.placeOrder()) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Order placed successfully!'),
                                  ),
                                );
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/dashboard',
                                  (route) => false,
                                );
                              }
                            }
                          },
                          child: const Text('Place Order'),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}