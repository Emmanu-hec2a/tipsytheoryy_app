import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/customer/cart_screen.dart';
import 'screens/customer/checkout_screen.dart';
import 'screens/customer/orders_screen.dart';
import 'screens/customer/order_tracking_screen.dart';
import 'screens/customer/rating_screen.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/rider/rider_shell.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/user_provider.dart';
import 'providers/location_provider.dart';
import 'providers/rider_provider.dart';
import 'providers/favourite_provider.dart';
import 'providers/ai_assistant_provider.dart';
import 'providers/promotion_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/shiriki_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => RiderProvider()),
        ChangeNotifierProvider(create: (_) => FavouriteProvider()),
        ChangeNotifierProvider(create: (_) => AIAssistantProvider()),
        ChangeNotifierProvider(create: (_) => PromotionProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ShirikiProvider()),
      ],
      child: const TipsyTheoryyApp(),
    ),
  );
}

class TipsyTheoryyApp extends StatelessWidget {
  const TipsyTheoryyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return MaterialApp(
      title: 'TipsyTheoryy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: authProvider.themeMode,
      home: const AuthWrapper(),
      routes: {
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/orders': (context) => const OrdersScreen(isStandalone: true),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/order-tracking') {
          final orderId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => OrderTrackingScreen(orderId: orderId),
          );
        }
        if (settings.name == '/rate-order') {
          final orderId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => RatingScreen(orderId: orderId),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    await authProvider.checkAuth();
    if (authProvider.status == AuthStatus.authenticated) {
      await userProvider.fetchProfile();
    }
    
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.status == AuthStatus.authenticated) {
      if (authProvider.role == 'rider') {
        return const RiderShell();
      } else if (authProvider.role == 'customer') {
        return const CustomerShell();
      } else {
        // Role is loading or missing - show loading
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        );
      }
    }

    return const LandingScreen();
  }
}
