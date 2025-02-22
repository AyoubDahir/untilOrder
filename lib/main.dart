import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/login_page/login_page_widget.dart';
import 'pages/menu_page/menu_page_widget.dart';
import 'pages/menu_page/menu_page_model.dart';
import 'pages/onboarding/onboarding_widget.dart';
import 'pages/login_page/login_page_model.dart';
import 'dashboard/dashboard_model.dart';
import 'services/navigation_service.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'package:printing/printing.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MenuPageModel(),
        ),
        ChangeNotifierProxyProvider<MenuPageModel, LoginPageModel>(
          create: (context) => LoginPageModel(menuPageModel: context.read<MenuPageModel>()),
          update: (context, menuPageModel, previous) => 
            previous ?? LoginPageModel(menuPageModel: menuPageModel),
        ),
        ChangeNotifierProvider(create: (_) => DashboardModel()),
      ],
      child: MaterialApp(
        title: 'Nagaad',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // Add light theme to ensure visibility
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const InitialLoadingScreen(),
        onGenerateRoute: (settings) {
          debugPrint('Navigating to: ${settings.name}');

          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => const InitialLoadingScreen(),
              );

            case '/login':
              return MaterialPageRoute(
                builder: (_) => const LoginPageWidget(),
                settings: settings,
              );

            case '/menu':
              return MaterialPageRoute(
                builder: (_) => const MenuPageWidget(),
                settings: settings,
              );

            case '/dashboard':
              return MaterialPageRoute(
                builder: (_) => const DashboardPage(),
                settings: settings,
              );

            default:
              return MaterialPageRoute(
                builder: (_) => const OnboardingWidget(),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}

class InitialLoadingScreen extends StatelessWidget {
  const InitialLoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: NavigationService.getInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              color: Colors.white, // Ensure white background
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return snapshot.data ?? const OnboardingWidget();
      },
    );
  }
}
