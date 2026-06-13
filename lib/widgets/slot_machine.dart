
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Responsive RIZE slot machine.
///
/// The public API intentionally stays close to the previous implementation so
/// existing calls to [SlotMachineController.spin] and
/// [SlotMachineController.spinTo] continue to work.
class SlotMachine extends StatefulWidget {
  const SlotMachine({
    super.key,
    required this.symbolsPerReel,
    this.onResult,
    this.height = 238,
    this.reelWidth = 100,
    this.itemExtent = 64,
    this.reelSpacing = 8,
    this.borderRadius = 24,
    this.spinMinRounds = 18,
    this.spinMaxRounds = 28,
    this.staggerMs = 190,
    this.enableItemTap = false,
    this.reelTitles,
    this.showLever = false,
    this.controller,
    this.enableHaptics = true,
    this.compact = false,
  });

  final List<List<Widget>> symbolsPerReel;
  final List<Widget>? reelTitles;
  final void Function(List<int> resultIndices)? onResult;

  final double height;

  /// Retained for backwards compatibility.
  ///
  /// The redesigned machine distributes available width responsively and does
  /// not force this exact width on narrow screens.
  final double reelWidth;

  final double itemExtent;
  final double reelSpacing;
  final double borderRadius;

  final int spinMinRounds;
  final int spinMaxRounds;
  final int staggerMs;

  final bool enableItemTap;
  final bool showLever;
  final SlotMachineController? controller;

  /// Uses Flutter's built-in platform haptics. No extra dependency required.
  final bool enableHaptics;

  /// Reduces padding and title size for particularly narrow placements.
  final bool compact;

  int get reelCount => symbolsPerReel.length;

  @override
  State<SlotMachine> createState() => _SlotMachineState();
}

