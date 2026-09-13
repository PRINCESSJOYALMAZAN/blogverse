import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_logo.dart';

// Tailwind-ish palette
const _kIndigo = Color(0xFF4F46E5);
const _kSlate900 = Color(0xFF0F172A);
const _kSlate700 = Color(0xFF334155);
const _kSlate500 = Color(0xFF64748B);
const _kSlate400 = Color(0xFF94A3B8);
const _kSlate200 = Color(0xFFE2E8F0);
const _kSlate100 = Color(0xFFF1F5F9);
const _kRed = Color(0xFFDC2626);
const _kGreen = Color(0xFF16A34A);

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.initialMode = AuthMode.login,
    this.initialEmail,
    this.isRegister = false,
  });

  final AuthMode initialMode;
  final String? initialEmail;
  final bool isRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  late AuthMode _mode;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.isRegister ? AuthMode.register : widget.initialMode;
    if (widget.initialEmail?.trim().isNotEmpty == true) {
      _email.text = widget.initialEmail!.trim();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  // Handlers

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthStateProvider>().login(_email.text, _password.text);
      if (mounted) context.go('/');
    } on InvalidCredentialsException {
      _snack('Invalid email or password.', error: true);
    } catch (e) {
      _snack(_mapError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthStateProvider>().register(
            email: _email.text,
            password: _password.text,
            name: _name.text,
          );
      if (!mounted) return;
      context.go('/');
      _snack('Welcome to BlogVerse!');
    } on InvalidCredentialsException {
      _snack('Invalid email or password.', error: true);
    } catch (e) {
      _snack(_mapError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _kRed : _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String _mapError(Object e) {
    if (e is AccountAlreadyExistsException) {
      return 'An account with this email already exists.';
    }
    final s = e.toString().toLowerCase();
    if (s.contains('invalid login')) return 'Invalid email or password.';
    if (s.contains('already registered')) {
      return 'An account with this email already exists.';
    }
    return e.toString().replaceFirst('AuthException(message: ', '').replaceFirst(')', '');
  }

  // Build

  void _switchMode(AuthMode mode) {
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSlate100,
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) return _WideLayout(state: this);
        return _NarrowLayout(state: this);
      }),
    );
  }
}

// Wide layout

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.state});
  final _AuthScreenState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left brand panel
        Expanded(
          flex: 5,
          child: Container(
            color: _kSlate900,
            child: Stack(
              children: [
                // Decorative blobs
                Positioned(
                  top: -80,
                  left: -80,
                  child: _Blob(color: _kIndigo.withValues(alpha: .18), size: 400),
                ),
                Positioned(
                  bottom: -100,
                  right: -60,
                  child: _Blob(color: const Color(0xFF7C3AED).withValues(alpha: .15), size: 350),
                ),
                // Content
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 52, vertical: 52),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LogoBadge(),
                      Spacer(),
                      _BrandCopy(),
                      Spacer(),
                      _Testimonial(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right form panel
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: _AuthFormCard(state: state),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Narrow layout

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.state});
  final _AuthScreenState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Mini brand header
          Container(
            color: _kSlate900,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 40),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_LogoBadge(), SizedBox(height: 20), _BrandCopy()],
            ),
          ),
          // Form
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(28),
            child: _AuthFormCard(state: state),
          ),
        ],
      ),
    );
  }
}

// Brand components

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return const AppLogo(iconSize: 36, fontSize: 20);
  }
}

class _BrandCopy extends StatelessWidget {
  const _BrandCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your voice,\nyour community.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -.8,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Share your thoughts, ask questions, and\ninspire conversations with the community.',
          style: TextStyle(
            color: _kSlate400,
            fontSize: 15,
            height: 1.7,
          ),
        ),
        SizedBox(height: 28),
        _FeatureRow(icon: Icons.bolt_rounded, label: 'Fast & responsive'),
        SizedBox(height: 10),
        _FeatureRow(icon: Icons.lock_outline_rounded, label: 'Secure by default'),
        SizedBox(height: 10),
        _FeatureRow(icon: Icons.photo_library_outlined, label: 'Multi-image support'),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _kIndigo.withValues(alpha: .25),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: const Color(0xFFA5B4FC), size: 14),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: _kSlate400, fontSize: 13)),
      ],
    );
  }
}

