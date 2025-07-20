import 'package:donatify_updated/admin_dashboard.dart';
import 'package:donatify_updated/donation_details.dart';
import 'package:donatify_updated/donor_dashboard.dart';
import 'package:donatify_updated/login_screen.dart';
import 'package:donatify_updated/payment_screen.dart';
import 'package:donatify_updated/receiver_dashboard.dart';
import 'package:donatify_updated/receiver_donation_form.dart';
import 'package:donatify_updated/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:donatify_updated/app_auth_provider.dart';
import 'user_selection.dart';
import 'supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SupabaseService.initialize();
  
   // Initialize Supabase
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
      ],
      child: const FundraiserApp(),
    ),
  );
}

class FundraiserApp extends StatelessWidget {
  const FundraiserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donatify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          secondary: Colors.amber,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/user-selection': (context) => const UserSelectionScreen(),
        '/login': (context) => LoginScreen(
              role: ModalRoute.of(context)!.settings.arguments as String,
            ),
        '/signup': (context) => SignupScreen(
              role: ModalRoute.of(context)!.settings.arguments as String,
            ),
        '/donor-dashboard': (context) => const DonorDashboard(),
        '/receiver-dashboard': (context) => const ReceiverDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/payment': (context) => PaymentScreen(
              requestId: ModalRoute.of(context)!.settings.arguments as String,
            ),
        '/receiver-form': (context) => const ReceiverDonationForm(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/donation-details':
            return MaterialPageRoute(
              builder: (context) => DonationDetailsPage(
                category: settings.arguments as String,
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const UserSelectionScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.volunteer_activism,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                'Donatify',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}