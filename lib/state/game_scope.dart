import 'package:flutter/widgets.dart';

import 'game_controller.dart';

/// Makes the single [GameController] available to the whole tree. Screens read
/// it with `GameScope.of(context)` and rebuild when it notifies.
class GameScope extends InheritedNotifier<GameController> {
  const GameScope({
    super.key,
    required GameController controller,
    required super.child,
  }) : super(notifier: controller);

  static GameController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'No GameScope found in context');
    return scope!.notifier!;
  }

  /// For callbacks that only need to *act* on the controller and shouldn't
  /// subscribe the calling widget to rebuilds.
  static GameController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'No GameScope found in context');
    return scope!.notifier!;
  }
}
