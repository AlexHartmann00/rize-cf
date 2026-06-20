import 'package:flutter/material.dart';
import 'package:rize/helpers/muscle_group_labels.dart';
import 'package:rize/types/workout.dart';

class MuscleVisualizer {
  String groupToAsset(String groupName, bool isFront) {
    return 'assets/muscle_graphics/${isFront ? "front" : "back"}/${groupName.toLowerCase()}.png';
  }

  ImageProvider getMuscleImage(String groupName, bool isFront) {
    String assetPath = groupToAsset(groupName, isFront);
    return AssetImage(assetPath);
  }
}

class MuscleVisualization extends StatelessWidget {
  MuscleVisualization({super.key, required this.workout});

  Workout workout;

  @override
  Widget build(BuildContext context) {
    //print('Muscle groups to visualize: ${workout.muscleGroups}, ${'assets/muscle_graphics/front/${workout.muscleGroups[0].toLowerCase()}.png'}');
    Color intensityColor = Color.lerp(
      Colors.green,
      Colors.red,
      workout.impactScore,
    )!;

    //TODO: Muscle group color gradient (ordered, first is most used)

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 100,
            height: 74,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Image.asset(
                      'assets/muscle_graphics/front/base_front.png',
                      height: 72,
                      color: Colors.white.withOpacity(0.55),
                    ),
                    ...workout.usedMuscleGroups.map(
                      (group) => Image.asset(
                        'assets/muscle_graphics/front/${group.toLowerCase()}.png',
                        color: intensityColor,
                        height: 72,
                        errorBuilder: (context, error, stackTrace) =>
                            SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Stack(
                  children: <Widget>[
                    Image.asset(
                      'assets/muscle_graphics/back/base_back.png',
                      height: 72,
                      color: Colors.white.withOpacity(0.55),
                    ),
                    ...workout.usedMuscleGroups.map(
                      (group) => Image.asset(
                        'assets/muscle_graphics/back/${group.toLowerCase()}.png',
                        color: intensityColor,
                        height: 72,
                        errorBuilder: (context, error, stackTrace) =>
                            SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
