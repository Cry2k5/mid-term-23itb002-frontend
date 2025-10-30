import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/user_service.dart';
import 'user_management_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final UserService _service = UserService();

  Future<void> login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Dio().post(
        'http://192.168.2.42:5001/api/auth/signin',
        data: {
          'username': _usernameController.text,
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        // token backend gửi trong response.data
        final token = response.data['token'] as String?;
        if (token == null) throw Exception('Token is null');

        _service.setToken(token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserManagementScreen(service: _service),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Login failed: ${response.data}';
        });
      }
    } on DioException catch (e) {
      setState(() {
        if (e.response != null) {
          _errorMessage = 'Login failed: ${e.response?.data}';
        } else {
          _errorMessage = 'Cannot connect to server: ${e.message}';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Admin Login', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 24),
                if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
                const SizedBox(height: 16),
                TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : login,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
