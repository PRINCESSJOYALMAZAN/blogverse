import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_profile.dart';
import '../services/supabase_service.dart';

class ProfileProvider extends ChangeNotifier {
  AppProfile? profile;
  bool loading = false;

  Future<void> load() async {
    if (SupabaseService.client.auth.currentUser == null) return;
    loading = true;
    notifyListeners();
    final user = SupabaseService.client.auth.currentUser!;
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
        name: user.userMetadata?['name'] ?? 'Member',
      );
    } else {
      profile = AppProfile.fromMap(row);
    }
    loading = false;
    notifyListeners();
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

  Future<void> updateCover(XFile image) async {
    await SupabaseService.ensureCurrentProfile();
    final old = profile?.coverUrl;
    final uploaded = await SupabaseService.uploadImages(
      [image],
      folder: 'covers',
    );
    try {
      await SupabaseService.client.from('profiles').upsert({
        'id': SupabaseService.userId,
        'email': SupabaseService.userEmail,
        'name': profile?.name ?? SupabaseService.userName,
        'avatar_url': profile?.avatarUrl,
        'cover_url': uploaded.first,
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

  Future<void> deleteCover() async {
    final old = profile?.coverUrl;
    await SupabaseService.client
        .from('profiles')
        .update({'cover_url': null}).eq('id', SupabaseService.userId);
    if (old != null && old.isNotEmpty) {
      await SupabaseService.deleteByPublicUrls([old]);
    }
    await load();
  }
}
