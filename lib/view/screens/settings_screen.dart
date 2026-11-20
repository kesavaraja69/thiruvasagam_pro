import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thiruvasagampro/services/reward_unlock_service.dart';
import 'package:thiruvasagampro/utils/ad_consent_manager.dart';
import 'package:thiruvasagampro/utils/ad_helper.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/app_open_ad_manager.dart';
import 'package:thiruvasagampro/view/widgets/reward_ad_prompt.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';
import 'package:thiruvasagampro/view/screens/about_screen.dart';
import 'package:thiruvasagampro/view/widgets/antique_header.dart';
import 'package:thiruvasagampro/view/widgets/custom_banner_ad.dart';
import 'package:thiruvasagampro/viewmodels/reading_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Opens the clock picker and saves the chosen reminder time.
  Future<void> _pickReminderTime(
    BuildContext context,
    ReadingProvider provider,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: provider.reminderTime,
      helpText: 'நினைவூட்டல் நேரம் (Reminder time)',
    );
    if (picked != null) {
      await provider.setReminderTime(picked);
    }
  }

  Future<void> _launchURL(String urlString) async {
    AppOpenAdManager.skipNextResume();
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'kesavarajamurugesan@gmail.com',
      query: 'subject=Thiruvasagam App Feedback',
    );
    AppOpenAdManager.skipNextResume();
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch email');
    }
  }

  Future<void> _openAdPrivacySettings(BuildContext context) async {
    final result = await AdConsentManager.showPrivacyOptionsForm();
    if (!context.mounted) return;

    final message = switch (result) {
      PrivacyOptionsResult.shown => null,
      PrivacyOptionsResult.notRequired =>
        'உங்கள் பகுதியில் கூடுதல் விளம்பர தனியுரிமை அமைப்புகள் தேவைப்படவில்லை.',
      PrivacyOptionsResult.failed =>
        'விளம்பர தனியுரிமை அமைப்புகளைத் திறக்க முடியவில்லை. சிறிது நேரம் கழித்து முயற்சிக்கவும்.',
    };

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          AntiqueHeader(title: 'அமைப்புகள் (Settings)'),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.contentMaxWidth(context),
                ),
                child: ListView(
                  padding: EdgeInsets.only(
                    bottom: isPhone ? Responsive.padding(context, 100) : 120,
                  ),
                  children: [
                    // Second banner unit, visible directly under the header
                    // and separated from the first tappable setting row.
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Responsive.contentPadding(
                          context,
                          Responsive.padding(context, 12),
                          tabletValue: 16,
                        ),
                        Responsive.padding(context, 4),
                        Responsive.contentPadding(
                          context,
                          Responsive.padding(context, 12),
                          tabletValue: 16,
                        ),
                        isPhone ? Responsive.padding(context, 16) : 8,
                      ),
                      child: CustomBannerAd(
                        adUnitId: AdHelper.inlineBannerAdUnitId,
                      ),
                    ),

                    // ===== READ MODE SECTION =====
                    _buildSectionHeader(context, '📖 படிப்பு முறை (Read Mode)'),

                    // Eye Protection Toggle
                    Consumer<ReadingProvider>(
                      builder: (context, provider, child) {
                        return _buildSwitchItem(
                          context: context,
                          icon: Icons.remove_red_eye_outlined,
                          title: 'கண் பாதுகாப்பு (Eye Protection)',
                          subtitle: provider.eyeProtectionEnabled
                              ? 'ON · மீதம் ${_formatRemaining(RewardUnlockService.instance.eyeProtectionRemaining)}'
                              : 'OFF · விளம்பரம் பார்த்து 5 நாட்களுக்கு திறக்க',
                          value: provider.eyeProtectionEnabled,
                          onChanged: (value) => _handleEyeProtectionToggle(
                            context,
                            provider,
                            value,
                          ),
                        );
                      },
                    ),
                    _buildDivider(context),

                    // Warmth & Dimness sliders (only when eye protection is enabled)
                    Consumer<ReadingProvider>(
                      builder: (context, provider, child) {
                        if (!provider.eyeProtectionEnabled) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            // Warmth slider
                            _buildSliderItem(
                              context: context,
                              icon: Icons.wb_sunny_outlined,
                              title: 'வெப்பம் (Warmth)',
                              value: provider.eyeWarmth,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) => provider.setEyeWarmth(val),
                            ),
                            _buildDivider(context),

                            // Dimness slider
                            _buildSliderItem(
                              context: context,
                              icon: Icons.brightness_low_outlined,
                              title: 'மங்கல் (Dimness)',
                              value: provider.eyeDimness,
                              min: 0.0,
                              max: 0.6,
                              onChanged: (val) => provider.setEyeDimness(val),
                            ),
                            _buildDivider(context),
                          ],
                        );
                      },
                    ),

                    // ===== AUDIO SECTION =====
                    _buildSectionHeader(context, '🔊 இசை (Audio)'),

                    // Continuous Play Toggle (auto-advance to the next song)
                    Consumer<ReadingProvider>(
                      builder: (context, provider, child) {
                        return _buildSwitchItem(
                          context: context,
                          icon: Icons.play_circle_outline,
                          title: 'தொடர் இசை (Continuous Play)',
                          subtitle: provider.continuousPlayEnabled
                              ? 'ON · பாடல் முடிந்ததும் அடுத்தது தானாக இயங்கும்'
                              : 'OFF',
                          value: provider.continuousPlayEnabled,
                          onChanged: (_) => provider.toggleContinuousPlay(),
                        );
                      },
                    ),
                    _buildDivider(context),

                    // ===== REMINDER SECTION =====
                    _buildSectionHeader(context, '🔔 நினைவூட்டல் (Reminder)'),

                    Consumer<ReadingProvider>(
                      builder: (context, provider, child) {
                        return Column(
                          children: [
                            _buildSwitchItem(
                              context: context,
                              icon: Icons.notifications_active_outlined,
                              title: 'தினசரி நினைவூட்டல் (Daily Reminder)',
                              subtitle: provider.reminderEnabled
                                  ? 'ON · ${provider.reminderTime.format(context)}'
                                  : 'OFF',
                              value: provider.reminderEnabled,
                              onChanged: (value) =>
                                  provider.toggleReminder(value),
                            ),
                            if (provider.reminderEnabled) ...[
                              _buildDivider(context),
                              _buildSettingsItem(
                                context: context,
                                icon: Icons.access_time,
                                title:
                                    'நேரம் (Time): ${provider.reminderTime.format(context)}',
                                onTap: () =>
                                    _pickReminderTime(context, provider),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    _buildDivider(context),

                    // ===== REWARDS SECTION =====
                    _buildSectionHeader(context, '🎁 வெகுமதிகள் (Rewards)'),
                    _buildRewardsSection(context),
                    _buildDivider(context),

                    // ===== GENERAL SECTION =====
                    _buildSectionHeader(context, '📋 பொது (General)'),

                    _buildSettingsItem(
                      context: context,
                      icon: Icons.info_outline,
                      title: 'எங்களை பற்றி (About)',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      ),
                    ),
                    _buildDivider(context),

                    _buildSettingsItem(
                      context: context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'தனியுரிமைக் கொள்கை (Privacy Policy)',
                      onTap: () => _launchURL(
                        'https://doc-hosting.flycricket.io/thiruvasagam-pro-privacy-policies/d92f049d-6945-49af-8daf-1b06db75bfdf/privacy',
                      ),
                    ),
                    _buildDivider(context),

                    _buildSettingsItem(
                      context: context,
                      icon: Icons.tune,
                      title: 'விளம்பர தனியுரிமை (Ad privacy settings)',
                      onTap: () => _openAdPrivacySettings(context),
                    ),
                    _buildDivider(context),

                    _buildSettingsItem(
                      context: context,
                      icon: Icons.description_outlined,
                      title: 'விதிமுறைகள் (Terms & Conditions)',
                      onTap: () => _launchURL(
                        'https://doc-hosting.flycricket.io/thiruvasagam-pro-terms-and-conditions/04b14714-6a57-4070-a967-1c0870400a96/terms',
                      ),
                    ),
                    _buildDivider(context),

                    _buildSettingsItem(
                      context: context,
                      icon: Icons.mail_outline,
                      title: 'தொடர்புக்கு (Contact Us)',
                      onTap: _launchEmail,
                    ),
                    _buildDivider(context),

                    SizedBox(height: Responsive.height(context, 15)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.padding(context, 16),
        Responsive.padding(context, 16),
        Responsive.padding(context, 16),
        Responsive.padding(context, 4),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, 14),
          fontWeight: FontWeight.bold,
          color: AppColors.vintageInk.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRewardsSection(BuildContext context) {
    // Never advertise a reward that cannot be earned: when no live rewarded
    // unit is configured, this section stays hidden rather than sending the
    // user into a broken ad flow.
    if (!AdHelper.rewardedAdsAvailable) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.padding(context, 20),
          vertical: Responsive.padding(context, 12),
        ),
        child: Text(
          'வெகுமதிகள் இப்போது கிடைக்கவில்லை.',
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 13),
            color: Colors.black45,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: RewardUnlockService.instance,
      builder: (context, _) {
        final rewards = RewardUnlockService.instance;
        return Column(
          children: [
            _buildSettingsItem(
              context: context,
              icon: Icons.block,
              title: 'விளம்பரமில்லா பயன்பாடு (Ad-free)',
              subtitle: rewards.isAdFree
                  ? 'மீதம் ${_formatRemaining(rewards.adFreeRemaining)}'
                  : '1 மணி நேரம் · விளம்பரம் பார்த்து திறக்க',
              trailingIcon: Icons.play_circle_outline,
              onTap: () => _earnReward(
                context,
                title: 'விளம்பரமில்லா பயன்பாடு',
                description:
                    '1 மணி நேரத்திற்கு அனைத்து விளம்பரங்களையும் நீக்க ஒரு குறுகிய விளம்பரத்தைப் பாருங்கள்.',
                onEarned: rewards.grantAdFree,
                successMessage: '1 மணி நேரத்திற்கு விளம்பரங்கள் நீக்கப்பட்டன.',
              ),
            ),
            _buildDivider(context),
            _buildSettingsItem(
              context: context,
              icon: Icons.remove_red_eye_outlined,
              title: 'கண் பாதுகாப்பு (Eye Protection)',
              subtitle: rewards.eyeProtectionEnabled
                  ? 'மீதம் ${_formatRemaining(rewards.eyeProtectionRemaining)}'
                  : '5 நாட்கள் · விளம்பரம் பார்த்து திறக்க',
              trailingIcon: Icons.play_circle_outline,
              onTap: () => _earnReward(
                context,
                title: 'கண் பாதுகாப்பு',
                description:
                    '5 நாட்களுக்கு கண் பாதுகாப்பைப் பயன்படுத்த ஒரு குறுகிய விளம்பரத்தைப் பாருங்கள்.',
                onEarned: () async {
                  await rewards.grantEyeProtection();
                  if (context.mounted) {
                    await context
                        .read<ReadingProvider>()
                        .setEyeProtectionEnabled(true);
                  }
                },
                successMessage: '5 நாட்களுக்கு கண் பாதுகாப்பு திறக்கப்பட்டது.',
              ),
            ),
            _buildDivider(context),
            _buildSettingsItem(
              context: context,
              icon: Icons.headphones,
              title: 'பின்னணி இசை (Background audio)',
              subtitle: rewards.backgroundAudioUnlocked
                  ? 'மீதம் ${_formatRemaining(rewards.backgroundAudioRemaining)}'
                  : '4 மணி நேரம் · விளம்பரம் பார்த்து திறக்க',
              trailingIcon: Icons.play_circle_outline,
              onTap: () => _earnReward(
                context,
                title: 'பின்னணி இசை',
                description:
                    '4 மணி நேரத்திற்கு ஆப்பை விட்டு வெளியேறியும் இசையைக் கேட்க ஒரு குறுகிய விளம்பரத்தைப் பாருங்கள்.',
                onEarned: rewards.grantBackgroundAudio,
                successMessage: '4 மணி நேரத்திற்கு பின்னணி இசை திறக்கப்பட்டது.',
              ),
            ),
            _buildDivider(context),
            _buildSettingsItem(
              context: context,
              icon: Icons.font_download_outlined,
              title: 'பிரீமியம் எழுத்துருக்கள் (Premium fonts)',
              subtitle: rewards.fontsUnlocked
                  ? 'மீதம் ${_formatRemaining(rewards.fontsRemaining)}'
                  : '24 மணி நேரம் · விளம்பரம் பார்த்து திறக்க',
              trailingIcon: Icons.play_circle_outline,
              onTap: () => _earnReward(
                context,
                title: 'பிரீமியம் எழுத்துருக்கள்',
                description:
                    '24 மணி நேரத்திற்கு அனைத்து பிரீமியம் எழுத்துருக்களையும் திறக்க ஒரு குறுகிய விளம்பரத்தைப் பாருங்கள்.',
                onEarned: rewards.grantFonts,
                successMessage:
                    '24 மணி நேரத்திற்கு பிரீமியம் எழுத்துருக்கள் திறக்கப்பட்டன.',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleEyeProtectionToggle(
    BuildContext context,
    ReadingProvider provider,
    bool value,
  ) async {
    if (!value) {
      await provider.setEyeProtectionEnabled(false);
      return;
    }

    // Already unlocked — just switch the overlay on.
    if (RewardUnlockService.instance.eyeProtectionEnabled) {
      await provider.setEyeProtectionEnabled(true);
      return;
    }

    final earned = await showRewardedAdPrompt(
      context,
      title: 'கண் பாதுகாப்பு',
      description:
          '5 நாட்களுக்கு கண் பாதுகாப்பைப் பயன்படுத்த ஒரு குறுகிய விளம்பரத்தைப் பாருங்கள்.',
    );
    if (!earned || !context.mounted) return;

    await RewardUnlockService.instance.grantEyeProtection();
    await provider.setEyeProtectionEnabled(true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('5 நாட்களுக்கு கண் பாதுகாப்பு திறக்கப்பட்டது.'),
      ),
    );
  }

  Future<void> _earnReward(
    BuildContext context, {
    required String title,
    required String description,
    required Future<void> Function() onEarned,
    required String successMessage,
  }) async {
    final earned = await showRewardedAdPrompt(
      context,
      title: title,
      description: description,
    );
    if (!earned) return;

    await onEarned();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  }

  String _formatRemaining(Duration? remaining) {
    if (remaining == null) return '0 நிமிடம்';
    if (remaining.inDays >= 1) {
      final days = remaining.inDays;
      final hours = remaining.inHours % 24;
      return hours == 0 ? '$days நாள்' : '$days நாள் $hours மணி';
    }
    if (remaining.inHours >= 1) {
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      return minutes == 0 ? '$hours மணி' : '$hours மணி $minutes நிமிடம்';
    }
    return '${remaining.inMinutes + 1} நிமிடம்';
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    IconData? trailingIcon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 8)),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.vintageInk,
          size: Responsive.iconSize(context, 26),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 12),
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
        trailing: Icon(
          trailingIcon ?? Icons.arrow_forward_ios,
          color: trailingIcon == null ? Colors.black45 : AppColors.vintageInk,
          size: Responsive.iconSize(context, trailingIcon == null ? 16 : 24),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 8)),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.vintageInk,
          size: Responsive.iconSize(context, 26),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 12),
            color: value ? Colors.green.shade700 : Colors.black38,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.vintageInk,
        ),
      ),
    );
  }

  Widget _buildSliderItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context, 16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.vintageInk,
                size: Responsive.iconSize(context, 22),
              ),
              SizedBox(width: Responsive.padding(context, 12)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 14),
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 12),
                  fontWeight: FontWeight.bold,
                  color: AppColors.vintageInk,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.vintageInk,
              inactiveTrackColor: AppColors.vintageInk.withValues(alpha: 0.2),
              thumbColor: AppColors.vintageInk,
              overlayColor: AppColors.vintageInk.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.padding(context, 4),
        horizontal: Responsive.padding(context, 25),
      ),
      child: Image.asset(
        AppAssets.templeDivider,
        height: Responsive.dim(context, 13),
        fit: BoxFit.contain,
      ),
    );
  }
}
