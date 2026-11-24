import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/case_progress_service.dart';

// =============================================================================
// CENTRALIZED STATUS-TO-STYLE MAPPING SYSTEM
// Single source of truth for card tint, border, indicator, badge, and line.
// Never manually assign colours to individual cases or timeline events.
// =============================================================================

@immutable
class CaseStepStatusStyle {
  final String label;
  final Color cardBackground;
  final Color cardBorder;
  final Color indicatorFill;
  final Color indicatorBorder;
  final Color indicatorIconColor;
  final IconData? indicatorIcon;
  final Color badgeBackground;
  final Color badgeText;
  final Color lineColor;
  final bool isDashedLine;
  final bool isHollowIndicator;
  final bool isDoubleRingIndicator;
  final bool isActiveAnimated;
  final Color titleColor;
  final Color descriptionColor;
  final Color calloutBackground;
  final Color calloutBorder;
  final Color calloutText;

  const CaseStepStatusStyle({
    required this.label,
    required this.cardBackground,
    required this.cardBorder,
    required this.indicatorFill,
    required this.indicatorBorder,
    required this.indicatorIconColor,
    required this.indicatorIcon,
    required this.badgeBackground,
    required this.badgeText,
    required this.lineColor,
    this.isDashedLine = false,
    this.isHollowIndicator = false,
    this.isDoubleRingIndicator = false,
    this.isActiveAnimated = false,
    this.titleColor = const Color(0xFF102B50),
    this.descriptionColor = const Color(0xFF475569),
    required this.calloutBackground,
    required this.calloutBorder,
    required this.calloutText,
  });

  static CaseStepStatusStyle of(CaseStepStatus status) {
    switch (status) {
      case CaseStepStatus.completed:
        return const CaseStepStatusStyle(
          label: 'Yakunlandi',
          cardBackground: Color(0xFFF0FDF4),
          cardBorder: Color(0xFF86EFAC),
          indicatorFill: Color(0xFF16A34A),
          indicatorBorder: Color(0xFF16A34A),
          indicatorIconColor: Colors.white,
          indicatorIcon: Icons.check_rounded,
          badgeBackground: Color(0xFFDCFCE7),
          badgeText: Color(0xFF15803D),
          lineColor: Color(0xFF16A34A),
          calloutBackground: Color(0xFFDCFCE7),
          calloutBorder: Color(0xFF86EFAC),
          calloutText: Color(0xFF166534),
        );
      case CaseStepStatus.successful:
        return const CaseStepStatusStyle(
          label: 'Muvaffaqiyatli',
          cardBackground: Color(0xFFF0FDF4),
          cardBorder: Color(0xFF86EFAC),
          indicatorFill: Color(0xFF16A34A),
          indicatorBorder: Color(0xFF16A34A),
          indicatorIconColor: Colors.white,
          indicatorIcon: Icons.check_rounded,
          badgeBackground: Color(0xFFDCFCE7),
          badgeText: Color(0xFF15803D),
          lineColor: Color(0xFF16A34A),
          calloutBackground: Color(0xFFDCFCE7),
          calloutBorder: Color(0xFF86EFAC),
          calloutText: Color(0xFF166534),
        );
      case CaseStepStatus.failed:
        return const CaseStepStatusStyle(
          label: 'Muvaffaqiyatsiz',
          cardBackground: Color(0xFFFEF2F2),
          cardBorder: Color(0xFFFCA5A5),
          indicatorFill: Color(0xFFDC2626),
          indicatorBorder: Color(0xFFDC2626),
          indicatorIconColor: Colors.white,
          indicatorIcon: Icons.close_rounded,
          badgeBackground: Color(0xFFFEE2E2),
          badgeText: Color(0xFFB91C1C),
          lineColor: Color(0xFFDC2626),
          calloutBackground: Color(0xFFFEE2E2),
          calloutBorder: Color(0xFFFCA5A5),
          calloutText: Color(0xFF991B1B),
        );
      case CaseStepStatus.postponed:
        return const CaseStepStatusStyle(
          label: 'Kechiktirildi',
          cardBackground: Color(0xFFFFF7ED),
          cardBorder: Color(0xFFFDBA74),
          indicatorFill: Color(0xFFEA580C),
          indicatorBorder: Color(0xFFEA580C),
          indicatorIconColor: Colors.white,
          indicatorIcon: Icons.schedule_rounded,
          badgeBackground: Color(0xFFFFEDD5),
          badgeText: Color(0xFFC2410C),
          lineColor: Color(0xFFEA580C),
          calloutBackground: Color(0xFFFFEDD5),
          calloutBorder: Color(0xFFFDBA74),
          calloutText: Color(0xFF9A3412),
        );
      case CaseStepStatus.rejected:
        return const CaseStepStatusStyle(
          label: 'Rad etildi',
          cardBackground: Color(0xFFFFF7ED),
          cardBorder: Color(0xFFFDBA74),
          indicatorFill: Color(0xFFEA580C),
          indicatorBorder: Color(0xFFEA580C),
          indicatorIconColor: Colors.white,
          indicatorIcon: Icons.priority_high_rounded,
          badgeBackground: Color(0xFFFFEDD5),
          badgeText: Color(0xFFC2410C),
          lineColor: Color(0xFFEA580C),
          calloutBackground: Color(0xFFFFEDD5),
          calloutBorder: Color(0xFFFDBA74),
          calloutText: Color(0xFF9A3412),
        );
      case CaseStepStatus.inProgress:
        return const CaseStepStatusStyle(
          label: 'Jarayonda',
          cardBackground: Color(0xFFEFF6FF),
          cardBorder: Color(0xFF60A5FA),
          indicatorFill: Color(0xFF1677D2),
          indicatorBorder: Color(0xFF1677D2),
          indicatorIconColor: Colors.white,
          indicatorIcon: null,
          badgeBackground: Color(0xFF1677D2),
          badgeText: Colors.white,
          lineColor: Color(0xFF1677D2),
          isDoubleRingIndicator: true,
          isActiveAnimated: true,
          calloutBackground: Color(0xFFDBEAFE),
          calloutBorder: Color(0xFF93C5FD),
          calloutText: Color(0xFF1E40AF),
        );
      case CaseStepStatus.upcoming:
        return const CaseStepStatusStyle(
          label: 'Kutilmoqda',
          cardBackground: Color(0xFFF8FAFC),
          cardBorder: Color(0xFFCBD5E1),
          indicatorFill: Colors.white,
          indicatorBorder: Color(0xFFCBD5E1),
          indicatorIconColor: Color(0xFF94A3B8),
          indicatorIcon: null,
          badgeBackground: Color(0xFFF1F5F9),
          badgeText: Color(0xFF64748B),
          lineColor: Color(0xFFCBD5E1),
          isDashedLine: true,
          isHollowIndicator: true,
          titleColor: Color(0xFF64748B),
          descriptionColor: Color(0xFF94A3B8),
          calloutBackground: Color(0xFFF1F5F9),
          calloutBorder: Color(0xFFCBD5E1),
          calloutText: Color(0xFF475569),
        );
    }
  }
}

