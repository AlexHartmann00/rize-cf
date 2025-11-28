import 'package:fitness_app/base_widgets.dart';
import 'package:fitness_app/types/workout.dart';
import 'package:flutter/material.dart';

class WorkoutSummaryWidget extends StatefulWidget {
  Workout workout;
  
  WorkoutSummaryWidget({super.key, required this.workout});

  @override
  State<WorkoutSummaryWidget> createState() => _WorkoutSummaryWidgetState();
}

class _WorkoutSummaryWidgetState extends State<WorkoutSummaryWidget> {
  @override
  Widget build(BuildContext context) {
    Workout workout = widget.workout;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutDetailsPage(workout: workout)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(100),
          border: Border.all(),
          borderRadius: BorderRadius.circular(15)
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            Text(workout.name),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Intensität ${workout.impactLevel.name}'),
                Icon(Icons.flash_on, color: Color.lerp(Colors.green, Colors.red, workout.impactScore),),
                Column(children: [
                  CircularProgressIndicator(
                    value: workout.impactScore,
                    color: Color.lerp(Colors.green, Colors.red, workout.impactScore),
                  ),          
                  Text(workout.impactScore.toString())
                ],),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text('${workout.baseSeconds} Sekunden'),
                  Text('${workout.baseReps} Wiederholungen')
                ],)
              ],
              
            ),
            
          ],),
        ),
      ),
    );
  }
}

class WorkoutDetailsPage extends StatefulWidget {
  Workout workout;
  WorkoutDetailsPage({super.key, required this.workout});

  @override
  State<WorkoutDetailsPage> createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends State<WorkoutDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: rizeAppBar,
      body: Column(
        children: [
          Text(widget.workout.name),
          Text(widget.workout.description),
          Text('${widget.workout.baseReps} Wiederholungen')
        ],
      ),
    );
  }
}

AppBar rizeAppBar = AppBar(
  backgroundColor: Colors.white,
        title: Row(
          spacing: 10,
          children: [
          Image.asset('assets/brand/Logo transparent.png', height: 50,),
          Text('RIZE', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),)
        ],),
      );

class AnamnesisQuestionnaire extends StatefulWidget {
  const AnamnesisQuestionnaire({super.key});

  @override
  State<AnamnesisQuestionnaire> createState() => _AnamnesisQuestionnaireState();
}

class _AnamnesisQuestionnaireState extends State<AnamnesisQuestionnaire> {
  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: rizeAppBar,
      body: Column(
        children: [
          Text('Anamnesebogen'),
          Form(
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Alter',
                  ),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Gewicht',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Absenden'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}