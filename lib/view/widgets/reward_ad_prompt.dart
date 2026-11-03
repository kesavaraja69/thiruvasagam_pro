import 'package:flutter/material.dart';

import '../../services/rewarded_ad_service.dart';

/// Shows an explicit opt-in prompt before a rewarded ad.
///
/// The confirmation and reward text are required so the user always knows what
/// they are trading their time for, and the reward is granted only when the
/// SDK reports that it was earned.
Future<bool> showRewardedAdPrompt(
  BuildContext context, {
  required String title,
  required String description,
  String confirmLabel = 'விளம்பரம் பார்',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('வேண்டாம்'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return false;

  var loadingVisible = true;
  showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (context) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 18),
            Expanded(child: Text('விளம்பரம் தயாராகிறது...')),
          ],
        ),
      ),
    ),
  ).whenComplete(() => loadingVisible = false);

  final earned = await RewardedAdService.instance.showOrLoad();

  if (context.mounted && loadingVisible) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  if (!earned && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'விளம்பரம் இப்போது கிடைக்கவில்லை. சிறிது நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.',
        ),
      ),
    );
  }

  return earned;
}
