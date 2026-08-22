import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:thiruvasagampro/utils/ad_helper.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/app_open_ad_manager.dart';

String _formatDuration(Duration d) {
  if (d.inHours > 0) {
    return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
  return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class AudioPlayerWidget extends StatefulWidget {
  final String? audioUrl;
  final String? title;

  const AudioPlayerWidget({super.key, this.audioUrl, this.title});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isReady = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isCheckingUrl = false;
  bool _isDraggingProgress = false;
  bool _urlAvailable = false;
  bool _hasError = false;
  String? _errorMessage;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _playingSub;

  // Ad
  InterstitialAd? _interstitialAd;
  int _stopCount = 0;

  @override
  void initState() {
    super.initState();
    _listenToStreams();
    _checkUrlAvailability();
    _loadInterstitialAd();
  }

  @override
  void didUpdateWidget(covariant AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl && mounted) {
      _onUrlChanged();
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

  Future<void> _onUrlChanged() async {
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _isReady = false;
      _isBuffering = false;
      _hasError = false;
      _errorMessage = null;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });
    await _checkUrlAvailability();
  }

  void _listenToStreams() {
    _playingSub = _audioPlayer.playingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });

    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isBuffering =
            state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading;
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        }
      });
    });

    _positionSub = _audioPlayer.positionStream.listen((position) {
      if (mounted && !_isDraggingProgress) {
        setState(() => _currentPosition = position);
      }
    });

    _durationSub = _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _totalDuration = duration ?? Duration.zero);
      }
    });
  }

  Future<void> _checkUrlAvailability() async {
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) {
      if (mounted) setState(() => _urlAvailable = false);
      return;
    }

    if (mounted) setState(() => _isCheckingUrl = true);

    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.isEmpty ||
          connectivityResults.contains(ConnectivityResult.none)) {
        if (mounted) {
          setState(() {
            _urlAvailable = false;
            _isCheckingUrl = false;
          });
        }
        return;
      }

      final response = await http.head(Uri.parse(widget.audioUrl!));
      if (mounted) {
        setState(() {
          _urlAvailable = response.statusCode == 200;
          _isCheckingUrl = false;
        });
      }
    } catch (e) {
      debugPrint('AudioPlayerWidget: URL check failed: $e');
      if (mounted) {
        setState(() {
          _urlAvailable = false;
          _isCheckingUrl = false;
        });
      }
    }
  }

  Future<void> _startPlayback() async {
    if (!mounted || widget.audioUrl == null || widget.audioUrl!.isEmpty) return;

    try {
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _isBuffering = true;
      });

      await _audioPlayer.setUrl(widget.audioUrl!);
      await _audioPlayer.play();

      if (mounted) {
        setState(() {
          _isReady = true;
          _isBuffering = false;
        });
      }
    } catch (e) {
      debugPrint('AudioPlayerWidget: Playback failed: $e');
      if (mounted) {
        setState(() {
          _isBuffering = false;
          _hasError = true;
          _errorMessage = 'Failed to load audio';
        });
      }
    }
  }

  void _togglePlayPause() {
    if (!mounted) return;

    try {
      if (_isPlaying) {
        _audioPlayer.pause();
        _stopCount++;
        if (_stopCount % 3 == 0 && _interstitialAd != null && mounted) {
          _interstitialAd!.show();
        }
      } else if (_isReady) {
        _audioPlayer.play();
      } else {
        _startPlayback();
      }
    } catch (e) {
      debugPrint('AudioPlayerWidget: Play/pause failed: $e');
    }
  }

  void _stop() {
    if (!mounted) return;

    try {
      _audioPlayer.stop();
      _stopCount++;
      if (_stopCount % 2 == 0 && _interstitialAd != null && mounted) {
        _interstitialAd!.show();
      }
    } catch (e) {
      debugPrint('AudioPlayerWidget: Stop failed: $e');
    }

    setState(() {
      _isPlaying = false;
      _isReady = false;
      _isBuffering = false;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });
  }

  void _skipForward() {
    if (!_isPlaying) return;
    final newPos = _currentPosition + const Duration(seconds: 10);
    _audioPlayer.seek(newPos > _totalDuration ? _totalDuration : newPos);
  }

  void _skipBackward() {
    if (!_isPlaying) return;
    final newPos = _currentPosition - const Duration(seconds: 10);
    _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  void _seekTo(Duration position) {
    _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.dividerBrown, AppColors.dividerBrown1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildPlayPauseButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null && widget.title!.isNotEmpty)
                        Text(
                          widget.title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      const SizedBox(height: 2),
                      _buildStatusRow(),
                    ],
                  ),
                ),
                if (_isPlaying || _isReady) ...[
                  const SizedBox(width: 8),
                  _buildControlButton(
                    icon: Icons.stop_rounded,
                    color: Colors.red.shade600,
                    onTap: _stop,
                    size: 40,
                  ),
                ],
              ],
            ),
          ),
          if ((_isPlaying || _isReady) && _totalDuration.inMilliseconds > 0)
            _buildProgressBar(),
          if (_isPlaying || _isReady)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSkipButton(
                    icon: Icons.replay_10_rounded,
                    onTap: _skipBackward,
                  ),
                  const SizedBox(width: 40),
                  _buildSkipButton(
                    icon: Icons.forward_10_rounded,
                    onTap: _skipForward,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _togglePlayPause,
        customBorder: const CircleBorder(),
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: AppColors.vintageInk,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.vintageInk.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildPlayPauseIcon(),
        ),
      ),
    );
  }

  Widget _buildPlayPauseIcon() {
    if (_hasError) {
      return const Icon(Icons.error_outline, color: Colors.white, size: 26);
    }
    if (_isBuffering && !_isReady) {
      return const Padding(
        padding: EdgeInsets.all(13.0),
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      );
    }
    return Icon(
      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      color: Colors.white,
      size: 30,
    );
  }

  Widget _buildStatusRow() {
    String statusText;
    IconData? statusIcon;

    if (_hasError) {
      statusText = _errorMessage ?? 'Error';
      statusIcon = Icons.error_outline;
    } else if (_isCheckingUrl) {
      statusText = 'Checking audio...';
      statusIcon = null;
    } else if (_isBuffering && !_isReady) {
      statusText = 'Loading audio...';
      statusIcon = null;
    } else if (_isPlaying) {
      statusText = 'Streaming audio';
      statusIcon = Icons.wifi;
    } else if (_isReady) {
      statusText = 'Paused';
      statusIcon = Icons.pause;
    } else if (!_urlAvailable) {
      statusText = 'Audio not available offline';
      statusIcon = Icons.wifi_off;
    } else {
      statusText = 'Tap to listen to audio';
      statusIcon = Icons.headphones;
    }

    return Row(
      children: [
        if (_isBuffering && !_isReady) ...[
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              color: Colors.white.withValues(alpha: 0.7),
              strokeWidth: 1.5,
            ),
          ),
          const SizedBox(width: 4),
        ] else if (statusIcon != null) ...[
          Icon(
            statusIcon,
            color: Colors.white.withValues(alpha: 0.7),
            size: 12,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          statusText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onHorizontalDragStart: (details) {
              setState(() => _isDraggingProgress = true);
            },
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final dx = details.localPosition.dx.clamp(
                  0.0,
                  box.size.width - 32,
                );
                final newProgress = dx / (box.size.width - 32);
                setState(() {
                  _currentPosition = Duration(
                    milliseconds: (newProgress * _totalDuration.inMilliseconds)
                        .toInt(),
                  );
                });
              }
            },
            onHorizontalDragEnd: (details) {
              setState(() => _isDraggingProgress = false);
              _seekTo(_currentPosition);
            },
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  final fillWidth = barWidth * progress.clamp(0.0, 1.0);

                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        width: fillWidth,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.vintageInk,
                              AppColors.vintageInk.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Positioned(
                        left: fillWidth - 6,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 36,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }

  Widget _buildSkipButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
