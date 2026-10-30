import 'package:flutter/material.dart';
import 'package:rize/helpers/muscle_group_labels.dart';
import 'package:rize/types/workout.dart';

/// Explicit side assignments prevent failed asset loads from silently hiding
/// highlights. German/legacy names resolve to the same masks as the catalogue.
const Map<String, List<String>> _muscleAliases = {
  'abs': ['abs'],
  'abdominals': ['abs'],
  'bauch': ['abs'],
  'biceps': ['biceps'],
  'bizeps': ['biceps'],
  'chest': ['chest'],
  'brust': ['chest'],
  'glutes': ['glutes'],
  'gesäß': ['glutes'],
  'gesaess': ['glutes'],
  'hamstring': ['hamstring'],
  'hamstrings': ['hamstring'],
  'beinbeuger': ['hamstring'],
  'lower back': ['lower back'],
  'lowerback': ['lower back'],
  'unterer rücken': ['lower back'],
  'obliques': ['obliques'],
  'seitliche bauchmuskeln': ['obliques'],
  'quadriceps': ['quadriceps'],
  'quadrizeps': ['quadriceps'],
  'oberschenkel': ['quadriceps'],
  'shoulder': ['shoulders'],
  'shoulders': ['shoulders'],
  'schulter': ['shoulders'],
  'schultern': ['shoulders'],
  'front shoulder': ['front shoulders'],
  'front shoulders': ['front shoulders'],
  'vordere schulter': ['front shoulders'],
  'vordere schultern': ['front shoulders'],
  'rear shoulder': ['rear shoulders'],
  'rear shoulders': ['rear shoulders'],
  'hintere schulter': ['rear shoulders'],
  'hintere schultern': ['rear shoulders'],
  'triceps': ['triceps'],
  'trizeps': ['triceps'],
  'upper back': ['upper back'],
  'oberer rücken': ['upper back'],
  'calf': ['calves'],
  'calves': ['calves'],
  'waden': ['calves'],
  'rücken': ['upper back', 'lower back'],
  'back': ['upper back', 'lower back'],
  'beine': ['quadriceps', 'hamstring', 'calves'],
  'legs': ['quadriceps', 'hamstring', 'calves'],
  'ganzkörper': [
    'abs',
    'biceps',
    'chest',
    'glutes',
    'hamstring',
    'lower back',
    'obliques',
    'quadriceps',
    'shoulders',
    'triceps',
    'upper back',
    'calves',
  ],
};

const Map<String, String> _frontMuscleAssets = {
  'abs': 'abs',
  'biceps': 'biceps',
  'chest': 'chest',
  'obliques': 'obliques',
  'quadriceps': 'quadriceps',
  'shoulders': 'shoulders',
  'front shoulders': 'shoulders',
};
const Map<String, String> _backMuscleAssets = {
  'glutes': 'glutes',
  'hamstring': 'hamstring',
  'lower back': 'lower back',
  'obliques': 'obliques',
  'shoulders': 'shoulders',
  'rear shoulders': 'shoulders',
  'triceps': 'triceps',
  'upper back': 'upper back',
  'calves': 'calves',
};

List<String> muscleAssetPaths(String groupName, bool isFront) {
  final groups =
      _muscleAliases[groupName.trim().toLowerCase()] ?? const <String>[];
  final assets = isFront ? _frontMuscleAssets : _backMuscleAssets;
  final side = isFront ? 'front' : 'back';
  return groups
      .where(assets.containsKey)
      .map((group) => 'assets/muscle_graphics/$side/${assets[group]}.png')
      .toSet()
      .toList(growable: false);
}

String? muscleAssetPath(String groupName, bool isFront) =>
    muscleAssetPaths(groupName, isFront).firstOrNull;

class MuscleVisualizer {
  String? groupToAsset(String groupName, bool isFront) =>
      muscleAssetPath(groupName, isFront);

