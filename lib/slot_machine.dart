import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// SlotMachine widget with per-reel symbols, optional titles, and external control.
///
/// - Each reel can have its own list of widgets.
/// - Optional titles displayed above each reel.
/// - Lever can be shown or hidden. If hidden, use [SlotMachineController] to spin
///   from your own button/callback.
/// - [onResult] returns the selected index per reel.
/// - [controller] exposes spin() / spinTo() and [spinning].
///
/// Example usage with external button and titles:
///
/// final controller = SlotMachineController();
/// ...
/// SlotMachine(
///   controller: controller,
///   showLever: false,
///   symbolsPerReel: const [
///     [Text('A'), Text('B'), Text('C')],
///     [Icon(Icons.star), Icon(Icons.favorite), Icon(Icons.pets)],
///     [Text('10'), Text('20'), Text('50'), Text('100')],
///   ],
///   reelTitles: const [Text('Übung'), Text('Intensität'), Text('Häufigkeit')],
///   onResult: (indices) => debugPrint('Result indices: $indices'),
/// ),
/// ElevatedButton(
///   onPressed: () => controller.spin(),
///   child: const Text('Spin'),
/// )
class SlotMachine extends StatefulWidget {
  const SlotMachine({
    super.key,
    required this.symbolsPerReel,
    this.onResult,
    this.height = 280,
    this.reelWidth = 100,
    this.itemExtent = 60,
    this.reelSpacing = 8,
    this.borderRadius = 24,
    this.spinMinRounds = 18,
    this.spinMaxRounds = 28,
    this.staggerMs = 350,
    this.enableItemTap = false,
    this.reelTitles,
    this.showLever = true,
    this.controller,
  });

  /// Per-reel widgets to show as repeating symbols.
  final List<List<Widget>> symbolsPerReel;

  /// Optional titles shown above each reel (Widget per reel).
  final List<Widget>? reelTitles;

  /// Called when all reels stop. Provides indices into the corresponding reel list.
  final void Function(List<int> resultIndices)? onResult;

  /// Visual layout parameters
  final double height;
  final double reelWidth;
  final double itemExtent;
  final double reelSpacing;
  final double borderRadius;

  /// Spin behavior
  final int spinMinRounds;
  final int spinMaxRounds;
  final int staggerMs;

  /// If true, taps on a tile try to snap it to center (if not spinning)
  final bool enableItemTap;

  /// Show built-in lever on the right. If false, hide lever (use controller to spin).
  final bool showLever;

  /// Optional external controller.
  final SlotMachineController? controller;

  int get reelCount => symbolsPerReel.length;

  @override
  State<SlotMachine> createState() => _SlotMachineState();
}

class _SlotMachineState extends State<SlotMachine> with TickerProviderStateMixin {
  late final List<FixedExtentScrollController> _controllers;
  late final AnimationController _leverController;
  late final Random _rng;
  bool _spinning = false;
  late SlotMachineController _controllerProxy;

  static const int _loopMultiplier = 200;

  @override
  void initState() {
    super.initState();
    _rng = Random();
    _controllers = List.generate(widget.reelCount, (_) => FixedExtentScrollController());
    _leverController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

    _controllerProxy = widget.controller ?? SlotMachineController._internal();
    _controllerProxy._attach(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < widget.reelCount; i++) {
        final reelLen = widget.symbolsPerReel[i].length;
        final base = reelLen * (_loopMultiplier ~/ 2);
        final startIndex = base + _rng.nextInt(reelLen);
        _controllers[i].jumpToItem(startIndex);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SlotMachine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _controllerProxy)._detach(this);
      final newController = widget.controller ?? SlotMachineController._internal();
      _controllerProxy = newController;
      _controllerProxy._attach(this);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    _leverController.dispose();
    _controllerProxy._detach(this);
    super.dispose();
  }

  bool get spinning => _spinning;

  void _normalizeReel(int reelIndex) {
    final controller = _controllers[reelIndex];
    final reelLen = widget.symbolsPerReel[reelIndex].length;
    final base = reelLen * (_loopMultiplier ~/ 2);
    final cur = controller.selectedItem % reelLen;
    controller.jumpToItem(base + cur);
  }

