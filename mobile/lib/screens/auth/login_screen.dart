import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../theme/app_spacing.dart';
import '../tasks/task_list_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TaskListScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Erreur inconnue')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                        Icons.task_alt_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      )
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1, 1),
                      ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                        'Content de vous revoir',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 350.ms)
                      .slideY(begin: 0.15, end: 0),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Connectez-vous pour retrouver vos tâches.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 120.ms, duration: 350.ms),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                        key: const Key('login_email_field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!regex.hasMatch(v)) return 'Email invalide';
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(delay: 160.ms, duration: 300.ms)
                      .slideX(begin: 0.05, end: 0),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                        key: const Key('login_password_field'),
                        controller: _passwordController,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 8) {
                            return 'Minimum 8 caractères';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 300.ms)
                      .slideX(begin: 0.05, end: 0),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    key: const Key('login_submit_button'),
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Se connecter'),
                  ).animate().fadeIn(delay: 240.ms, duration: 300.ms),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text("Pas encore de compte ? S'inscrire"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
