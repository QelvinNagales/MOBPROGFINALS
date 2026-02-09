/// Friend model class
/// Represents a student connection/friend in the network.
class Friend {
  String name;
  String course;
  String interest;

  Friend({
    required this.name,
    required this.course,
    required this.interest,
  });

  /// Creates a copy of this friend with optional overrides
  Friend copyWith({
    String? name,
    String? course,
    String? interest,
  }) {
    return Friend(
      name: name ?? this.name,
      course: course ?? this.course,
      interest: interest ?? this.interest,
    );
  }
}
