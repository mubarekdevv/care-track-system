import 'package:flutter/material.dart';

import '../../core/photo/profile_photo_service.dart';

/// Avatar from Firestore data URL, Storage https URL, or initials fallback.
class KidCareAvatarImage extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final Color accent;

  const KidCareAvatarImage({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 28,
    this.accent = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    if (url != null && url.isNotEmpty) {
      if (ProfilePhotoService.isDataUrl(url)) {
        final bytes = ProfilePhotoService.bytesFromDataUrl(url);
        if (bytes != null) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
          );
        }
      } else if (ProfilePhotoService.isHttpUrl(url)) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: accent.withValues(alpha: 0.15),
          backgroundImage: NetworkImage(url),
          onBackgroundImageError: (_, __) {},
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: accent.withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
          color: accent,
        ),
      ),
    );
  }
}
