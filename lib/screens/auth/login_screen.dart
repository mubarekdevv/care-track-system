import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Password", border: OutlineInputBorder())),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Login"),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text("Don't have an account? Register"),
            )
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    final user = await AuthService()
        .signIn(_emailController.text, _passwordController.text);

    if (user != null) {
      // 🚀 Here is where Phase 4 magic happens: Role-based navigation
      final userData = await AuthService().getUserData(user.uid);
      if (userData != null) {
        _navigateBasedOnRole(userData.role);
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Login Failed")));
    }
  }

  void _navigateBasedOnRole(String role) {
    if (role == 'Parent') {
      Navigator.pushReplacementNamed(context, '/parent_home');
    } else if (role == 'Teacher')
      Navigator.pushReplacementNamed(context, '/teacher_home');
    // Add others as you build dashboards
  }
}
