import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:thiruvasagampro/services/tts_service.dart';
import 'package:thiruvasagampro/utils/ad_helper.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/app_open_ad_manager.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';

/// A production-quality TTS player widget for text-to-speech playback.
/// Features: Play/Pause, Stop, Voice selection, Speed/Pitch/Volume controls.
class TTSPlayerWidget extends StatefulWidget {
  final String textToSpeak;
  final String? title;

  const TTSPlayerWidget({super.key, required this.textToSpeak, this.title});

  @override
  State<TTSPlayerWidget> createState() => _TTSPlayerWidgetState();
}

class _TTSPlayerWidgetState extends State<TTSPlayerWidget>
    with SingleTickerProviderStateMixin {
  final TTSService _ttsService = TTSService();

  // State flags
  bool _hasAcquired = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isLoading = false;
  bool _isExpanded = false;
  bool _isVoicesLoading = true;
  bool _hasInitError = false;

  // Ad
  InterstitialAd? _interstitialAd;
  int _stopCount = 0;

  // Animation
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _initializeTTS();
    _loadInterstitialAd();
  }

  @override
  void didUpdateWidget(covariant TTSPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textToSpeak != widget.textToSpeak && mounted) {
      _handleTextChanged();
    }
  }

  Future<void> _handleTextChanged() async {
    final wasPlaying = _isPlaying;
    await _ttsService.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _isPaused = false;
    });
    if (wasPlaying &&
        widget.textToSpeak.isNotEmpty &&
        !_isLoading &&
        !_hasInitError) {
      try {
        await _ttsService.speak(widget.textToSpeak);
        if (!mounted) return;
        setState(() {
          _isPlaying = true;
          _isPaused = false;
        });
      } catch (e) {
        debugPrint('TTS auto-play failed: $e');
      }
    }
  }

  Future<void> _initializeTTS() async {
    if (!_hasAcquired) {
      _hasAcquired = true;
      _ttsService.acquire();
    }
    setState(() {
      _isLoading = true;
      _isVoicesLoading = true;
      _hasInitError = false;
    });

    _ttsService.onVoicesLoaded = () {
      if (mounted) setState(() => _isVoicesLoading = false);
    };

    _ttsService.onInitError = (error) {
      if (mounted) {
        setState(() {
          _hasInitError = true;
          _isLoading = false;
          _isVoicesLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS initialization failed: $error'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    };

    await _ttsService.initialize();

    _ttsService.onSpeechComplete = () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
        });
      }
    };

    _ttsService.onSpeechError = (error) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS error: $error'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    };

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _expandController.dispose();
    _ttsService.stop();
    _ttsService.clearCallbacks();
    if (_hasAcquired) {
      _hasAcquired = false;
      _ttsService.release();
    }
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _expandController.forward() : _expandController.reverse();
    });
  }

  Future<void> _togglePlayPause() async {
    if (_isLoading || _hasInitError) return;
    setState(() => _isLoading = true);

    try {
      if (_isPlaying && !_isPaused) {
        await _ttsService.pause();
        setState(() {
          _isPaused = true;
          _isLoading = false;
        });
      } else if (_isPaused) {
        await _ttsService.resume();
        setState(() {
          _isPaused = false;
          _isLoading = false;
        });
      } else {
        await _ttsService.speak(widget.textToSpeak);
        setState(() {
          _isPlaying = true;
          _isPaused = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _stop() async {
    await _ttsService.stop();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
    });

    _stopCount++;
    if (_stopCount % 2 == 0 && _interstitialAd != null && mounted) {
      _interstitialAd!.show();
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              AppOpenAdManager.pauseAppOpenAd = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              Future.delayed(const Duration(seconds: 1), () {
                AppOpenAdManager.pauseAppOpenAd = false;
              });
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              Future.delayed(const Duration(seconds: 1), () {
                AppOpenAdManager.pauseAppOpenAd = false;
              });
              ad.dispose();
              _loadInterstitialAd();
            },
          );
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) =>
            debugPrint('TTS interstitial failed: ${err.message}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasInitError) return _buildErrorWidget();

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.palmLeafGreen,
                AppColors.palmLeafGreen.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(Responsive.radius(context, 7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.palmLeafGreen.withValues(alpha: 0.3),
                blurRadius: Responsive.dim(context, 8),
                offset: Offset(0, Responsive.dim(context, 3)),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main controls row
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.padding(context, 16),
                  vertical: Responsive.padding(context, 8),
                ),
                child: Row(
                  children: [
                    // Play/Pause button
                    _buildPlayPauseButton(),
                    SizedBox(width: Responsive.padding(context, 12)),

                    // Title and status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null && widget.title!.isNotEmpty)
                            Text(
                              widget.title!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.fontSize(context, 13),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          SizedBox(height: Responsive.height(context, 2)),
                          Row(
                            children: [
                              Icon(
                                _isPlaying
                                    ? Icons.record_voice_over
                                    : Icons.mic,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: Responsive.iconSize(context, 10),
                              ),
                              SizedBox(width: Responsive.padding(context, 4)),
                              Text(
                                _isPaused
                                    ? 'Paused'
                                    : _isPlaying
                                    ? 'Reading...'
                                    : 'Text-to-Speech',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: Responsive.fontSize(context, 10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Stop button
                    if (_isPlaying || _isPaused) ...[
                      SizedBox(width: Responsive.padding(context, 8)),
                      _buildControlButton(
                        icon: Icons.stop_rounded,
                        color: Colors.red.shade600,
                        onTap: _stop,
                        size: Responsive.dim(context, 28),
                      ),
                    ],

                    SizedBox(width: Responsive.padding(context, 8)),

                    // Settings toggle
                    _buildSettingsButton(),
                  ],
                ),
              ),

              // Expanded settings panel
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildExpandedPanel(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context, 16),
        vertical: Responsive.padding(context, 12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: Responsive.iconSize(context, 20),
          ),
          SizedBox(width: Responsive.padding(context, 10)),
          Expanded(
            child: Text(
              'TTS unavailable',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: Responsive.fontSize(context, 13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _hasInitError = false);
              _initializeTTS();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.padding(context, 12),
                vertical: Responsive.padding(context, 6),
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(
                  Responsive.radius(context, 12),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.fontSize(context, 12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        width: Responsive.dim(context, 32),
        height: Responsive.dim(context, 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: _isLoading
            ? Padding(
                padding: EdgeInsets.all(Responsive.padding(context, 11)),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                _isPlaying && !_isPaused
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: Responsive.iconSize(context, 24),
              ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 36,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        width: Responsive.dim(context, 30),
        height: Responsive.dim(context, 30),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isExpanded ? Icons.keyboard_arrow_up : Icons.tune,
          color: Colors.white,
          size: Responsive.iconSize(context, 16),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.padding(context, 16),
        0,
        Responsive.padding(context, 16),
        Responsive.padding(context, 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSliderRow(
            icon: Icons.speed,
            label: 'Speed',
            value: _ttsService.speechRate,
            min: 0.0,
            max: 1.0,
            onChanged: (val) async {
              await _ttsService.setSpeechRate(val);
              setState(() {});
            },
          ),
          SizedBox(height: Responsive.height(context, 8)),
          _buildSliderRow(
            icon: Icons.graphic_eq,
            label: 'Pitch',
            value: _ttsService.pitch,
            min: 0.5,
            max: 2.0,
            onChanged: (val) async {
              await _ttsService.setPitch(val);
              setState(() {});
            },
          ),
          SizedBox(height: Responsive.height(context, 8)),
          _buildSliderRow(
            icon: Icons.volume_up,
            label: 'Volume',
            value: _ttsService.volume,
            min: 0.0,
            max: 1.0,
            onChanged: (val) async {
              await _ttsService.setVolume(val);
              setState(() {});
            },
          ),
          SizedBox(height: Responsive.height(context, 8)),
          if (_isVoicesLoading)
            _buildVoiceSkeleton()
          else if (_ttsService.availableVoices.isNotEmpty)
            _buildVoiceSelector()
          else
            _buildNoVoicesMessage(),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: Responsive.iconSize(context, 14),
        ),
        SizedBox(width: Responsive.padding(context, 6)),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: Responsive.fontSize(context, 10),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.fontSize(context, 10),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSkeleton() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context, 8),
        vertical: Responsive.padding(context, 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Responsive.radius(context, 10)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.record_voice_over,
            color: Colors.white70,
            size: Responsive.iconSize(context, 14),
          ),
          SizedBox(width: Responsive.padding(context, 6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loading voices...',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: Responsive.fontSize(context, 10),
                  ),
                ),
                SizedBox(height: Responsive.height(context, 6)),
                Container(
                  height: Responsive.dim(context, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      Responsive.radius(context, 4),
                    ),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSelector() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context, 8),
        vertical: Responsive.padding(context, 4),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Responsive.radius(context, 10)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.record_voice_over,
            color: Colors.white70,
            size: Responsive.iconSize(context, 14),
          ),
          SizedBox(width: Responsive.padding(context, 6)),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                isExpanded: true,
                value: _ttsService.currentVoice.isNotEmpty
                    ? _ttsService.currentVoice
                    : null,
                dropdownColor: AppColors.palmLeafGreen,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.fontSize(context, 10),
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white70,
                  size: Responsive.iconSize(context, 16),
                ),
                items: _ttsService.availableVoices.map((voice) {
                  return DropdownMenuItem<String>(
                    value: voice['name'],
                    child: Text(
                      '${voice['name']} (${voice['locale']})',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 10),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    final voice = _ttsService.availableVoices.firstWhere(
                      (v) => v['name'] == value,
                    );
                    _ttsService.setVoice(voice);
                    setState(() {});
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVoicesMessage() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context, 8),
        vertical: Responsive.padding(context, 6),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Responsive.radius(context, 10)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white54,
            size: Responsive.iconSize(context, 12),
          ),
          SizedBox(width: Responsive.padding(context, 6)),
          Expanded(
            child: Text(
              'Using default system voice',
              style: TextStyle(
                color: Colors.white54,
                fontSize: Responsive.fontSize(context, 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
