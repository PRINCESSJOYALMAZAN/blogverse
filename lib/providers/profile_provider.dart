import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_profile.dart';
import '../services/supabase_service.dart';

class ProfileProvider extends ChangeNotifier {
  AppProfile? profile;
  bool loading = false;
  String? error;

  Future<void> load() async {
    if (SupabaseService.client.auth.currentUser == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;
      final row = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) {
        await SupabaseService.ensureCurrentProfile();
        profile = AppProfile(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['name']?.toString() ?? 'Member',
        );
      } else {
        profile = AppProfile.fromMap(row);
      }
    } catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<AppProfile?> getProfileById(String userId) async {
    final row = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : AppProfile.fromMap(row);
  }

  Future<void> updateName(String name) async {
    await SupabaseService.ensureCurrentProfile(name: name);
    await load();
  }

  Future<void> updateAvatar(XFile image) async {
    await SupabaseService.ensureCurrentProfile();
    final old = profile?.avatarUrl;
    final uploaded = await SupabaseService.uploadImages(
      [image],
      folder: 'avatars',
    );
    try {
      await SupabaseService.client.from('profiles').upsert({
        'id': SupabaseService.userId,
        'email': SupabaseService.userEmail,
        'name': profile?.name ?? SupabaseService.userName,
        'avatar_url': uploaded.first,
      });
    } catch (_) {
      await SupabaseService.deleteByPublicUrls(uploaded);
      rethrow;
    }
    if (old != null && old.isNotEmpty) {
      await SupabaseService.deleteByPublicUrls([old]);
    }
    await load();
  }

  Future<void> deleteAvatar() async {
    final old = profile?.avatarUrl;
    await SupabaseService.client
        .from('profiles')
        .update({'avatar_url': null}).eq('id', SupabaseService.userId);
    if (old != null && old.isNotEmpty) {
      await SupabaseService.deleteByPublicUrls([old]);
    }
    await load();
  }

}
