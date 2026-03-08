import 'package:flutter/material.dart';
import 'package:TBox/screens/login_screen.dart';
import 'package:TBox/screens/main_screen.dart';
import 'package:TBox/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:TBox/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
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
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final apiKey = await _storageService.getApiKey();
    if (mounted) {
      setState(() {
        _isLoggedIn = apiKey != null;
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
          darkTheme: themeProvider.theme == AppTheme.black
              ? blackTheme
              : darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: _isLoggedIn
              ? MainScreen(onLogout: _handleLogout)
              : LoginScreen(onLoginResult: _handleLogin),
        );
      },
    );
  }
}