class _SlotMachineState extends State<SlotMachine>
    with TickerProviderStateMixin {
  static const int _loopMultiplier = 240;

  late List<FixedExtentScrollController> _reelControllers;
  late final AnimationController _leverController;
  late final AnimationController _glowController;
  late final Random _random;

  late SlotMachineController _controllerProxy;

  Timer? _hapticTimer;
  bool _spinning = false;
  int _stoppedReels = 0;

  bool get spinning => _spinning;

  @override
  void initState() {
    super.initState();

    _random = Random();
    _reelControllers = _createReelControllers();

    _leverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _controllerProxy =
        widget.controller ?? SlotMachineController._internal();
    _controllerProxy._attach(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _placeReelsNearMiddle();
    });
  }

  @override
  void didUpdateWidget(covariant SlotMachine oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _controllerProxy)._detach(this);

      _controllerProxy =
          widget.controller ?? SlotMachineController._internal();
      _controllerProxy._attach(this);
    }

    if (oldWidget.reelCount != widget.reelCount) {
      for (final FixedExtentScrollController controller
          in _reelControllers) {
        controller.dispose();
      }

      _reelControllers = _createReelControllers();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _placeReelsNearMiddle();
      });
    }
  }

  List<FixedExtentScrollController> _createReelControllers() {
    return List<FixedExtentScrollController>.generate(
      widget.reelCount,
      (_) => FixedExtentScrollController(),
      growable: false,
    );
  }

  void _placeReelsNearMiddle() {
    if (!mounted) return;

    for (int index = 0; index < widget.reelCount; index++) {
      final int reelLength = widget.symbolsPerReel[index].length;
      if (reelLength == 0) continue;

      final int middle = reelLength * (_loopMultiplier ~/ 2);
      final int start = middle + _random.nextInt(reelLength);

      if (_reelControllers[index].hasClients) {
        _reelControllers[index].jumpToItem(start);
      }
    }
  }

  @override
  void dispose() {
    _stopHapticSequence();

    for (final FixedExtentScrollController controller
        in _reelControllers) {
      controller.dispose();
    }

    _leverController.dispose();
    _glowController.dispose();
    _controllerProxy._detach(this);

    super.dispose();
  }

  void _normalizeReel(int reelIndex) {
    final FixedExtentScrollController controller =
        _reelControllers[reelIndex];

    if (!controller.hasClients) return;

    final int reelLength = widget.symbolsPerReel[reelIndex].length;
    if (reelLength == 0) return;

    final int middle = reelLength * (_loopMultiplier ~/ 2);
    final int currentSymbol = controller.selectedItem % reelLength;

    controller.jumpToItem(middle + currentSymbol);
  }

  Future<List<int>> _spin({List<int>? targetIndices}) async {
    if (_spinning || widget.reelCount == 0) {
      return const <int>[];
    }

    if (targetIndices != null &&
        targetIndices.length != widget.reelCount) {
      throw ArgumentError(
        'targetIndices must contain exactly ${widget.reelCount} values.',
      );
    }

    for (final List<Widget> reel in widget.symbolsPerReel) {
      if (reel.isEmpty) {
        throw StateError('Every slot-machine reel needs at least one item.');
      }
    }

    setState(() {
      _spinning = true;
      _stoppedReels = 0;
    });

    _glowController.repeat(reverse: true);
    _startHapticSequence();

    if (widget.showLever) {
      await _leverController.forward();
    }

    for (int index = 0; index < _reelControllers.length; index++) {
      _normalizeReel(index);
    }

    final List<int> resultIndices = <int>[];
    final List<Future<void>> reelAnimations = <Future<void>>[];

    for (int reelIndex = 0;
        reelIndex < _reelControllers.length;
        reelIndex++) {
      final FixedExtentScrollController controller =
          _reelControllers[reelIndex];
      final int reelLength = widget.symbolsPerReel[reelIndex].length;

      final int chosenIndex = targetIndices == null
          ? _random.nextInt(reelLength)
          : targetIndices[reelIndex] % reelLength;

      final int current = controller.selectedItem;
      final int currentSymbol = current % reelLength;

      final int rounds = widget.spinMinRounds +
          _random.nextInt(
            max(
              1,
              widget.spinMaxRounds - widget.spinMinRounds + 1,
            ),
          );

      final int delta =
          (chosenIndex - currentSymbol + reelLength) % reelLength;
      final int target = current + rounds * reelLength + delta;

      final Duration delay = Duration(
        milliseconds: reelIndex * widget.staggerMs,
      );

      final Duration duration = Duration(
        milliseconds:
            1250 + reelIndex * 330 + _random.nextInt(260),
      );

      resultIndices.add(chosenIndex);

      reelAnimations.add(
        Future<void>.delayed(delay, () async {
          if (widget.enableHaptics) {
            await HapticFeedback.lightImpact();
          }

          await controller.animateToItem(
            target,
            duration: duration,
            curve: Curves.easeOutQuart,
          );

          if (!mounted) return;

          setState(() {
            _stoppedReels += 1;
          });

          if (widget.enableHaptics) {
            await HapticFeedback.mediumImpact();
          }
        }),
      );
    }

    await Future.wait(reelAnimations);

    _stopHapticSequence();

    if (widget.showLever) {
      await _leverController.reverse();
    }

    for (int index = 0; index < _reelControllers.length; index++) {
      _normalizeReel(index);
    }

    await _glowController.reverse();

    if (widget.enableHaptics) {
      await HapticFeedback.heavyImpact();
    }

    if (!mounted) return resultIndices;

    setState(() {
      _spinning = false;
      _stoppedReels = widget.reelCount;
    });

    widget.onResult?.call(resultIndices);
    return resultIndices;
  }

  void _startHapticSequence() {
    if (!widget.enableHaptics) return;

    _stopHapticSequence();

    int tick = 0;

    // A soft mechanical tick. We deliberately skip some ticks later in the
    // sequence so the haptic rhythm feels as though the reels are slowing.
    _hapticTimer = Timer.periodic(
      const Duration(milliseconds: 78),
      (Timer timer) {
        if (!_spinning) {
          timer.cancel();
          return;
        }

        tick += 1;

        final bool shouldPulse = tick < 16 ||
            (tick < 28 && tick.isEven) ||
            (tick >= 28 && tick % 3 == 0);

        if (shouldPulse) {
          unawaited(HapticFeedback.selectionClick());
        }
      },
    );
  }

  void _stopHapticSequence() {
    _hapticTimer?.cancel();
    _hapticTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final bool narrow = MediaQuery.sizeOf(context).width < 390;
    final double horizontalPadding =
        widget.compact || narrow ? 10 : 14;
    final double spacing =
        widget.compact || narrow ? 5 : widget.reelSpacing;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (BuildContext context, Widget? child) {
        return Container(
          height: widget.height,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            widget.compact ? 10 : 12,
            horizontalPadding,
            widget.compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFFF9FBFF),
                Color(0xFFE9F1FF),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.88),
              width: 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              if (_spinning)
                BoxShadow(
                  color: const Color(0xFF58C7F3).withOpacity(
                    0.18 + _glowController.value * 0.12,
                  ),
                  blurRadius: 26,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int index = 0;
                        index < widget.reelCount;
                        index++) ...<Widget>[
                      Expanded(
                        child: _RizeReel(
                          controller: _reelControllers[index],
                          symbols: widget.symbolsPerReel[index],
                          title: widget.reelTitles == null
                              ? null
                              : widget.reelTitles![index],
                          itemExtent: widget.itemExtent,
                          reelIndex: index,
                          spinning: _spinning,
                          stopped: _stoppedReels > index,
                          enableItemTap: widget.enableItemTap,
                          onSelect: (int symbolIndex) {
                            _selectItem(index, symbolIndex);
                          },
                        ),
                      ),
                      if (index < widget.reelCount - 1)
                        SizedBox(width: spacing),
                    ],
                  ],
                ),
              ),
              if (widget.showLever) ...<Widget>[
                const SizedBox(width: 10),
                _PremiumLever(
                  animation: _leverController,
                  disabled: _spinning,
                  onPull: _spin,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _selectItem(int reelIndex, int symbolIndex) {
    if (_spinning || !widget.enableItemTap) return;

    final FixedExtentScrollController controller =
        _reelControllers[reelIndex];

    if (!controller.hasClients) return;

    final int reelLength = widget.symbolsPerReel[reelIndex].length;
    final int current = controller.selectedItem;
    final int currentSymbol = current % reelLength;
    final int delta =
        (symbolIndex - currentSymbol + reelLength) % reelLength;

    if (widget.enableHaptics) {
      unawaited(HapticFeedback.selectionClick());
    }

    controller.animateToItem(
      current + delta,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }
}

class _RizeReel extends StatelessWidget {
  const _RizeReel({
    required this.controller,
    required this.symbols,
    required this.itemExtent,
    required this.reelIndex,
    required this.spinning,
    required this.stopped,
    required this.enableItemTap,
    required this.onSelect,
    this.title,
  });

  final FixedExtentScrollController controller;
  final List<Widget> symbols;
  final Widget? title;
  final double itemExtent;
  final int reelIndex;
  final bool spinning;
  final bool stopped;
  final bool enableItemTap;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final int totalItems = symbols.length * _SlotMachineState._loopMultiplier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title != null) ...<Widget>[
          SizedBox(
            height: 29,
            child: Center(
              child: DefaultTextStyle.merge(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF19324F),
                  fontSize: 12,
                  letterSpacing: 0.1,
                  fontWeight: FontWeight.w900,
                ),
                child: title!,
              ),
            ),
          ),
          const SizedBox(height: 7),
        ],
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FE),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: const Color(0xFFD8E3F4),
                    ),
                  ),
                  child: ListWheelScrollView.useDelegate(
                    controller: controller,
                    itemExtent: itemExtent,
                    physics: enableItemTap && !spinning
                        ? const FixedExtentScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    diameterRatio: 1.45,
                    perspective: 0.0022,
                    squeeze: 0.94,
                    overAndUnderCenterOpacity: 0.24,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: totalItems,
                      builder: (BuildContext context, int index) {
                        if (index < 0 || index >= totalItems) {
                          return null;
                        }

                        final int symbolIndex = index % symbols.length;

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: enableItemTap
                              ? () => onSelect(symbolIndex)
                              : null,
                          child: _ReelSymbol(
                            child: KeyedSubtree(
                              key: ValueKey<String>(
                                'reel-$reelIndex-symbol-$symbolIndex',
                              ),
                              child: symbols[symbolIndex],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Premium selection window.
                IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: itemExtent,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          const Color(0xFF58C7F3).withOpacity(
                            spinning ? 0.14 : 0.10,
                          ),
                          const Color(0xFF176BC7).withOpacity(
                            spinning ? 0.16 : 0.11,
                          ),
                        ],
                      ),
                      border: Border.all(
                        color: stopped
                            ? const Color(0xFF58C7F3)
                            : const Color(0xFF8AB9EA),
                        width: stopped ? 1.5 : 1,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFF176BC7).withOpacity(0.10),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),

                // Fade reel edges so only the selected row gets full emphasis.
                IgnorePointer(
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                const Color(0xFFF5F8FE),
                                const Color(0xFFF5F8FE).withOpacity(0.12),
                              ],
                            ),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      SizedBox(height: itemExtent),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: <Color>[
                                const Color(0xFFF5F8FE),
                                const Color(0xFFF5F8FE).withOpacity(0.12),
                              ],
                            ),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
                  ),
                ),

                if (spinning)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF58C7F3),
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(0xFF58C7F3).withOpacity(0.55),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReelSymbol extends StatelessWidget {
  const _ReelSymbol({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Center(
        child: DefaultTextStyle.merge(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF19324F),
            fontSize: 12,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
          child: IconTheme.merge(
            data: const IconThemeData(
              color: Color(0xFF176BC7),
              size: 18,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class SlotMachineController {
  SlotMachineController();

  SlotMachineController._internal();

  _SlotMachineState? _state;

  bool get spinning => _state?.spinning ?? false;

  Future<List<int>> spin() {
    return _state?._spin() ?? Future<List<int>>.value(const <int>[]);
  }

  Future<List<int>> spinTo(List<int> targetIndices) {
    return _state?._spin(targetIndices: targetIndices) ??
        Future<List<int>>.value(const <int>[]);
  }

  void _attach(_SlotMachineState state) {
    _state = state;
  }

  void _detach(_SlotMachineState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }
}

class _PremiumLever extends StatelessWidget {
  const _PremiumLever({
    required this.animation,
    required this.onPull,
    required this.disabled,
  });

  final AnimationController animation;
  final Future<List<int>> Function() onPull;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final Animation<double> angle = Tween<double>(
      begin: 0,
      end: -0.32,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    return GestureDetector(
      onTap: disabled ? null : onPull,
      child: SizedBox(
        width: 42,
        child: AnimatedBuilder(
          animation: angle,
          builder: (BuildContext context, Widget? child) {
            return Transform.rotate(
              angle: angle.value,
              alignment: Alignment.bottomCenter,
              child: child,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      Color(0xFF79D5FF),
                      Color(0xFF176BC7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF176BC7).withOpacity(0.34),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              Container(
                width: 6,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFF7E92AA),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                width: 36,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF19324F),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
