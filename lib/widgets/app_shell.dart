import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'sidebar.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.child,
    this.selectedIndex = 0,
    this.profile,
  });

  final Widget child;
  final int selectedIndex;
  final AppProfile? profile;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String? _loadedUserId;

  void _go(BuildContext context, int index) {
    if (index == 0) context.go('/');
    if (index == 1) context.go('/new');
    if (index == 2) context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final userId = auth.user?.id;

    if (userId != null && _loadedUserId != userId) {
      _loadedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ProfileProvider>().load();
      });
    }
    if (userId == null && _loadedUserId != null) {
      _loadedUserId = null;
    }

    // The sidebar is the signed-in user's persistent account area. It must
    // never use the profile currently being viewed in the page content.
    final shellProfile = profileProvider.profile;

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
                  profile: shellProfile,
                  selectedIndex: widget.selectedIndex,
                  onDestinationSelected: (i) => _go(context, i),
                ),
              Expanded(
                child: SafeArea(
                  left: false,
                  child: widget.child,
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : AppBottomNav(
                  auth: auth,
                  selectedIndex: widget.selectedIndex,
                  onTap: (i) => _go(context, i),
                ),
        );
      },
    );
  }
}
