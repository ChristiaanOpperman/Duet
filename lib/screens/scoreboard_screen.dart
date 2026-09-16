import 'package:flutter/material.dart';

import '../state/game_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/page_header.dart';
import '../widgets/standings_list.dart';

/// Shown between couples so the room gets a beat to react before the next
/// pair takes the phone.
class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final justPlayed = game.currentTurn.coupleIndex;

    return GradientScaffold(
      bottomBar: GlowButton(
        label: 'Next couple: ${game.currentCouple.displayName}',
        icon: Icons.arrow_forward_rounded,
        onPressed: game.continueFromScoreboard,
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.l),
        children: [
          PageHeader(
            title: 'Standings',
            eyebrow: 'Couple $justPlayed of ${game.coupleCount} done',
          ),
          const SizedBox(height: Insets.l),
          StandingsList(
            standings: game.standings,
            highlightCoupleId: game.couples[justPlayed - 1].id,
          ),
        ],
      ),
    );
  }
}