  ImageProvider? getMuscleImage(String groupName, bool isFront) {
    final assetPath = groupToAsset(groupName, isFront);
    return assetPath == null ? null : AssetImage(assetPath);
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
    final String assetPath = entry.$2;
    final Color color = entry.$1 == 0 ? primaryColor : secondaryColor;

    if (!isFront && assetPath.endsWith('/lower back.png')) {
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
    if (!isFront && assetPath.endsWith('/upper back.png')) {
      // The source asset includes rear deltoids. Keep those exclusive to the
      // shoulder overlay so an upper-back exercise cannot highlight them.
      return ClipPath(clipper: const _UpperBackClipper(), child: overlay);
    }
    if (!isFront && assetPath.endsWith('/shoulders.png')) {
      return ClipPath(clipper: const _RearShoulderClipper(), child: overlay);
    }
    if (!isFront && assetPath.endsWith('/triceps.png')) {
      return ClipPath(clipper: const _UpperArmClipper(), child: overlay);
    }
    if (!isFront && assetPath.endsWith('/glutes.png')) {
      return ClipPath(clipper: const _GluteClipper(), child: overlay);
    }
    return overlay;
  }

  @override
  Widget build(BuildContext context) {
    final String side = isFront ? 'front' : 'back';
    final Map<String, int> overlays = {};
    for (final entry in groups.indexed) {
      for (final path in muscleAssetPaths(entry.$2, isFront)) {
        overlays.putIfAbsent(path, () => entry.$1);
      }
    }
    Widget body() => Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        ...overlays.entries.map(
          (entry) => _muscleOverlay((entry.value, entry.key)),
        ),
        Image.asset(
          'assets/muscle_graphics/$side/base_$side.png',
          height: height,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
        ),
      ],
    );
    // Mirror the full composition on both views, using one common axis for
    // the outline and every muscle, independent of highlight order. Use the
    // left source half: its rear shoulder has the continuous compartment.
    return RepaintBoundary(
      key: ValueKey<String>('symmetric-$side-body'),
      child: SizedBox(
        width: height * (isFront ? 127 : 129) / 400,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRect(clipper: const _HalfClipper(right: false), child: body()),
            ClipRect(
              clipper: const _HalfClipper(right: true),
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
    // Reflect this boundary to the left half used by the body composition.
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
      (Matrix4.translationValues(size.width, 0, 0) *
              Matrix4.diagonal3Values(-size.width / 129, size.height / 400, 1))
          .storage,
    );
  }

  @override
  bool shouldReclip(_UpperBackClipper oldClipper) => false;
}

/// Keep the original upper-arm fill out of the forearm compartment.
class _UpperArmClipper extends CustomClipper<Path> {
  const _UpperArmClipper();

  @override
  Path getClip(Size size) =>
      (Path()
            ..moveTo(0, 0)
            ..lineTo(129, 0)
            ..lineTo(129, 142)
            ..lineTo(117, 142)
            ..lineTo(110, 138)
            ..lineTo(104, 141)
            ..lineTo(25, 141)
            ..lineTo(19, 138)
            ..lineTo(12, 142)
            ..lineTo(0, 142)
            ..close())
          .transform(
            Matrix4.diagonal3Values(
              size.width / 129,
              size.height / 400,
              1,
            ).storage,
          );

  @override
  bool shouldReclip(_UpperArmClipper oldClipper) => false;
}

/// Stop at the gluteal fold rather than highlighting the outer thigh too.
class _GluteClipper extends CustomClipper<Path> {
  const _GluteClipper();

  @override
  Path getClip(Size size) =>
      (Path()
            ..moveTo(0, 0)
            ..lineTo(129, 0)
            ..lineTo(129, 212)
            ..lineTo(90, 212)
            ..lineTo(86, 218)
            ..lineTo(76, 220)
            ..lineTo(65, 218)
            ..lineTo(53, 220)
            ..lineTo(43, 218)
            ..lineTo(39, 212)
            ..lineTo(0, 212)
            ..close())
          .transform(
            Matrix4.diagonal3Values(
              size.width / 129,
              size.height / 400,
              1,
            ).storage,
          );

  @override
  bool shouldReclip(_GluteClipper oldClipper) => false;
}

/// Share the exact boundary with the upper back so a secondary back fill
/// cannot split a shoulder into regions with different highlight colours.
class _RearShoulderClipper extends CustomClipper<Path> {
  const _RearShoulderClipper();

  @override
  Path getClip(Size size) => Path.combine(
    PathOperation.difference,
    Path()..addRect(Offset.zero & size),
    const _UpperBackClipper().getClip(size),
  );

  @override
  bool shouldReclip(_RearShoulderClipper oldClipper) => false;
}