// =============================================================================
// UZBEK DATE FORMATTING HELPERS
// =============================================================================

const List<String> _uzMonths = <String>[
  'yanvar',
  'fevral',
  'mart',
  'aprel',
  'may',
  'iyun',
  'iyul',
  'avgust',
  'sentyabr',
  'oktyabr',
  'noyabr',
  'dekabr',
];

String _formatUzDateTime(DateTime dt, {bool includeTime = true}) {
  final l = dt.toLocal();
  final month = _uzMonths[l.month - 1];
  if (!includeTime) {
    return '${l.day} $month, ${l.year}';
  }
  final hh = l.hour.toString().padLeft(2, '0');
  final mm = l.minute.toString().padLeft(2, '0');
  return '${l.day} $month, $hh:$mm';
}

// =============================================================================
// REUSABLE VERTICAL CASE PROGRESS STEPPER COMPONENT
// Decoupled from data fetching/storage; accepts any list of CaseProgressStep.
// =============================================================================

class VerticalCaseProgressStepper extends StatefulWidget {
  final List<CaseProgressStep> steps;
  final bool canEdit;
  final ValueChanged<CaseProgressStep>? onEditStep;
  final ValueChanged<CaseProgressStep>? onDeleteStep;
  final ValueChanged<CaseStepDocument>? onOpenDocument;

  const VerticalCaseProgressStepper({
    super.key,
    required this.steps,
    this.canEdit = false,
    this.onEditStep,
    this.onDeleteStep,
    this.onOpenDocument,
  });

  @override
  State<VerticalCaseProgressStepper> createState() =>
      _VerticalCaseProgressStepperState();
}

