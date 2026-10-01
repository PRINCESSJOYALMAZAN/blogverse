import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  SupabaseService._();

  static final client = Supabase.instance.client;
  static const _uuid = Uuid();
  static const imageBucket = 'forum-images';

  static String get userId => client.auth.currentUser!.id;
  static String get userEmail => client.auth.currentUser?.email ?? '';
  static String get userName {
    final metaName =
        client.auth.currentUser?.userMetadata?['name']?.toString().trim();
    if (metaName != null && metaName.isNotEmpty) return metaName;
    final email = userEmail;
    if (email.contains('@')) return email.split('@').first;
    return 'Member';
  }

  static Future<void> ensureCurrentProfile({String? name}) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    final trimmedName = name?.trim();
    final displayName =
        trimmedName != null && trimmedName.isNotEmpty ? trimmedName : userName;

    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'name': displayName,
      });
    } catch (_) {
      // Ignore database profile creation errors so auth doesn't get blocked
    }
  }

  static Future<List<String>> uploadImages(
    List<XFile> files, {
    required String folder,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final rawExtension = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
      final extension = RegExp(r'^[a-z0-9]{1,5}$').hasMatch(rawExtension)
          ? rawExtension
          : 'jpg';
      final path = '$folder/${userId}_${_uuid.v4()}.$extension';
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw ArgumentError(
            'The selected image is empty or could not be read.');
      }
      await client.storage.from(imageBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: file.mimeType?.startsWith('image/') == true
                  ? file.mimeType
                  : _contentTypeFor(extension),
              upsert: false,
            ),
          );
      urls.add(client.storage.from(imageBucket).getPublicUrl(path));
    }
    return urls;
  }

  static String _contentTypeFor(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  static Future<void> deleteByPublicUrls(List<String> urls) async {
    final paths = urls.map(_pathFromPublicUrl).whereType<String>().toList();
    if (paths.isNotEmpty) {
      await client.storage.from(imageBucket).remove(paths);
    }
  }

  static String? _pathFromPublicUrl(String url) {
    const marker = '/object/public/$imageBucket/';
    final index = url.indexOf(marker);
    if (index == -1) return null;
    return Uri.decodeFull(url.substring(index + marker.length));
  }
}
