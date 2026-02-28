import 'package:flutter/material.dart';
import 'package:myapp/storage_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool) onLoginResult;

  const LoginScreen({super.key, required this.onLoginResult});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiKeyController = TextEditingController();
  final _storageService = StorageService();

  Future<void> _login() async {
    final apiKey = _apiKeyController.text;
    if (apiKey.isNotEmpty) {
      await _storageService.saveApiKey(apiKey);
      widget.onLoginResult(true);
    } else {
      // Show an error message if the API key is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API key')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
