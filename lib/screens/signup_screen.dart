import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import 'auth_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({
    super.key,
    this.initialEmail,
  });

  final String? initialEmail;

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      initialMode: AuthMode.register,
      initialEmail: initialEmail,
    );
  }
}
