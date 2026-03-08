import 'package:flutter/material.dart';
import 'package:TBox/storage_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool) onLoginResult;

  const LoginScreen({super.key, required this.onLoginResult});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiKeyController = TextEditingController();
  final _storageService = StorageService();
  bool _obscureText = true;

  Future<void> _login() async {
    final apiKey = _apiKeyController.text;
    if (apiKey.isNotEmpty) {
      await _storageService.saveApiKey(apiKey);
      widget.onLoginResult(true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an API key')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          width: size.width,
          child: Stack(
            children: [
              // Blue background for the top half
              Container(
                height: size.height * 0.5,
                width: size.width,
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter API key to continue',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // White card in the center
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: size.height * 0.6,
                  width: size.width,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        TextField(
                          controller: _apiKeyController,
                          obscureText: _obscureText,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'API Key',
                            prefixIcon: const Icon(Icons.vpn_key_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
