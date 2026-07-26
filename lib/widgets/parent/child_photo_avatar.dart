import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/child_model.dart';
import '../../providers/child_provider.dart';

/// Tappable child avatar with camera badge — uploads via [ChildProvider.updateChildPhoto].
class ChildPhotoAvatar extends StatefulWidget {
  final ChildModel child;
  final double radius;
  final bool editable;
  final Color? borderColor;

  const ChildPhotoAvatar({
    super.key,
    required this.child,
    this.radius = 36,
    this.editable = true,
    this.borderColor,
  });

  @override
  State<ChildPhotoAvatar> createState() => _ChildPhotoAvatarState();
}

class _ChildPhotoAvatarState extends State<ChildPhotoAvatar> {
  final _picker = ImagePicker();
  Uint8List? _localPreview;
  bool _uploading = false;

  ChildModel _resolveChild(ChildProvider provider) {
    for (final c in provider.children) {
      if (c.id == widget.child.id) return c;
    }
    return widget.child;
  }

  Future<void> _pickAndUpload() async {
    if (!widget.editable || _uploading) return;

    try {
      final selected = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (selected == null || !mounted) return;

      final bytes = await selected.readAsBytes();
      if (!mounted) return;
      setState(() {
        _localPreview = bytes;
        _uploading = true;
      });

      final success = await Provider.of<ChildProvider>(context, listen: false)
          .updateChildPhoto(childId: widget.child.id, imageBytes: bytes);

      if (!mounted) return;

      setState(() => _uploading = false);

      if (success) {
        setState(() => _localPreview = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo updated for ${widget.child.name}!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.softGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not upload photo. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _resolveChild(Provider.of<ChildProvider>(context));
    final accent = widget.borderColor ?? AppTheme.primaryBlue;

    Widget avatar;
    if (_localPreview != null) {
      avatar = CircleAvatar(
        radius: widget.radius,
        backgroundImage: MemoryImage(_localPreview!),
      );
    } else if (child.imageUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: widget.radius,
        backgroundColor: accent.withValues(alpha: 0.2),
        backgroundImage: NetworkImage(child.imageUrl),
      );
    } else {
      avatar = CircleAvatar(
        radius: widget.radius,
        backgroundColor: accent.withValues(alpha: 0.2),
        child: Text(
          child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C',
          style: TextStyle(
            fontSize: widget.radius * 0.75,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
      );
    }

    if (!widget.editable) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickAndUpload,
            customBorder: const CircleBorder(),
            child: avatar,
          ),
        ),
        if (_uploading)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
          ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _pickAndUpload,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
