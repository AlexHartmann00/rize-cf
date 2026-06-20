const Map<String, String> _muscleGroupLabels = <String, String>{
  'abs': 'Bauch',
  'abdominals': 'Bauch',
  'biceps': 'Bizeps',
  'chest': 'Brust',
  'glutes': 'Gesäß',
  'hamstring': 'Beinbeuger',
  'hamstrings': 'Beinbeuger',
  'lower back': 'Unterer Rücken',
  'obliques': 'Seitliche Bauchmuskeln',
  'quadriceps': 'Oberschenkel',
  'shoulders': 'Schultern',
  'triceps': 'Trizeps',
  'upper back': 'Oberer Rücken',
  'calves': 'Waden',
};

String muscleGroupLabel(String technicalName) =>
    _muscleGroupLabels[technicalName.trim().toLowerCase()] ?? technicalName;