  Future<List<int>> _spin({List<int>? targetIndices}) async {
    if (_spinning) return Future.value(const []);
    setState(() => _spinning = true);

    if (widget.showLever) await _leverController.forward();

    for (int i = 0; i < _controllers.length; i++) {
      _normalizeReel(i);
    }

    final List<int> finalIndices = [];

    for (int i = 0; i < _controllers.length; i++) {
      final controller = _controllers[i];
      final reelLen = widget.symbolsPerReel[i].length;

      final chosenIndex = targetIndices != null
          ? (targetIndices[i] % reelLen)
          : _rng.nextInt(reelLen);

      final current = controller.selectedItem;
      final curMod = current % reelLen;

      final rounds = widget.spinMinRounds +
          _rng.nextInt(max(1, widget.spinMaxRounds - widget.spinMinRounds + 1));
      final forwardDeltaWithinCycle = (chosenIndex - curMod) % reelLen;
      final targetIndex = current + rounds * reelLen + forwardDeltaWithinCycle;

      if (i > 0) {
        await Future<void>.delayed(Duration(milliseconds: widget.staggerMs));
      }

      unawaited(controller.animateToItem(
        targetIndex,
        duration: Duration(milliseconds: 1200 + i * 450 + _rng.nextInt(400)),
        curve: Curves.easeOutCubic,
      ));

      finalIndices.add(chosenIndex);
    }

    final totalWait = Duration(milliseconds: 1600 + (_controllers.length - 1) * (widget.staggerMs + 450) + 450);
    await Future<void>.delayed(totalWait);

    if (widget.showLever) await _leverController.reverse();

    for (int i = 0; i < _controllers.length; i++) {
      _normalizeReel(i);
    }

    setState(() => _spinning = false);
    widget.onResult?.call(finalIndices);
    return finalIndices;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MachineBody(
              borderRadius: widget.borderRadius,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < widget.reelCount; i++) ...[
                    SizedBox(
                      width: widget.reelWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.reelTitles != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: DefaultTextStyle.merge(
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: widget.reelTitles![i],
                                ),
                              ),
                            ),
                          _buildReel(i),
                        ],
                      ),
                    ),
                    if (i < widget.reelCount - 1) SizedBox(width: widget.reelSpacing),
                  ],
                ],
              ),
            ),
          ),
          if (widget.showLever) ...[
            const SizedBox(width: 16),
            _Lever(
              animation: _leverController,
              onPull: () => _spin(),
              disabled: _spinning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReel(int reelIndex) {
    final symbols = widget.symbolsPerReel[reelIndex];
    final reelLen = symbols.length;
    final totalItems = reelLen * _loopMultiplier;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.10),
              Colors.transparent,
              Colors.black.withOpacity(0.10),
            ],
          ),
          border: Border.all(color: Colors.black12),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SizedBox(
          width: widget.reelWidth,
          height: widget.itemExtent * 3.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ListWheelScrollView.useDelegate(
                controller: _controllers[reelIndex],
                itemExtent: widget.itemExtent,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.003,
                overAndUnderCenterOpacity: 0.2,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: totalItems,
                  builder: (context, index) {
                    if (index < 0 || index >= totalItems) return null;
                    final symbolIndex = index % reelLen;
                    final child = symbols[symbolIndex];

                    return _SymbolTile(
                      height: widget.itemExtent - 10,
                      child: KeyedSubtree(
                        key: ValueKey('reel-$reelIndex-sym-$symbolIndex'),
                        child: child,
                      ),
                      enableTap: widget.enableItemTap,
                      onTap: () {
                        if (!_spinning) {
                          final current = _controllers[reelIndex].selectedItem;
                          final curMod = current % reelLen;
                          final delta = (symbolIndex - curMod) % reelLen;
                          _controllers[reelIndex].animateToItem(
                            current + delta,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              IgnorePointer(
                child: Container(
                  height: widget.itemExtent,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                    border: const Border(
                      top: BorderSide(color: Colors.black12),
                      bottom: BorderSide(color: Colors.black12),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// External controller to spin programmatically or land on target indices.
class SlotMachineController {
  _SlotMachineState? _state;
  SlotMachineController();
  SlotMachineController._internal();

  bool get spinning => _state?.spinning ?? false;

  Future<List<int>> spin() async {
    return await _state?._spin() ?? Future.value(const []);
  }

  Future<List<int>> spinTo(List<int> targetIndices) async {
    return await _state?._spin(targetIndices: targetIndices) ?? Future.value(const []);
  }

  void _attach(_SlotMachineState state) => _state = state;
  void _detach(_SlotMachineState state) {
    if (identical(_state, state)) _state = null;
  }
}

class _MachineBody extends StatelessWidget {
  const _MachineBody({
    required this.child,
    required this.borderRadius,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(blurRadius: 16, offset: Offset(0, 8), color: Color(0x1A000000)),
          ],
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _SymbolTile extends StatelessWidget {
  const _SymbolTile({
    required this.child,
    required this.height,
    this.enableTap = false,
    this.onTap,
  });

  final Widget child;
  final double height;
  final bool enableTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        ),
      ),
    );
    return enableTap ? InkWell(onTap: onTap, child: content) : content;
  }
}

class _Lever extends StatelessWidget {
  const _Lever({
    required this.animation,
    required this.onPull,
    required this.disabled,
  });
  final AnimationController animation;
  final VoidCallback onPull;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final angleTween = Tween<double>(begin: 0, end: -0.30).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    return GestureDetector(
      onTap: disabled ? null : onPull,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: angleTween,
                builder: (context, child) => Transform.rotate(
                  angle: angleTween.value,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
                child: _LeverGraphics(disabled: disabled),
              ),
              const SizedBox(height: 16),
              Text(
                disabled ? 'Spinning…' : 'Pull',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeverGraphics extends StatelessWidget {
  const _LeverGraphics({ required this.disabled });
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: disabled ? scheme.secondaryContainer : scheme.primary,
            boxShadow: const [
              BoxShadow(blurRadius: 10, color: Color(0x33000000), offset: Offset(0, 4))
            ],
          ),
        ),
        Container(
          width: 8,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.grey.shade600,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          width: 54,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade700,
            borderRadius: BorderRadius.circular(9),
            boxShadow: const [
              BoxShadow(blurRadius: 8, color: Color(0x33000000), offset: Offset(0, 2))
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper to detach a Future without awaiting it
void unawaited(Future<void> f) {}
