import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thiruvasagampro/services/audio_cache_service.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/view/screens/about_screen.dart';
import 'package:thiruvasagampro/view/widgets/antique_header.dart';
import 'package:thiruvasagampro/view/widgets/custom_banner_ad.dart';
import 'package:thiruvasagampro/viewmodels/reading_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchURL(String urlString) async {
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
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          AntiqueHeader(title: 'அமைப்புகள் (Settings)'),

          // ===== READ MODE SECTION =====
          _buildSectionHeader('📖 படிப்பு முறை (Read Mode)'),

          // Eye Protection Toggle
          Consumer<ReadingProvider>(
            builder: (context, provider, child) {
              return _buildSwitchItem(
                icon: Icons.remove_red_eye_outlined,
                title: 'கண் பாதுகாப்பு (Eye Protection)',
                subtitle: provider.eyeProtectionEnabled ? 'ON' : 'OFF',
                value: provider.eyeProtectionEnabled,
                onChanged: (_) => provider.toggleEyeProtection(),
              );
            },
          ),
          _buildDivider(),

          // Warmth & Dimness sliders (only when eye protection is enabled)
          Consumer<ReadingProvider>(
            builder: (context, provider, child) {
              if (!provider.eyeProtectionEnabled) return const SizedBox.shrink();
              return Column(
                children: [
                  // Warmth slider
                  _buildSliderItem(
                    icon: Icons.wb_sunny_outlined,
                    title: 'வெப்பம் (Warmth)',
                    value: provider.eyeWarmth,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) => provider.setEyeWarmth(val),
                  ),
                  _buildDivider(),

                  // Dimness slider
                  _buildSliderItem(
                    icon: Icons.brightness_low_outlined,
                    title: 'மங்கல் (Dimness)',
                    value: provider.eyeDimness,
                    min: 0.0,
                    max: 0.6,
                    onChanged: (val) => provider.setEyeDimness(val),
                  ),
                  _buildDivider(),
                ],
              );
            },
          ),

          // ===== GENERAL SECTION =====
          _buildSectionHeader('📋 பொது (General)'),

          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'எங்களை பற்றி (About)',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
          ),
          _buildDivider(),

          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'தனியுரிமைக் கொள்கை (Privacy Policy)',
            onTap: () => _launchURL(
              'https://doc-hosting.flycricket.io/thiruvasagam-pro-privacy-policies/d92f049d-6945-49af-8daf-1b06db75bfdf/privacy',
            ),
          ),
          _buildDivider(),

          _buildSettingsItem(
            icon: Icons.description_outlined,
            title: 'விதிமுறைகள் (Terms & Conditions)',
            onTap: () => _launchURL(
              'https://doc-hosting.flycricket.io/thiruvasagam-pro-terms-and-conditions/04b14714-6a57-4070-a967-1c0870400a96/terms',
            ),
          ),
          _buildDivider(),

          _buildSettingsItem(
            icon: Icons.mail_outline,
            title: 'தொடர்புக்கு (Contact Us)',
            onTap: _launchEmail,
          ),
          _buildDivider(),

          // ===== AUDIO CACHE SECTION =====
          _buildSectionHeader('🎵 ஆடியோ கேச் (Audio Cache)'),

          _buildSettingsItem(
            icon: Icons.cleaning_services_outlined,
            title: 'கேசை அழி (Clear Audio Cache)',
            onTap: () => _showClearCacheDialog(context),
          ),
          _buildDivider(),

          const SizedBox(height: 30),
          const CustomBannerAd(),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.vintageInk.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListTile(
        leading: Icon(icon, color: AppColors.vintageInk, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.black45,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListTile(
        leading: Icon(icon, color: AppColors.vintageInk, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
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
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.vintageInk, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 25.0),
      child: Image.asset(
        AppAssets.templeDivider,
        height: 15,
        fit: BoxFit.contain,
      ),
    );
  }

  Future<void> _showClearCacheDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Audio Cache?'),
        content: const Text(
          'This will remove all cached audio files. You will need to download them again when offline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AudioCacheService.instance.clearCache();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio cache cleared successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
