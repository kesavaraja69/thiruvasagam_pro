import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:thiruvasagampro/services/tts_service.dart';
import 'package:thiruvasagampro/utils/ad_helper.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/app_open_ad_manager.dart';

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
  bool _hasAcquired = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isLoading = false;
  bool _isExpanded = false;
  bool _isVoicesLoading = true;
  bool _hasInitError = false;
  InterstitialAd? _interstitialAd;
  int _stopCount = 0;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _initializeTTS();
    _loadInterstitialAd();
  }

  @override
  void didUpdateWidget(covariant TTSPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the chapter changes (textToSpeak or title changes),
    // stop current speech and auto-play the new chapter.
    if (oldWidget.textToSpeak != widget.textToSpeak && mounted) {
      _handleChapterChanged();
    }
  }

  Future<void> _handleChapterChanged() async {
    final wasPlaying = _isPlaying;
    await _ttsService.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _isPaused = false;
    });
    // Only auto-play if TTS was already playing before the chapter change
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
        debugPrint('Auto-play on chapter change failed: $e');
      }
    }
  }

  Future<void> _initializeTTS() async {
    if (!_hasAcquired) {
      _hasAcquired = true;
      _ttsService.acquire(); // FIX #1: Reference count the singleton
    }
    setState(() {
      _isLoading = true;
      _isVoicesLoading = true;
      _hasInitError = false;
    });

    _ttsService.onVoicesLoaded = () {
      if (mounted) {
        setState(() => _isVoicesLoading = false);
      }
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
            content: Text('Audio error: $error'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    };

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _ttsService.stop();
    _ttsService.clearCallbacks();
    if (_hasAcquired) {
      _hasAcquired = false;
      _ttsService.release(); // FIX #1: Release reference on dispose
    }
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _animController.forward() : _animController.reverse();
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
              _loadInterstitialAd(); // Reload next ad
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
        onAdFailedToLoad: (err) {
          debugPrint('TTS interstitial ad failed to load: ${err.message}');
        },
      ),
    );
  }

  Future<void> _stop() async {
    await _ttsService.stop();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
    });

    // Show interstitial ad every 3rd stop
    _stopCount++;
    if (_stopCount % 2 == 0 && _interstitialAd != null && mounted) {
      _interstitialAd!.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error state — show a retry button
    if (_hasInitError) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red.shade50.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade300, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
            const SizedBox(width: 8),
            Text(
              'Audio unavailable',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() => _hasInitError = false);
                _initializeTTS();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.dividerBrown.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main player row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Play/Pause button
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: AppColors.vintageInk,
                          shape: BoxShape.circle,
                        ),
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
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
                                size: 24,
                              ),
                      ),
                    ),

                    if (_isPlaying || _isPaused) ...[
                      const SizedBox(width: 8),
                      // Stop button
                      GestureDetector(
                        onTap: _stop,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stop_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Show chapter title or status
                      Expanded(
                        child: Text(
                          (widget.title != null && widget.title!.isNotEmpty)
                              ? widget.title!
                              : (_isPaused ? 'Paused' : 'Playing...'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      Text(
                        'Listen',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(width: 8),

                    // Settings toggle button
                    GestureDetector(
                      onTap: _toggleExpanded,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.tune,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded settings panel
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Speech Rate Slider
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

                      const SizedBox(height: 8),

                      // Pitch Slider
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

                      const SizedBox(height: 8),

                      // Volume Slider
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

                      const SizedBox(height: 8),

                      // Voice Selector — loading skeleton or actual selector
                      if (_isVoicesLoading)
                        _buildVoiceLoadingSkeleton()
                      else if (_ttsService.availableVoices.isNotEmpty)
                        _buildVoiceSelector()
                      else
                        _buildNoVoicesMessage(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.vintageInk,
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
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ],
    );
  }

  /// Skeleton shimmer shown while voices are loading
  Widget _buildVoiceLoadingSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.record_voice_over, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Loading voices...',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 6),
                // Animated skeleton bar
                _ShimmerSkeleton(),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              color: Colors.white54,
              strokeWidth: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.record_voice_over, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                isExpanded: true,
                value: _ttsService.currentVoice.isNotEmpty
                    ? _ttsService.currentVoice
                    : null,
                dropdownColor: AppColors.dividerBrown,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white70,
                  size: 18,
                ),
                items: _ttsService.availableVoices.map((voice) {
                  return DropdownMenuItem<String>(
                    value: voice['name'],
                    child: Text(
                      '${voice['name']} (${voice['locale']})',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
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

  /// Shown when no Tamil voices are found
  Widget _buildNoVoicesMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white54, size: 14),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Using default system voice',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small animated skeleton bar used as a loading placeholder
class _ShimmerSkeleton extends StatefulWidget {
  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.05),
              ],
              stops: [
                (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                _shimmerController.value,
                (_shimmerController.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
