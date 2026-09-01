import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rize/helpers/screen_awake_service.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubeVideo extends StatefulWidget {
  final String videoId; // e.g. "dQw4w9WgXcQ"
  const YoutubeVideo({super.key, required this.videoId});

  @override
  State<YoutubeVideo> createState() => _YoutubeVideoState();
}

class _YoutubeVideoState extends State<YoutubeVideo>
    with WidgetsBindingObserver {
  late final YoutubePlayerController _controller;
  late final StreamSubscription<YoutubePlayerValue> _playerSubscription;
  final ScreenAwakeHandle _screenAwake = ScreenAwakeHandle();
  bool _appIsActive = true;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        mute: false,
        playsInline: true,
        interfaceLanguage: 'de',
      ),
    )..loadVideoById(videoId: widget.videoId);
    _playerSubscription = _controller.stream.listen(_handlePlayerValue);
    WidgetsBinding.instance.addObserver(this);
  }

  void _handlePlayerValue(YoutubePlayerValue value) {
    final bool isPlaying =
        value.playerState == PlayerState.playing ||
        value.playerState == PlayerState.buffering;
    unawaited(_screenAwake.setActive(_appIsActive && isPlaying));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
    _handlePlayerValue(_controller.value);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerSubscription.cancel();
    _screenAwake.dispose();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(controller: _controller, aspectRatio: 16 / 9);
  }
}
