import 'package:flutter/material.dart';
import 'package:rize/helpers/muscle_group_labels.dart';
import 'package:rize/types/workout.dart';

String? _muscleAssetPath(String groupName, bool isFront) {
  String assetName = groupName.trim().toLowerCase();
  switch (assetName) {
    case 'hamstrings':
      assetName = 'hamstring';
      break;
    case 'lowerback':
      assetName = 'lower back';
      break;
    case 'calf':
    case 'calves':
      if (isFront) return null;
      assetName = 'calves';
      break;
    case 'front shoulder':
    case 'front shoulders':
      if (!isFront) return null;
      assetName = 'shoulders';
      break;
    case 'rear shoulder':
    case 'rear shoulders':
      if (isFront) return null;
      assetName = 'shoulders';
      break;
    case 'shoulder':
      assetName = 'shoulders';
      break;
  }
  final String side = isFront ? 'front' : 'back';
  return 'assets/muscle_graphics/$side/$assetName.png';
}

String? muscleAssetPath(String groupName, bool isFront) =>
    _muscleAssetPath(groupName, isFront);

class MuscleVisualizer {
  String groupToAsset(String groupName, bool isFront) {
    return _muscleAssetPath(groupName, isFront) ??
        'assets/muscle_graphics/${isFront ? "front" : "back"}/${groupName.toLowerCase()}.png';
  }

  ImageProvider getMuscleImage(String groupName, bool isFront) {
    String assetPath = groupToAsset(groupName, isFront);
    return AssetImage(assetPath);
  }
}

class MuscleVisualization extends StatelessWidget {
  const MuscleVisualization({
    super.key,
    required this.workout,
    this.large = false,
  });

  final Workout workout;
  final bool large;

  @override
  Widget build(BuildContext context) {
    const Color primaryMuscleColor = Color(0xFFE93B3B);
    const Color secondaryMuscleColor = Color(0xFFFF8A3D);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          _MuscleBodies(
            groups: workout.usedMuscleGroups,
            height: large ? 132 : 72,
            primaryColor: primaryMuscleColor,
            secondaryColor: secondaryMuscleColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'TRAINIERT',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  workout.usedMuscleGroups.map(muscleGroupLabel).join(' · '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleBodies extends StatelessWidget {
  const _MuscleBodies({
    required this.groups,
    required this.height,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final List<String> groups;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 1.4,
      height: height + 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _BodyStack(
            isFront: true,
            groups: groups,
            height: height,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          ),
          SizedBox(width: height * 0.13),
          _BodyStack(
            isFront: false,
            groups: groups,
            height: height,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          ),
        ],
      ),
    );
  }
}

class _BodyStack extends StatelessWidget {
  const _BodyStack({
    required this.isFront,
    required this.groups,
    required this.height,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final bool isFront;
  final List<String> groups;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;

  Widget _muscleOverlay((int, String) entry) {
    final String? assetPath = _muscleAssetPath(entry.$2, isFront);
    if (assetPath == null) return const SizedBox.shrink();
    final String normalizedGroup = entry.$2.trim().toLowerCase();
    final Color color = entry.$1 == 0 ? primaryColor : secondaryColor;

    if (!isFront &&
        (normalizedGroup == 'lower back' || normalizedGroup == 'lowerback')) {
      return _CentralMuscleMask(
        key: const ValueKey<String>('central-lower-back'),
        assetPath: assetPath,
        color: color,
        height: height,
      );
    }
    final Widget overlay = _muscleImage(
      assetPath: assetPath,
      color: color,
      height: height,
    );
    if (!isFront && normalizedGroup == 'upper back') {
      // The source asset includes rear deltoids. Keep those exclusive to the
      // shoulder overlay so an upper-back exercise cannot highlight them.
      return ClipPath(clipper: const _UpperBackClipper(), child: overlay);
    }
    return overlay;
  }

  @override
  Widget build(BuildContext context) {
    final String side = isFront ? 'front' : 'back';
    Widget body() => Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        ...groups.indexed.map(_muscleOverlay),
        Image.asset(
          'assets/muscle_graphics/$side/base_$side.png',
          height: height,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
        ),
      ],
    );
    if (isFront) return body();

    // Mirror the complete composition so secondary muscles cannot cover the
    // upper back differently on each side. All layers share the same axis.
    return RepaintBoundary(
      key: const ValueKey<String>('symmetric-back-body'),
      child: SizedBox(
        width: height * 129 / 400,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRect(clipper: const _HalfClipper(right: true), child: body()),
            ClipRect(
              clipper: const _HalfClipper(right: false),
              child: Transform.flip(flipX: true, child: body()),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _muscleImage({
  required String assetPath,
  required Color color,
  required double height,
  BoxFit? fit,
}) {
  return Image.asset(
    assetPath,
    color: color,
    colorBlendMode: BlendMode.srcIn,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
  );
}

class _CentralMuscleMask extends StatelessWidget {
  const _CentralMuscleMask({
    super.key,
    required this.assetPath,
    required this.color,
    required this.height,
  });

  final String assetPath;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 129 / 400,
      height: height,
      child: ClipRect(
        clipper: const _CenterClipper(),
        child: _muscleImage(
          assetPath: assetPath,
          color: color,
          height: height,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  const _HalfClipper({required this.right});

  final bool right;

  @override
  Rect getClip(Size size) => right
      ? Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height)
      : Rect.fromLTWH(0, 0, size.width / 2, size.height);

  @override
  bool shouldReclip(_HalfClipper oldClipper) => oldClipper.right != right;
}

class _CenterClipper extends CustomClipper<Rect> {
  const _CenterClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(size.width * 0.39, 0, size.width * 0.22, size.height);

  @override
  bool shouldReclip(_CenterClipper oldClipper) => false;
}

class _UpperBackClipper extends CustomClipper<Path> {
  const _UpperBackClipper();

  @override
  Path getClip(Size size) {
    // Follow the inner deltoid boundary in the 129 x 400 source image.
    // The back composition mirrors its right half after clipping.
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(129, 0)
      ..lineTo(129, 64)
      ..lineTo(86, 64)
      ..lineTo(90, 66)
      ..lineTo(89, 68)
      ..lineTo(83, 70)
      ..lineTo(76, 72)
      ..lineTo(69, 74)
      ..lineTo(75, 76)
      ..lineTo(83, 78)
      ..lineTo(88, 80)
      ..lineTo(92, 82)
      ..lineTo(96, 84)
      ..lineTo(104, 92)
      ..lineTo(111, 100)
      ..lineTo(119, 108)
      ..lineTo(124, 114)
      ..lineTo(129, 114)
      ..lineTo(129, 400)
      ..lineTo(0, 400)
      ..close();
    return path.transform(
      Matrix4.diagonal3Values(size.width / 129, size.height / 400, 1).storage,
    );
  }

  @override
  bool shouldReclip(_UpperBackClipper oldClipper) => false;
}
