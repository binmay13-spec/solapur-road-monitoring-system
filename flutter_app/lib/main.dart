// NEW FILE — Main Entry Point
// Firebase initialization, routing, and app shell

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/citizen/citizen_home_screen.dart';
import 'screens/worker/worker_home_screen.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartRoadMonitorApp());
}

class SmartRoadMonitorApp extends StatelessWidget {
  const SmartRoadMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ProxyProvider<AuthService, ApiService>(
          update: (_, auth, __) => ApiService(auth),
        ),
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'Smart Road Monitor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Listens to auth state and routes to correct screen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          // User is logged in — determine role and navigate
          return const RoleBasedRouter();
        }

        return const RoleSelectionScreen();
      },
    );
  }
}

/// Routes user based on their stored role
class RoleBasedRouter extends StatefulWidget {
  const RoleBasedRouter({super.key});

  @override
  State<RoleBasedRouter> createState() => _RoleBasedRouterState();
}

class _RoleBasedRouterState extends State<RoleBasedRouter> {
  bool _loading = true;
  String _role = 'citizen';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    // Cache context-dependent objects before any async gaps
    final apiService = Provider.of<ApiService>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      final response = await apiService.getProfile();
      if (response['success'] == true && response['user'] != null) {
        final user = UserModel.fromJson(response['user']);
        appState.setUser(user);
        if (mounted) {
          setState(() {
            _role = user.role;
            _loading = false;
          });
        }
        return;
      }
    } catch (e) {
      // If profile fetch fails, check stored role
      debugPrint('Profile fetch failed: $e');
    }

    if (mounted) {
      setState(() {
        _role = appState.selectedRole ?? 'citizen';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SplashScreen();

    switch (_role) {
      case 'worker':
        return const WorkerHomeScreen();
      case 'admin':
        // Admin uses web dashboard
        return const CitizenHomeScreen();
      default:
        return const CitizenHomeScreen();
    }
  }
}

/// Beautiful splash screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.traffic, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Smart Road Monitor',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Making roads safer together',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Global app state
class AppState extends ChangeNotifier {
  UserModel? _user;
  String? _selectedRole;

  UserModel? get user => _user;
  String? get selectedRole => _selectedRole;

  void setUser(UserModel user) {
    _user = user;
    _selectedRole = user.role;
    notifyListeners();
  }

  void setSelectedRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _selectedRole = null;
    notifyListeners();
  }
}
