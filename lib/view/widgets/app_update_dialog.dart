import 'package:flutter/material.dart';

import '../../models/app_update_config.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_theme.dart';

/// What the user chose in the update dialog.
enum UpdateDialogAction { update, later }

// ─── Palette local to this dialog ─────────────────────────────────────
// A calmer, lighter cream than AppColors.parchmentBase. A dialog should sit
// *above* the page, so it needs less saturation and texture than the page
// behind it — otherwise the text competes with the background.
const Color _surface = Color(0xFFFAF3E0);
const Color _panel = Color(0xFFFFFDF6);
const Color _ink = Color(0xFF3A2415);
const Color _goldAccent = Color(0xFFB8912A);

/// Dialog-local metrics, derived from the dialog's own width.
///
/// The shared `Responsive` helpers key typography off screen *width* while
/// keying vertical spacing off screen *height*. On a phone in landscape that
/// inflates text to 1.6x while collapsing spacing to 0.5x, which is why the
/// footer used to swallow the whole dialog. A dialog is a container, so its
/// type scale should follow the container — and stay clamped.
class _Metrics {
  const _Metrics(this.factor);

  factory _Metrics.forWidth(double width) =>
      _Metrics((width / 360).clamp(0.85, 1.15));

  final double factor;

  /// Spacing / padding.
  double sp(double value) => value * factor;

  /// Font size.
  double fs(double value) => value * factor;

  /// Corner radius.
  double r(double value) => value * factor;
}

/// Shows the themed "a new version is available" dialog.
///
/// Returns [UpdateDialogAction.later] when the user dismisses it (tapping
/// outside or pressing back) so callers can snooze without extra branching.
///
/// When `info.forceUpdate` is true the dialog cannot be dismissed at all — the
/// barrier tap and the back gesture are both disabled.
Future<UpdateDialogAction> showAppUpdateDialog(
  BuildContext context, {
  required PendingUpdate info,
}) async {
  final action = await showDialog<UpdateDialogAction>(
    context: context,
    barrierDismissible: !info.forceUpdate,
    builder: (dialogContext) => PopScope(
      // A forced update may only be left through the Play flow.
      canPop: !info.forceUpdate,
      child: _AppUpdateDialog(info: info),
    ),
  );
  return action ?? UpdateDialogAction.later;
}

class _AppUpdateDialog extends StatelessWidget {
  const _AppUpdateDialog({required this.info});

  final PendingUpdate info;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isPhone = Responsive.isPhone(context);

    // Phones get ~90% of the width; wider displays get a comfortable column.
    final maxWidth = isPhone
        ? screen.width * 0.90
        : (Responsive.isLargeTablet(context) ? 520.0 : 440.0);

    // Short screens (phone landscape) must scroll rather than clip.
    final maxHeight = screen.height * 0.85;

    // Phone portrait stacks the buttons full-width for bigger tap targets;
    // landscape and tablets have room to sit side by side.
    final stackButtons = isPhone && !Responsive.isLandscape(context);