class _Testimonial extends StatelessWidget {
  const _Testimonial();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"An incredible platform to share and grow with like-minded developers."',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          SizedBox(height: 10),
          Text('- BlogVerse community',
              style: TextStyle(color: _kSlate500, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// Auth form card

class _AuthFormCard extends StatefulWidget {
  const _AuthFormCard({required this.state});
  final _AuthScreenState state;

  @override
  State<_AuthFormCard> createState() => _AuthFormCardState();
}

class _AuthFormCardState extends State<_AuthFormCard> {
  bool _showPw = false;

  _AuthScreenState get s => widget.state;

  bool get _hasEightCharacters => s._password.text.length >= 8;
  bool get _hasNumber => RegExp(r'\d').hasMatch(s._password.text);
  bool get _hasSpecialCharacter =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(s._password.text);

  @override
  void initState() {
    super.initState();
    s._password.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    s._password.removeListener(_onPasswordChanged);
    super.dispose();
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please enter a password';
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must include at least 1 number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]')
        .hasMatch(password)) {
      return 'Password must include at least 1 special character';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = s._mode == AuthMode.register;

    return Form(
      key: s._formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heading
          Text(
            isRegister ? 'Create your account' : 'Welcome back',
            style: const TextStyle(
              color: _kSlate900,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isRegister
                ? 'Join the BlogVerse community today.'
                : 'Sign in to continue to BlogVerse.',
            style: const TextStyle(color: _kSlate500, fontSize: 14),
          ),
          const SizedBox(height: 28),

          // Full name (register only)
          if (isRegister) ...[
            _TwField(
              controller: s._name,
              label: 'Full name',
              hint: 'Juan Dela Cruz',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter your full name'
                  : null,
            ),
            const SizedBox(height: 14),
          ],

          // Email
          _TwField(
            controller: s._email,
            label: 'Email',
            hint: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 14),

          // Password
          _TwField(
            controller: s._password,
            label: 'Password',
            hint: 'Password',
            obscureText: !_showPw,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => setState(() => _showPw = !_showPw),
              child: Icon(
                _showPw
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: _kSlate500,
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 10),
          _PasswordChecklist(
            hasEightCharacters: _hasEightCharacters,
            hasNumber: _hasNumber,
            hasSpecialCharacter: _hasSpecialCharacter,
          ),

          const SizedBox(height: 22),

          // Submit
          SizedBox(
            height: 46,
            child: FilledButton(
              onPressed: s._busy
                  ? null
                  : (isRegister ? s._handleRegister : s._handleLogin),
              style: FilledButton.styleFrom(
                backgroundColor: _kIndigo,
                disabledBackgroundColor: _kIndigo.withValues(alpha: .6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: s._busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isRegister ? 'Create account' : 'Sign in',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          const Row(children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('or',
                  style: TextStyle(color: _kSlate400, fontSize: 13)),
            ),
            Expanded(child: Divider()),
          ]),

          const SizedBox(height: 20),

          // Toggle register / login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isRegister
                    ? 'Already have an account? '
                    : "Don't have an account? ",
                style: const TextStyle(color: _kSlate500, fontSize: 14),
              ),
              GestureDetector(
                onTap: () => s._switchMode(
                  isRegister ? AuthMode.login : AuthMode.register,
                ),
                child: Text(
                  isRegister ? 'Sign in' : 'Sign up',
                  style: const TextStyle(
                    color: _kIndigo,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: _kIndigo,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({
    required this.hasEightCharacters,
    required this.hasNumber,
    required this.hasSpecialCharacter,
  });

  final bool hasEightCharacters;
  final bool hasNumber;
  final bool hasSpecialCharacter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PasswordRule(
          checked: hasEightCharacters,
          text: 'At least 8 characters',
        ),
        const SizedBox(height: 6),
        _PasswordRule(
          checked: hasNumber,
          text: 'At least 1 number',
        ),
        const SizedBox(height: 6),
        _PasswordRule(
          checked: hasSpecialCharacter,
          text: 'At least 1 special character',
        ),
      ],
    );
  }
}

class _PasswordRule extends StatelessWidget {
  const _PasswordRule({
    required this.checked,
    required this.text,
  });

  final bool checked;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = checked ? _kGreen : _kSlate500;
    return Row(
      children: [
        Icon(
          checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}


// Tailwind-styled text field

class _TwField extends StatelessWidget {
  const _TwField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: _kSlate700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(
            color: _kSlate900,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _kSlate400),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: _kSlate400)
                : null,
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: suffixIcon,
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
            filled: true,
            fillColor: _kSlate100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kSlate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kIndigo, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kRed, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

