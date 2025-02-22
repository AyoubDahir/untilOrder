import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/dashboard_widget.dart';
import '../../dashboard/dashboard_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardModel(),
      child: const DashboardWidget(),
    );
  }
}
