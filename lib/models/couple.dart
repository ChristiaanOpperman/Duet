import 'player.dart';

/// A team of two. Couples are the scoring unit — points earned by either
/// partner go to the couple's total.
class Couple {
  const Couple({
    required this.id,
    required this.partnerA,
    required this.partnerB,
  });

  final String id;
  final Player partnerA;
  final Player partnerB;

  List<Player> get players => [partnerA, partnerB];

  String get displayName => '${partnerA.name} & ${partnerB.name}';

  /// The other half of the pair — who has to do the guessing for [player].
  Player partnerOf(Player player) =>
      player.id == partnerA.id ? partnerB : partnerA;

  bool contains(Player player) =>
      player.id == partnerA.id || player.id == partnerB.id;

  Couple copyWith({Player? partnerA, Player? partnerB}) => Couple(
        id: id,
        partnerA: partnerA ?? this.partnerA,
        partnerB: partnerB ?? this.partnerB,
      );

  @override
  bool operator ==(Object other) => other is Couple && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
