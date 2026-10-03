import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'user_profile.dart';

/// Renders the avatar photo if one was selected, otherwise shows initials.
/// [initialsSize] is larger on the profile hero, smaller on the mini card.
Widget buildAvatarContent(UserProfileData profile, {double initialsSize = 22}) {
  if (profile.avatarFile != null) {
    return Image.file(
      profile.avatarFile!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
  return Center(
    child: Text(
      profile.initials,
      style: TextStyle(
        color: const Color(0xFFDCEAFF),
        fontSize: initialsSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );
}

/// Full-screen photo viewer — Telegram / Instagram style.
///
/// - Blurred background
/// - Dark overlay
/// - Hero-animated photo
/// - Tap anywhere or press X to close
class FullScreenPhotoPage extends StatelessWidget {
  final File file;

  const FullScreenPhotoPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Blurred background
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Image.file(file, fit: BoxFit.cover),
              ),
            ),
            // Dim overlay
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withOpacity(0.58)),
            ),
            // The photo
            Center(
              child: Hero(
                tag: 'profile-avatar-hero',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.88,
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    child: Image.file(file, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            // Close button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.50),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.22),
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 17,
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
