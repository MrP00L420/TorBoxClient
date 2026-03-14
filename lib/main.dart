import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:TBox/screens/login_screen.dart';
import 'package:TBox/screens/main_screen.dart';
import 'package:TBox/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:TBox/theme_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:developer' as developer;

void main() async {
  // Ensure that plugin services are initialized before calling `runApp`
  WidgetsFlutterBinding.ensureInitialized();

  // Create and load the theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const TBox(),
    ),
  );
}

class TBox extends StatefulWidget {
  const TBox({super.key});

  @override
  State<TBox> createState() => _TBoxState();
}

class _TBoxState extends State<TBox> {
  bool _isLoggedIn = false;
  bool _isAuthenticating = true;
  final _storageService = StorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final apiKey = await _storageService.getApiKey();
    final isAppLockEnabled = await _storageService.isAppLockEnabled();
    bool authenticated = false;

    if (apiKey != null && isAppLockEnabled) {
      try {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to open TBox',
        );
      } on PlatformException catch (e) {
        developer.log('Error during authentication', name: 'dev.TBox.auth', error: e);
        // Keep authenticated as false in case of error
        authenticated = false;
      }

      // If authentication fails or is cancelled, exit the app.
      if (!authenticated) {
        SystemNavigator.pop();
        return;
      }
    } else if (apiKey != null) {
      // If app lock is not enabled but an API key exists, treat as logged in.
      authenticated = true;
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = authenticated;
        _isAuthenticating = false;
      });
    }
  }

  void _handleLogin(bool success) {
    if (success) {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  void _handleLogout(bool success) {
    if (success) {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.deepPurple;

    // Using const for themes improves performance as they don't need to be rebuilt.
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    final blackTheme = darkTheme.copyWith(
      scaffoldBackgroundColor: Colors.black,
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'TBox',
          theme: lightTheme,
          darkTheme: themeProvider.theme == AppTheme.black ? blackTheme : darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: _isAuthenticating
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _isLoggedIn
                  ? MainScreen(onLogout: _handleLogout)
                  : LoginScreen(onLoginResult: _handleLogin),
        );
      },
    );
  }
}
