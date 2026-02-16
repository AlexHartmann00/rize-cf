import 'package:flutter/material.dart';
import 'package:rize/types/workout.dart';

class MuscleVisualizer {
  String groupToAsset(String groupName, bool isFront){
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
    Color intensityColor = Color.lerp(Colors.green, Colors.red, workout.impactScore)!;

    //TODO: Muscle group color gradient (ordered, first is most used)

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(children: [
              Image.asset(  
                    'assets/muscle_graphics/front/base_front.png',
                    height: 100,
                    color: Colors.black,
                  ),
              ...workout.usedMuscleGroups.map((group) => Image.asset(
                    'assets/muscle_graphics/front/${group.toLowerCase()}.png',
                    color: intensityColor,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
                  )),
            ],),
            SizedBox(width: 20),
            Stack(children: [
              Image.asset(  
                    'assets/muscle_graphics/back/base_back.png',
                    height: 100,
                    color: Colors.black,
                  ),
              ...workout.usedMuscleGroups.map((group) => Image.asset(
                    'assets/muscle_graphics/back/${group.toLowerCase()}.png',
                    color: intensityColor,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
                  )),
            ],),
          ],
        ),
      ),
    );
  }
}