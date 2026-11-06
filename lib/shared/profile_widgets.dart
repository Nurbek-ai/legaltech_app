import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'user_profile.dart';

/// Renders the avatar photo at full quality if selected, otherwise shows initials
/// inside a deep navy (#102B57) badge as shown in the YAN360 reference.
Widget buildAvatarContent(
  UserProfileData profile, {
  double initialsSize = 19,
}) {
  if (profile.avatarFile != null) {
    return Image.file(
      profile.avatarFile!,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      width: double.infinity,
      height: double.infinity,
    );
  }
  return Center(
    child: Text(
      profile.initials,
      style: TextStyle(
        color: Colors.white,
        fontSize: initialsSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class FullScreenPhotoPage extends StatelessWidget {
  final File file;

  const FullScreenPhotoPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: YanColors.background,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Opacity(
                  opacity: 0.25,
                  child: Image.file(file, fit: BoxFit.cover),
                ),
              ),
            ),
            Center(
              child: Hero(
                tag: 'profile-avatar-hero',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.88,
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: YanColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: YanColors.border),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: YanColors.primaryNavy.withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: YanColors.primaryNavy,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}