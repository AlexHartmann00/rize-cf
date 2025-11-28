class MuscleGroup {
  String name;
  MuscleArea muscleArea;

  MuscleGroup({required this.name, required this.muscleArea});

  factory MuscleGroup.fromJson(Map<String, dynamic> json) {
    return MuscleGroup(
      name: json["name"],
      muscleArea: MuscleArea.fromJson({"name": json["muscleArea"]}),
    );
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "muscleArea": muscleArea.name,
      };
}

class MuscleArea {
  String name;

  MuscleArea({required this.name});

  factory MuscleArea.fromJson(Map<String, dynamic> json) {
    return MuscleArea(name: json["name"]);
  }

  Map<String, dynamic> toJson() => {"name": name};
}