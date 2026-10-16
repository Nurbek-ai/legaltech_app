import 'package:flutter/material.dart';

import '../../services/family_claim_document_service.dart';
import 'family_claim_page.dart';

/// Delegates to the unified [FamilyClaimPage] configured for
/// [FamilyClaimType.divorce] (`nikohdan_ajrashish.docx`).
class DivorceClaimPage extends StatelessWidget {
  const DivorceClaimPage({
    super.key,
    this.onSubmit,
  });

  final Future<void> Function(Map<String, dynamic> payload)? onSubmit;

  @override
  Widget build(BuildContext context) {
    return FamilyClaimPage(
      type: FamilyClaimType.divorce,
      onSubmit: onSubmit,
    );
  }
}
