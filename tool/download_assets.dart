// Downloads bundled JPEG assets. Run from project root:
//   dart tool/download_assets.dart

import 'dart:io';

/// Picsum + verified Unsplash URLs — see lib/core/constants/image_sources.dart
const _sources = <String, String>{
  'assets/images/products/school_starter_kit.jpg': 'https://picsum.photos/seed/kidcare-school-kit/640/480.jpg',
  'assets/images/products/classic_polo_uniform.jpg': 'https://picsum.photos/seed/kidcare-uniform/640/480.jpg',
  'assets/images/products/stem_activity_pack.jpg':
      'https://images.unsplash.com/photo-1532094349884-543bc11b234d?auto=format&fit=crop&w=640&q=80',
  'assets/images/products/vitamin_gummies.jpg': 'https://picsum.photos/seed/kidcare-vitamins/640/480.jpg',
  'assets/images/products/reading_adventure_set.jpg':
      'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=640&q=80',
  'assets/images/products/art_craft_box.jpg': 'https://picsum.photos/seed/kidcare-art-craft/640/480.jpg',
  'assets/images/products/promo_back_to_school.jpg':
      'https://picsum.photos/seed/kidcare-back-to-school/720/400.jpg',
  'assets/images/auth/welcome_hero.jpg':
      'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?auto=format&fit=crop&w=800&q=80',
  'assets/images/auth/login_hero.jpg':
      'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=800&q=80',
  'assets/images/auth/register_hero.jpg':
      'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=800&q=80',
  'assets/images/auth/register_teacher.jpg':
      'https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=800&q=80',
  'assets/images/auth/register_healthcare.jpg':
      'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=800&q=80',
  'assets/images/auth/register_child.jpg':
      'https://images.unsplash.com/photo-1544776193-352d25ca82cd?auto=format&fit=crop&w=800&q=80',
  'assets/images/auth/feature_parent.jpg':
      'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=480&q=80',
  'assets/images/auth/feature_teacher.jpg':
      'https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=480&q=80',
  'assets/images/auth/feature_healthcare.jpg':
      'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=480&q=80',
  'assets/images/auth/feature_child.jpg':
      'https://images.unsplash.com/photo-1544776193-352d25ca82cd?auto=format&fit=crop&w=480&q=80',
  'assets/images/auth/feature_secure.jpg':
      'https://images.unsplash.com/photo-1563986768609-322da13575f3?auto=format&fit=crop&w=480&q=80',
};

Future<void> main() async {
  final root = Directory.current.path;
  var ok = 0;
  var failed = 0;

  for (final entry in _sources.entries) {
    final path = '$root${Platform.pathSeparator}${entry.key.replaceAll('/', Platform.pathSeparator)}';
    final file = File(path);
    file.parent.createSync(recursive: true);

    stdout.write('Downloading ${file.uri.pathSegments.last}... ');
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(entry.value));
      request.headers.set('User-Agent', 'KidCare-Asset-Downloader/1.0');
      final response = await request.close();
      if (response.statusCode != 200) {
        stderr.writeln('FAILED (HTTP ${response.statusCode})');
        failed++;
        client.close(force: true);
        continue;
      }
      await response.pipe(file.openWrite());
      client.close();
      final kb = (await file.length()) / 1024;
      if (kb < 1) {
        stderr.writeln('FAILED (empty file)');
        await file.delete();
        failed++;
        continue;
      }
      stdout.writeln('OK (${kb.toStringAsFixed(1)} KB)');
      ok++;
    } catch (e) {
      stderr.writeln('FAILED ($e)');
      failed++;
    }
  }

  stdout.writeln('\nDone: $ok succeeded, $failed failed.');
  if (failed > 0) exitCode = 1;
}
