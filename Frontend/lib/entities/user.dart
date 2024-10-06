class User {
  final String? id;
  final String? profilePhoto;
  final String? email;
  final String? name;
  final String? surname;
  final String? genre;
  final String? bornDate;
  final double? elo;
  final List<Map<String, dynamic>>? lastMatchesInfo;

  User({
    required this.id,
    required this.profilePhoto,
    required this.email,
    required this.name,
    required this.surname,
    required this.genre,
    required this.bornDate,
    this.elo,
    this.lastMatchesInfo,
  });
}