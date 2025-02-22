import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dashboard_model.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({Key? key}) : super(key: key);

  @override
  _DashboardWidgetState createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    debugPrint('DashboardWidget initialized');
    // Fetch recent orders when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Fetching orders after frame...');
      context.read<DashboardModel>().fetchOrders();
    });
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading dashboard...'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.blue[900],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Open menu
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              debugPrint('Manually refreshing orders...');
              context.read<DashboardModel>().refreshOrders();
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Open notifications
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              // Open profile
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final dashboardModel = Provider.of<DashboardModel>(context, listen: false);
              await dashboardModel.logout(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<DashboardModel>(
          builder: (context, model, child) {
            if (model.error != null) {
              return _buildErrorWidget(
                model.error!,
                () => model.refreshOrders(),
              );
            }

            if (model.isLoading && model.recentOrders.isEmpty) {
              return _buildLoadingWidget();
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Consumer<DashboardModel>(
                        builder: (context, model, child) {
                          return Text(
                            model.recentOrders.length.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionCard('Menu', Icons.menu_book, '/menu'),
                          _buildActionCard('Reports', Icons.bar_chart, '/reports'),
                          _buildActionCard('Recent Orders', Icons.receipt_long, '/recent-orders'),
                          _buildActionCard('Available Products', Icons.inventory, '/available-products'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Orders',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Consumer<DashboardModel>(
                                    builder: (context, model, child) {
                                      return DropdownButton<OrderStatus?>(
                                        value: model.selectedStatus,
                                        hint: Text('All Status'),
                                        items: [
                                          DropdownMenuItem<OrderStatus?>(
                                            value: null,
                                            child: Text('All Status'),
                                          ),
                                          ...OrderStatus.values.map((status) {
                                            return DropdownMenuItem<OrderStatus>(
                                              value: status,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: status.color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(status.displayName),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                        onChanged: (OrderStatus? newStatus) {
                                          context.read<DashboardModel>().setStatusFilter(newStatus);
                                        },
                                      );
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.refresh),
                                    onPressed: () {
                                      context.read<DashboardModel>().fetchOrders();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Expanded(
                            child: Consumer<DashboardModel>(
                              builder: (context, model, child) {
                                if (model.recentOrders.isEmpty) {
                                  return Center(
                                    child: Text('No recent orders found'),
                                  );
                                }

                                return RefreshIndicator(
                                  onRefresh: () => model.fetchOrders(),
                                  child: ListView.builder(
                                    itemCount: model.recentOrders.length,
                                    itemBuilder: (context, index) {
                                      final order = model.recentOrders[index];
                                      return Card(
                                        elevation: 2,
                                        margin: EdgeInsets.symmetric(vertical: 4),
                                        child: ListTile(
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  order.customerName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: order.status.color.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  order.status.displayName,
                                                  style: TextStyle(
                                                    color: order.status.color,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Ref: ${order.reference}'),
                                              Text(
                                                DateFormat('MMM dd, yyyy HH:mm')
                                                    .format(DateTime.parse(order.date)),
                                              ),
                                            ],
                                          ),
                                          trailing: Text(
                                            '\$${order.total.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, String route) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}