    return Dialog(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final m = _Metrics.forWidth(constraints.maxWidth);
            // A viewport wider than it is tall (a landscape phone) has no
            // vertical budget but plenty of horizontal room, so the emblem
            // moves beside the copy instead of above it.
            final isWide = constraints.maxWidth > constraints.maxHeight;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(m.r(20)),
                border: Border.all(
                  color: AppColors.templeGold.withValues(alpha: 0.75),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage(AppAssets.parchmentBg),
                  fit: BoxFit.cover,
                  opacity: 0.16,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(m.r(20)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Only the body scrolls. The actions stay pinned to the
                    // bottom so the update button is never pushed off-screen on
                    // a short or landscape display.
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          m.sp(22),
                          m.sp(22),
                          m.sp(22),
                          m.sp(18),
                        ),
                        child: isWide ? _buildWideBody(m) : _buildTallBody(m),
                      ),
                    ),
                    _buildHairline(opacity: 0.10),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        m.sp(22),
                        m.sp(14),
                        m.sp(22),
                        m.sp(16),
                      ),
                      child: _buildActions(
                        context,
                        m,
                        stackButtons: stackButtons,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Body layouts ───────────────────────────────────────────────────

  /// Tall viewport (portrait): emblem on top, everything centred beneath it.
  Widget _buildTallBody(_Metrics m) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEmblem(m),
        SizedBox(height: m.sp(12)),
        _buildTitle(m, TextAlign.center),
        SizedBox(height: m.sp(16)),
        _buildVersionTransition(m, MainAxisAlignment.center),
        if (info.message != null) ...[
          SizedBox(height: m.sp(16)),
          _buildMessage(m, info.message!, TextAlign.center),
        ],
        if (info.releaseNotes.isNotEmpty) ...[
          SizedBox(height: m.sp(18)),
          _buildReleaseNotes(m),
        ],
      ],
    );
  }

  /// Short viewport (landscape phone): the emblem moves beside the copy so the
  /// headline and version delta are never pushed below the fold, and the copy
  /// is left-aligned because a centred column beside an image reads as ragged.
  Widget _buildWideBody(_Metrics m) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEmblem(m, maxSize: 100),
        SizedBox(width: m.sp(18)),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(m, TextAlign.left),
              SizedBox(height: m.sp(12)),
              _buildVersionTransition(m, MainAxisAlignment.start),
              if (info.message != null) ...[
                SizedBox(height: m.sp(12)),
                _buildMessage(m, info.message!, TextAlign.left),
              ],
              if (info.releaseNotes.isNotEmpty) ...[
                SizedBox(height: m.sp(14)),
                _buildReleaseNotes(m),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Focal point ────────────────────────────────────────────────────

  /// The app's own Nataraja lockup. Its built-in flourish doubles as the rule
  /// under the headline, which is why no separate divider asset is used.
  Widget _buildEmblem(_Metrics m, {double maxSize = 118}) {
    final size = m.sp(104).clamp(88.0, maxSize);
    return Image.asset(
      AppAssets.logo2,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  Widget _buildTitle(_Metrics m, TextAlign align) {
    return Text(
      info.title ?? 'புதிய பதிப்பு கிடைக்கிறது!',
      textAlign: align,
      style: TextStyle(
        fontFamily: 'Kavivanar',
        fontSize: m.fs(22),
        height: 1.25,
        letterSpacing: 0.2,
        fontWeight: FontWeight.bold,
        color: AppColors.vintageInk,
      ),
    );
  }

  // ─── Version delta ──────────────────────────────────────────────────

  /// `1.8.0 → 1.9.0` reads in one glance, unlike two side-by-side badges.
  Widget _buildVersionTransition(_Metrics m, MainAxisAlignment align) {
    return Row(
      mainAxisAlignment: align,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _versionColumn(
          m,
          label: 'தற்போதைய',
          version: info.currentVersion,
          emphasized: false,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: m.sp(14)),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: m.sp(18),
            color: _goldAccent,
          ),
        ),
        _versionColumn(
          m,
          label: 'புதிய',
          version: info.latestVersion,
          emphasized: true,
        ),
      ],
    );
  }

  Widget _versionColumn(
    _Metrics m, {
    required String label,
    required String version,
    required bool emphasized,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          version,
          style: TextStyle(
            fontSize: m.fs(emphasized ? 17 : 15),
            fontWeight: emphasized ? FontWeight.bold : FontWeight.w600,
            color: emphasized
                ? AppColors.vintageInk
                : AppColors.vintageInk.withValues(alpha: 0.55),
          ),
        ),
        SizedBox(height: m.sp(2)),
        Text(
          label,
          style: TextStyle(
            fontSize: m.fs(11),
            letterSpacing: 0.3,
            color: AppColors.vintageInk.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(_Metrics m, String message, TextAlign align) {
    return Text(
      message,
      textAlign: align,
      style: TextStyle(
        fontSize: m.fs(14),
        height: 1.5,
        color: _ink,
      ),
    );
  }

  // ─── What's new ─────────────────────────────────────────────────────

  Widget _buildReleaseNotes(_Metrics m) {
    final notes = info.releaseNotes;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.sp(14)),
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(m.r(12)),
        border: Border.all(color: _goldAccent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'புதிய அம்சங்கள்',
            style: TextStyle(
              fontSize: m.fs(12),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
              color: AppColors.vintageInk.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: m.sp(10)),
          _buildHairline(opacity: 0.10),
          SizedBox(height: m.sp(10)),
          ...List.generate(notes.length, (index) {
            final isLast = index == notes.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : m.sp(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A crisp dot reads cleaner than a "•" glyph, whose size
                  // varies with the font fallback.
                  Container(
                    width: m.sp(5),
                    height: m.sp(5),
                    margin: EdgeInsets.only(top: m.sp(7)),
                    decoration: const BoxDecoration(
                      color: _goldAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: m.sp(10)),
                  Expanded(
                    child: Text(
                      notes[index],
                      style: TextStyle(
                        fontSize: m.fs(13),
                        height: 1.5,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────

  Widget _buildActions(
    BuildContext context,
    _Metrics m, {
    required bool stackButtons,
  }) {
    final updateButton = _primaryButton(context, m);

    // A forced update offers no way out — the store link is the only action.
    if (info.forceUpdate) {
      return SizedBox(width: double.infinity, child: updateButton);
    }

    final laterButton = _secondaryButton(context, m);

    if (stackButtons) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          updateButton,
          SizedBox(height: m.sp(6)),
          laterButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 2, child: laterButton),
        SizedBox(width: m.sp(12)),
        Expanded(flex: 3, child: updateButton),
      ],
    );
  }

  Widget _primaryButton(BuildContext context, _Metrics m) {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(UpdateDialogAction.update),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.vintageInk,
        foregroundColor: _surface,
        elevation: 0,
        minimumSize: Size.fromHeight(m.sp(50)),
        padding: EdgeInsets.symmetric(horizontal: m.sp(16)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(m.r(14)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.system_update_alt_rounded, size: m.sp(19)),
          SizedBox(width: m.sp(8)),
          Flexible(
            child: Text(
              info.forceUpdate
                  ? 'இப்போது புதுப்பிக்கவும்'
                  : 'புதுப்பிக்கவும் (Update)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: m.fs(15),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Text-only on purpose. The filled primary already establishes the
  /// hierarchy, so a second outlined box would only add noise.
  Widget _secondaryButton(BuildContext context, _Metrics m) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(UpdateDialogAction.later),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.vintageInk.withValues(alpha: 0.78),
        minimumSize: Size.fromHeight(m.sp(46)),
        padding: EdgeInsets.symmetric(horizontal: m.sp(8)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(m.r(14)),
        ),
      ),
      child: Text(
        'பிறகு (Later)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: m.fs(14.5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHairline({double opacity = 0.10}) {
    return Container(
      height: 1,
      color: AppColors.vintageInk.withValues(alpha: opacity),
    );
  }
}