class _VerticalCaseProgressStepperState
    extends State<VerticalCaseProgressStepper> {
  final Set<String> _expandedStepIds = <String>{};

  void _toggleExpanded(String stepId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedStepIds.contains(stepId)) {
        _expandedStepIds.remove(stepId);
      } else {
        _expandedStepIds.add(stepId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List<Widget>.generate(widget.steps.length, (index) {
        final step = widget.steps[index];
        final isFirst = index == 0;
        final isLast = index == widget.steps.length - 1;
        final prevStyle = isFirst
            ? null
            : CaseStepStatusStyle.of(widget.steps[index - 1].status);
        final currentStyle = CaseStepStatusStyle.of(step.status);
        final isExpanded = _expandedStepIds.contains(step.id);

        return _TimelineStepRow(
          key: ValueKey<String>(step.id),
          step: step,
          style: currentStyle,
          previousStyle: prevStyle,
          isFirst: isFirst,
          isLast: isLast,
          isExpanded: isExpanded,
          canEdit: widget.canEdit,
          onToggleExpand: () => _toggleExpanded(step.id),
          onEdit:
              widget.onEditStep != null ? () => widget.onEditStep!(step) : null,
          onDelete: widget.onDeleteStep != null
              ? () => widget.onDeleteStep!(step)
              : null,
          onOpenDocument: widget.onOpenDocument,
        );
      }),
    );
  }
}

class _TimelineStepRow extends StatelessWidget {
  final CaseProgressStep step;
  final CaseStepStatusStyle style;
  final CaseStepStatusStyle? previousStyle;
  final bool isFirst;
  final bool isLast;
  final bool isExpanded;
  final bool canEdit;
  final VoidCallback onToggleExpand;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<CaseStepDocument>? onOpenDocument;

  const _TimelineStepRow({
    super.key,
    required this.step,
    required this.style,
    required this.previousStyle,
    required this.isFirst,
    required this.isLast,
    required this.isExpanded,
    required this.canEdit,
    required this.onToggleExpand,
    this.onEdit,
    this.onDelete,
    this.onOpenDocument,
  });

