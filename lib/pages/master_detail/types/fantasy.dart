class Fantasy {
  final String name;
  final Gender gender;
  final String race;

  Fantasy({
    required this.name,
    required this.gender,
    required this.race,
  });
}

enum Gender { male, female }
