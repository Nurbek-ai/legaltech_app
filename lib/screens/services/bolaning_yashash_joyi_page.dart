import 'package:flutter/material.dart';

import '../../services/family_claim_document_service.dart';
import 'family_claim_page.dart';

/// Delegates to the unified [FamilyClaimPage] configured for
/// [FamilyClaimType.childResidence] (`bolaning_yashash_joyi.docx`).
class ChildLivingPlacePage extends StatelessWidget {
  const ChildLivingPlacePage({
    super.key,
    this.onSubmit,
  });

  final Future<void> Function(Map<String, dynamic> payload)? onSubmit;

  @override
  Widget build(BuildContext context) {
    return FamilyClaimPage(
      type: FamilyClaimType.childResidence,
      onSubmit: onSubmit,
    );
  }
}
