import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_profile.dart';
import '../providers/auth_provider.dart';
import 'sidebar.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    this.selectedIndex = 0,
    this.profile,
  });

  final Widget child;
  final int selectedIndex;
  final AppProfile? profile;

  void _go(BuildContext context, int index) {
    if (index == 0) context.go('/');
    if (index == 1) context.go('/new');
    if (index == 2) context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Row(
            children: [
              if (wide)
                Sidebar(
                  auth: auth,
                  profile: profile,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (i) => _go(context, i),
                ),
              Expanded(
                child: SafeArea(
                  left: false,
                  child: child,
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : AppBottomNav(
                  auth: auth,
                  selectedIndex: selectedIndex,
                  onTap: (i) => _go(context, i),
                ),
        );
      },
    );
  }
}
