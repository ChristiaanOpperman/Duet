/// One half of a couple.
class Player {
  const Player({required this.id, required this.name});

  final String id;
  final String name;

  Player copyWith({String? name}) => Player(id: id, name: name ?? this.name);

  @override
  bool operator ==(Object other) => other is Player && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player($id, $name)';
}