  static const double _railWidth = 34;
  static const double _indicatorTopOffset = 18;
  static const double _indicatorSize = 26;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Left Vertical Timeline Rail
          SizedBox(
            width: _railWidth,
            child: Column(
              children: <Widget>[
                // Top connector (from previous step into current indicator)
                SizedBox(
                  height: _indicatorTopOffset,
                  width: _railWidth,
                  child: isFirst
                      ? null
                      : CustomPaint(
                          painter: _VerticalLinePainter(
                            color: previousStyle?.lineColor ?? style.lineColor,
                            isDashed: previousStyle?.isDashedLine ?? false,
                          ),
                        ),
                ),

                // Circular Status Indicator (pulses ONLY when in_progress)
                _TimelineStatusIndicator(
                  style: style,
                  size: _indicatorSize,
                ),

                // Bottom connector (from current indicator down to next step)
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : SizedBox(
                          width: _railWidth,
                          child: CustomPaint(
                            painter: _VerticalLinePainter(
                              color: style.lineColor,
                              isDashed: style.isDashedLine,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right Process Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: _ProcessCardContainer(
                style: style,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onToggleExpand,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: style.indicatorBorder.withValues(alpha: 0.06),
                    highlightColor:
                        style.indicatorBorder.withValues(alpha: 0.03),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Header: Title + Status Badge + Chevron
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: style.titleColor,
                                    height: 1.3,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: style.badgeBackground,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  style.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: style.badgeText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 19,
                                    color: style.descriptionColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Event Date & Time (when available)
                          if (step.eventDate != null) ...<Widget>[
                            const SizedBox(height: 5),
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: style.descriptionColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _formatUzDateTime(step.eventDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: style.descriptionColor,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Short Description
                          if (step.shortDescription.trim().isNotEmpty) ...<Widget>[
                            const SizedBox(height: 7),
                            Text(
                              step.shortDescription.trim(),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: style.descriptionColor,
                                height: 1.45,
                              ),
                            ),
                          ],

                          // Inline Failure / Postponement Callout (when applicable)
                          if (step.failureReason.trim().isNotEmpty &&
                              (step.status == CaseStepStatus.failed ||
                                  step.status == CaseStepStatus.postponed ||
                                  step.status == CaseStepStatus.rejected)) ...<Widget>[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: style.calloutBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: style.calloutBorder,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 15,
                                    color: style.calloutText,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      step.failureReason.trim(),
                                      style: TextStyle(
                                        fontSize: 12.2,
                                        fontWeight: FontWeight.w600,
                                        color: style.calloutText,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Compact Attachment Count Pill when collapsed
                          if (!isExpanded && step.attachments.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 9),
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 13.5,
                                  color: style.badgeText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${step.attachments.length} ta ilova hujjat',
                                  style: TextStyle(
                                    fontSize: 11.8,
                                    fontWeight: FontWeight.w600,
                                    color: style.badgeText,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Smooth Expandable Section
                          AnimatedSize(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: isExpanded
                                ? AnimatedOpacity(
                                    opacity: isExpanded ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: _ExpandedStepDetails(
                                      step: step,
                                      style: style,
                                      canEdit: canEdit,
                                      onEdit: onEdit,
                                      onDelete: onDelete,
                                      onOpenDocument: onOpenDocument,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EXPANDED CARD DETAILS (ONLY RENDERS NON-EMPTY REAL DATA)
// =============================================================================

class _ExpandedStepDetails extends StatelessWidget {
  final CaseProgressStep step;
  final CaseStepStatusStyle style;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<CaseStepDocument>? onOpenDocument;

  const _ExpandedStepDetails({
    required this.step,
    required this.style,
    required this.canEdit,
    this.onEdit,
    this.onDelete,
    this.onOpenDocument,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnyDetails = step.hasExpandableContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 12),
        Divider(
          height: 1,
          thickness: 1,
          color: style.cardBorder.withValues(alpha: 0.55),
        ),
        const SizedBox(height: 12),

        if (!hasAnyDetails && !canEdit)
          const Text(
            'Ushbu bosqich bo‘yicha qo‘shimcha tafsilotlar kiritilmagan.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),

        // A. Additional Process Information
        if (step.detailedExplanation.trim().isNotEmpty) ...<Widget>[
          const _DetailSectionHeading(
            icon: Icons.subject_rounded,
            label: 'Batafsil ma’lumot',
          ),
          const SizedBox(height: 5),
          Text(
            step.detailedExplanation.trim(),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (step.actionsTaken.trim().isNotEmpty) ...<Widget>[
          const _DetailSectionHeading(
            icon: Icons.task_alt_rounded,
            label: 'Ko‘rilgan choralar',
          ),
          const SizedBox(height: 5),
          Text(
            step.actionsTaken.trim(),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (step.nextSteps.trim().isNotEmpty) ...<Widget>[
          const _DetailSectionHeading(
            icon: Icons.arrow_forward_rounded,
            label: 'Keyingi qadam',
          ),
          const SizedBox(height: 5),
          Text(
            step.nextSteps.trim(),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // B. Uploaded Documents
        if (step.attachments.isNotEmpty) ...<Widget>[
          const _DetailSectionHeading(
            icon: Icons.folder_open_rounded,
            label: 'Yuklangan hujjatlar',
          ),
          const SizedBox(height: 7),
          ...step.attachments.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: InkWell(
                onTap: onOpenDocument != null ? () => onOpenDocument!(doc) : null,
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFDCE6F2)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FC),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          doc.fileType,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1677D2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              doc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.8,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF102B50),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatUzDateTime(doc.uploadedAt, includeTime: false),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
                        color: Color(0xFF1677D2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],

        // C. Lawyer Comments
        if (step.lawyerComment.trim().isNotEmpty) ...<Widget>[
          const _DetailSectionHeading(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Advokat izohi',
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFDCE6F2)),
            ),
            child: Text(
              step.lawyerComment.trim(),
              style: const TextStyle(
                fontSize: 12.8,
                color: Color(0xFF102B50),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // D. Relevant Dates
        if (step.hasRelevantDates) ...<Widget>[
          const _DetailSectionHeading(
            icon: Icons.calendar_today_outlined,
            label: 'Muhim sanalar',
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFDCE6F2)),
            ),
            child: Column(
              children: <Widget>[
                if (step.startedAt != null)
                  _DateMetaRow(
                    label: 'Boshlangan sana',
                    value: _formatUzDateTime(step.startedAt!),
                  ),
                if (step.submittedAt != null)
                  _DateMetaRow(
                    label: 'Topshirilgan sana',
                    value: _formatUzDateTime(step.submittedAt!),
                  ),
                if (step.decisionAt != null)
                  _DateMetaRow(
                    label: 'Qaror / javob sanasi',
                    value: _formatUzDateTime(step.decisionAt!),
                  ),
                if (step.completedAt != null)
                  _DateMetaRow(
                    label: 'Yakunlangan sana',
                    value: _formatUzDateTime(step.completedAt!),
                  ),
                if (step.nextActionAt != null)
                  _DateMetaRow(
                    label: 'Keyingi amal sanasi',
                    value: _formatUzDateTime(step.nextActionAt!),
                  ),
              ],
            ),
          ),
        ],

        // Advocate Controls (strictly hidden from clients)
        if (canEdit) ...<Widget>[
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              if (onEdit != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1677D2),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text(
                      'Tahrirlash',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (onEdit != null && onDelete != null) const SizedBox(width: 8),
              if (onDelete != null)
                OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 15),
                  label: const Text(
                    'O‘chirish',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DetailSectionHeading extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailSectionHeading({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: const Color(0xFF1677D2)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF102B50),
          ),
        ),
      ],
    );
  }
}

class _DateMetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _DateMetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF102B50),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ACTIVE-ONLY CARD BORDER ANIMATION & STATIC CARD CONTAINER
// =============================================================================

class _ProcessCardContainer extends StatefulWidget {
  final CaseStepStatusStyle style;
  final Widget child;

  const _ProcessCardContainer({
    required this.style,
    required this.child,
  });

  @override
  State<_ProcessCardContainer> createState() => _ProcessCardContainerState();
}

class _ProcessCardContainerState extends State<_ProcessCardContainer>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant _ProcessCardContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style.isActiveAnimated != widget.style.isActiveAnimated) {
      _syncController();
    }
  }

  void _syncController() {
    if (widget.style.isActiveAnimated) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3400),
      )..repeat();
    } else {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final shouldAnimate = widget.style.isActiveAnimated && !reducedMotion;

    if (!shouldAnimate || _controller == null) {
      return Container(
        decoration: BoxDecoration(
          color: widget.style.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.style.cardBorder,
            width: 1.2,
          ),
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _TravellingBorderPainter(
            progress: _controller!.value,
            radius: 16,
            baseColor: widget.style.cardBorder,
            highlightColor: const Color(0xFF1677D2),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: widget.style.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.style.cardBorder.withValues(alpha: 0.65),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _TravellingBorderPainter extends CustomPainter {
  final double progress;
  final double radius;
  final Color baseColor;
  final Color highlightColor;

  _TravellingBorderPainter({
    required this.progress,
    required this.radius,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.8),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final total = metric.length;
    final segmentLen = total * 0.24;
    final start = (progress * total) % total;
    final end = start + segmentLen;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = highlightColor.withValues(alpha: 0.85);

    if (end <= total) {
      canvas.drawPath(metric.extractPath(start, end), paint);
    } else {
      canvas.drawPath(metric.extractPath(start, total), paint);
      canvas.drawPath(metric.extractPath(0, end - total), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TravellingBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// =============================================================================
// TIMELINE INDICATOR (PULSES ONLY FOR IN_PROGRESS)
// =============================================================================

class _TimelineStatusIndicator extends StatefulWidget {
  final CaseStepStatusStyle style;
  final double size;

  const _TimelineStatusIndicator({
    required this.style,
    required this.size,
  });

  @override
  State<_TimelineStatusIndicator> createState() =>
      _TimelineStatusIndicatorState();
}

class _TimelineStatusIndicatorState extends State<_TimelineStatusIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _TimelineStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style.isActiveAnimated != widget.style.isActiveAnimated) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (widget.style.isActiveAnimated) {
      _pulseController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )..repeat(reverse: true);
    } else {
      _pulseController?.dispose();
      _pulseController = null;
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final size = widget.size;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    // Double-ring animated blue indicator for in_progress
    if (s.isDoubleRingIndicator) {
      final dot = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFDBEAFE),
          border: Border.all(color: s.indicatorBorder, width: 2),
        ),
        child: Center(
          child: Container(
            width: size * 0.44,
            height: size * 0.44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.indicatorFill,
            ),
          ),
        ),
      );

      if (reducedMotion || _pulseController == null) {
        return SizedBox(width: size + 8, height: size + 8, child: Center(child: dot));
      }

      return AnimatedBuilder(
        animation: _pulseController!,
        builder: (context, child) {
          final t = _pulseController!.value;
          return SizedBox(
            width: size + 8,
            height: size + 8,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: size + (t * 8),
                  height: size + (t * 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.indicatorFill.withValues(alpha: 0.18 * (1 - t)),
                  ),
                ),
                child!,
              ],
            ),
          );
        },
        child: dot,
      );
    }

    // Hollow grey circle for upcoming
    if (s.isHollowIndicator) {
      return SizedBox(
        width: size + 8,
        height: size + 8,
        child: Center(
          child: Container(
            width: size - 2,
            height: size - 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: s.indicatorBorder, width: 2),
            ),
          ),
        ),
      );
    }

    // Static filled circle with white icon for completed, successful, failed, postponed, rejected
    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: s.indicatorFill,
          ),
          child: s.indicatorIcon != null
              ? Icon(s.indicatorIcon, color: s.indicatorIconColor, size: 15)
              : null,
        ),
      ),
    );
  }
}

// =============================================================================
// SOLID & DASHED VERTICAL CONNECTING LINE PAINTER
// =============================================================================

class _VerticalLinePainter extends CustomPainter {
  final Color color;
  final bool isDashed;

  _VerticalLinePainter({
    required this.color,
    required this.isDashed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (!isDashed) {
      canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
      return;
    }

    const dashHeight = 5.0;
    const dashGap = 4.5;
    double y = 0;
    while (y < size.height) {
      final nextY = (y + dashHeight).clamp(0.0, size.height);
      canvas.drawLine(Offset(cx, y), Offset(cx, nextY), paint);
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDashed != isDashed;
}

// =============================================================================
// FULL PAGE SCREEN: INTEGRATED CASE PROGRESS TRACKER
// Pure white surface, no percentage/stats clutter, Advocate CRUD + Client view
// =============================================================================

class CaseProgressStepperPage extends StatefulWidget {
  final String advocateId;
  final String clientId;
  final String peerName;
  final String caseTitle;
  final bool isAdvocate;

  const CaseProgressStepperPage({
    super.key,
    required this.advocateId,
    required this.clientId,
    required this.peerName,
    this.caseTitle = 'Ish jarayoni',
    required this.isAdvocate,
  });

  @override
  State<CaseProgressStepperPage> createState() =>
      _CaseProgressStepperPageState();
}

class _CaseProgressStepperPageState extends State<CaseProgressStepperPage> {
  late final String _caseKey;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _caseKey = CaseProgressRepository.buildCaseKey(
      widget.advocateId,
      widget.clientId,
    );
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isRefreshing = true);
    await CaseProgressRepository.instance.loadCase(
      advocateId: widget.advocateId,
      clientId: widget.clientId,
    );
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _openDocument(CaseStepDocument doc) async {
    final err = await CaseProgressRepository.instance.openDocument(doc);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(err),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF102B50),
          ),
        );
    }
  }

  Future<void> _confirmDeleteStep(CaseProgressStep step) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Bosqichni o‘chirish',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF102B50),
          ),
        ),
        content: Text(
          '“${step.title}” bosqichini ish jarayonidan o‘chirmoqchimisiz?',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('O‘chirish'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await CaseProgressRepository.instance.deleteStep(step);
    }
  }

  Future<void> _openStepEditor({CaseProgressStep? existing}) async {
    if (!widget.isAdvocate) return;
    final currentSteps =
        CaseProgressRepository.instance.notifierForCase(_caseKey).value;

    final saved = await showModalBottomSheet<CaseProgressStep>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CaseStepEditorSheet(
        caseKey: _caseKey,
        advocateId: widget.advocateId,
        clientId: widget.clientId,
        nextSortOrder: currentSteps.length,
        existing: existing,
      ),
    );
    if (saved != null) {
      final err = await CaseProgressRepository.instance.upsertStep(saved);
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = CaseProgressRepository.instance.notifierForCase(_caseKey);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF102B50),
          ),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.caseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF102B50),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              widget.isAdvocate
                  ? 'Mijoz: ${widget.peerName}'
                  : 'Advokat: ${widget.peerName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _isRefreshing ? null : _load,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1677D2),
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF102B50),
                  ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE8EFF7)),
        ),
      ),
      floatingActionButton: widget.isAdvocate
          ? FloatingActionButton.extended(
              onPressed: () => _openStepEditor(),
              backgroundColor: const Color(0xFF1677D2),
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Bosqich qo‘shish',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: ValueListenableBuilder<List<CaseProgressStep>>(
        valueListenable: notifier,
        builder: (context, steps, _) {
          if (steps.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Icon(
                          Icons.timeline_rounded,
                          size: 28,
                          color: Color(0xFF1677D2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Hozircha ish bosqichlari kiritilmagan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF102B50),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isAdvocate
                            ? 'Mijoz o‘z ishining borishini kuzatib borishi uchun bosqich qo‘shing yoki standart shablondan boshlang.'
                            : 'Advokatingiz ish bosqichlarini qo‘shgach, barcha jarayonlar shu yerda ketma-ket ko‘rinadi.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.2,
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                      if (widget.isAdvocate) ...<Widget>[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openStepEditor(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1677D2),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 19),
                            label: const Text(
                              'Birinchi bosqichni qo‘shish',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await CaseProgressRepository.instance
                                  .seedStandardCaseTemplate(
                                advocateId: widget.advocateId,
                                clientId: widget.clientId,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1677D2),
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            icon: const Icon(
                              Icons.auto_awesome_motion_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Namuna bosqichlarni yuklash',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF1677D2),
            backgroundColor: Colors.white,
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                18,
                20,
                18,
                widget.isAdvocate ? 96 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: VerticalCaseProgressStepper(
                    steps: steps,
                    canEdit: widget.isAdvocate,
                    onEditStep: widget.isAdvocate
                        ? (s) => _openStepEditor(existing: s)
                        : null,
                    onDeleteStep: widget.isAdvocate ? _confirmDeleteStep : null,
                    onOpenDocument: _openDocument,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// ADVOCATE STEP EDITOR MODAL SHEET
// =============================================================================

class _CaseStepEditorSheet extends StatefulWidget {
  final String caseKey;
  final String advocateId;
  final String clientId;
  final int nextSortOrder;
  final CaseProgressStep? existing;

  const _CaseStepEditorSheet({
    required this.caseKey,
    required this.advocateId,
    required this.clientId,
    required this.nextSortOrder,
    this.existing,
  });

  @override
  State<_CaseStepEditorSheet> createState() => _CaseStepEditorSheetState();
}

class _CaseStepEditorSheetState extends State<_CaseStepEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _shortDescCtrl;
  late final TextEditingController _failureReasonCtrl;
  late final TextEditingController _detailsCtrl;
  late final TextEditingController _actionsTakenCtrl;
  late final TextEditingController _nextStepsCtrl;
  late final TextEditingController _lawyerCommentCtrl;

  late CaseStepStatus _status;
  DateTime? _eventDate;
  DateTime? _startedAt;
  DateTime? _submittedAt;
  DateTime? _decisionAt;
  DateTime? _completedAt;
  DateTime? _nextActionAt;
  late List<CaseStepDocument> _attachments;
  bool _uploadingDoc = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _shortDescCtrl = TextEditingController(text: e?.shortDescription ?? '');
    _failureReasonCtrl = TextEditingController(text: e?.failureReason ?? '');
    _detailsCtrl = TextEditingController(text: e?.detailedExplanation ?? '');
    _actionsTakenCtrl = TextEditingController(text: e?.actionsTaken ?? '');
    _nextStepsCtrl = TextEditingController(text: e?.nextSteps ?? '');
    _lawyerCommentCtrl = TextEditingController(text: e?.lawyerComment ?? '');
    _status = e?.status ?? CaseStepStatus.inProgress;
    _eventDate = e?.eventDate;
    _startedAt = e?.startedAt;
    _submittedAt = e?.submittedAt;
    _decisionAt = e?.decisionAt;
    _completedAt = e?.completedAt;
    _nextActionAt = e?.nextActionAt;
    _attachments = List<CaseStepDocument>.from(
      e?.attachments ?? const <CaseStepDocument>[],
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _shortDescCtrl.dispose();
    _failureReasonCtrl.dispose();
    _detailsCtrl.dispose();
    _actionsTakenCtrl.dispose();
    _nextStepsCtrl.dispose();
    _lawyerCommentCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1677D2),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF102B50),
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1677D2),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF102B50),
          ),
        ),
        child: child!,
      ),
    );

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? 9,
      pickedTime?.minute ?? 0,
    );
  }

  Future<void> _pickAndUploadDocument() async {
    if (_uploadingDoc) return;
    setState(() => _uploadingDoc = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final f = result.files.first;
        final path = (f.path ?? '').trim();
        final uploaded = await CaseProgressRepository.instance.uploadDocument(
          caseKey: widget.caseKey,
          fileName: f.name,
          bytes: f.bytes,
          file: path.isNotEmpty ? File(path) : null,
          localPath: path,
        );
        if (uploaded != null && mounted) {
          setState(() => _attachments.add(uploaded));
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faylni o‘qib bo‘lmadi. Boshqa faylni tanlab ko‘ring.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF102B50),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fayl tanlashda xatolik yuz berdi. Qayta urinib ko‘ring.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF102B50),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingDoc = false);
    }
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bosqich nomini kiriting.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF102B50),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final e = widget.existing;
    final step = CaseProgressStep(
      id: e?.id ?? 'STEP-${now.microsecondsSinceEpoch}',
      caseKey: widget.caseKey,
      advocateId: widget.advocateId,
      clientId: widget.clientId,
      sortOrder: e?.sortOrder ?? widget.nextSortOrder,
      title: title,
      shortDescription: _shortDescCtrl.text.trim(),
      status: _status,
      eventDate: _eventDate,
      failureReason: _failureReasonCtrl.text.trim(),
      detailedExplanation: _detailsCtrl.text.trim(),
      actionsTaken: _actionsTakenCtrl.text.trim(),
      nextSteps: _nextStepsCtrl.text.trim(),
      lawyerComment: _lawyerCommentCtrl.text.trim(),
      startedAt: _startedAt,
      submittedAt: _submittedAt,
      decisionAt: _decisionAt,
      completedAt: _completedAt,
      nextActionAt: _nextActionAt,
      attachments: _attachments,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.of(context).pop(step);
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102B50),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 13.8,
              color: Color(0xFF102B50),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 11,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1677D2),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          final picked = await _pickDateTime(value);
          if (picked != null) onChanged(picked);
        },
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFFDCE6F2)),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Color(0xFF1677D2),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Text(
                value != null ? _formatUzDateTime(value) : 'Tanlash',
                style: TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
                  color: value != null
                      ? const Color(0xFF102B50)
                      : const Color(0xFF1677D2),
                ),
              ),
              if (value != null) ...<Widget>[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final showReasonField = _status == CaseStepStatus.failed ||
        _status == CaseStepStatus.postponed ||
        _status == CaseStepStatus.rejected;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 18 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? 'Yangi bosqich qo‘shish'
                        : 'Bosqichni tahrirlash',
                    style: const TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF102B50),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE8EFF7)),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Bosqich holati',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF102B50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: CaseStepStatus.values.map((s) {
                        final st = CaseStepStatusStyle.of(s);
                        final selected = _status == s;
                        return GestureDetector(
                          onTap: () => setState(() => _status = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? st.indicatorFill : st.cardBackground,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selected ? st.indicatorFill : st.cardBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              st.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? (s == CaseStepStatus.upcoming
                                        ? const Color(0xFF102B50)
                                        : Colors.white)
                                    : st.badgeText,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    _buildInput(
                      controller: _titleCtrl,
                      label: 'Bosqich nomi *',
                      hint: 'Masalan: Dastlabki da’vo arizasini topshirish',
                    ),
                    _buildInput(
                      controller: _shortDescCtrl,
                      label: 'Qisqa tavsif',
                      hint: 'Jarayon haqida qisqacha ma’lumot',
                      maxLines: 2,
                    ),
                    if (showReasonField)
                      _buildInput(
                        controller: _failureReasonCtrl,
                        label: 'Rad etilish / kechikish sababi',
                        hint: 'Nima sababdan muvaffaqiyatsiz yoki kechiktirildi?',
                        maxLines: 2,
                      ),
                    _buildInput(
                      controller: _detailsCtrl,
                      label: 'Batafsil izoh (ixtiyoriy)',
                      hint: 'Bajarilgan ishlar va erishilgan natija',
                      maxLines: 3,
                    ),
                    _buildInput(
                      controller: _actionsTakenCtrl,
                      label: 'Ko‘rilgan choralar (ixtiyoriy)',
                      hint: 'Muammoni hal qilish uchun qilingan harakatlar',
                      maxLines: 2,
                    ),
                    _buildInput(
                      controller: _nextStepsCtrl,
                      label: 'Keyingi qadam (ixtiyoriy)',
                      hint: 'Keyingi bosqichda nima kutilmoqda?',
                      maxLines: 2,
                    ),
                    _buildInput(
                      controller: _lawyerCommentCtrl,
                      label: 'Advokat izohi va tavsiyasi (ixtiyoriy)',
                      hint: 'Mijoz uchun muhim eslatma yoki ko‘rsatma',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sanalar (ixtiyoriy)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF102B50),
                      ),
                    ),
                    const SizedBox(height: 7),
                    _buildDateChip(
                      label: 'Asosiy sana va vaqt',
                      value: _eventDate,
                      onChanged: (v) => setState(() => _eventDate = v),
                    ),
                    _buildDateChip(
                      label: 'Boshlangan sana',
                      value: _startedAt,
                      onChanged: (v) => setState(() => _startedAt = v),
                    ),
                    _buildDateChip(
                      label: 'Topshirilgan sana',
                      value: _submittedAt,
                      onChanged: (v) => setState(() => _submittedAt = v),
                    ),
                    _buildDateChip(
                      label: 'Qaror / javob sanasi',
                      value: _decisionAt,
                      onChanged: (v) => setState(() => _decisionAt = v),
                    ),
                    _buildDateChip(
                      label: 'Yakunlangan sana',
                      value: _completedAt,
                      onChanged: (v) => setState(() => _completedAt = v),
                    ),
                    _buildDateChip(
                      label: 'Keyingi amal sanasi',
                      value: _nextActionAt,
                      onChanged: (v) => setState(() => _nextActionAt = v),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Ilova hujjatlar (ixtiyoriy)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF102B50),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _uploadingDoc ? null : _pickAndUploadDocument,
                          icon: _uploadingDoc
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_file_rounded, size: 17),
                          label: const Text(
                            'Hujjat yuklash',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_attachments.isNotEmpty)
                      ..._attachments.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final doc = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDCE6F2)),
                          ),
                          child: Row(
                            children: <Widget>[
                              Text(
                                doc.fileType,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1677D2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  doc.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF102B50),
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    setState(() => _attachments.removeAt(idx)),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1677D2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  widget.existing == null
                      ? 'Bosqichni saqlash'
                      : 'O‘zgarishlarni saqlash',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
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