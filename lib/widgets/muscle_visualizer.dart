import 'package:flutter/material.dart';
import 'package:rize/helpers/muscle_group_labels.dart';
import 'package:rize/types/workout.dart';

String? _muscleAssetPath(String groupName, bool isFront) {
  String assetName = groupName.trim().toLowerCase();
  switch (assetName) {
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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
    return Image.asset(
      assetPath,
      color: entry.$1 == 0 ? primaryColor : secondaryColor,
      colorBlendMode: BlendMode.srcIn,
      height: height,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String side = isFront ? 'front' : 'back';
    return Stack(
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
  }
}
