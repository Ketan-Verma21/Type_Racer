import 'package:flutter_test/flutter_test.dart';
import 'package:type_racer/screens/game/game_screen.dart';
import 'package:type_racer/state/game_controller.dart';

import '../../fakes/builders.dart';
import '../../fakes/fake_game_repository.dart';

void main() {
  late FakeGameRepository repo;
  late GameController game;

  setUp(() {
    repo = FakeGameRepository()..myPlayerId = 'me';
    game = GameController(repo);
  });

  GameView viewWith({bool isJoin = true, bool isOver = false, int idx = 0, bool spectator = false, bool out = false}) {
    repo.emitGame(room(
      isJoin: isJoin,
      isOver: isOver,
      players: [player('me', idx: idx, spectator: spectator, out: out), player('rival')],
    ));
    return viewFor(game);
  }

  test('lobby before the start', () => expect(viewWith(), GameView.lobby));
  test('race once it started', () => expect(viewWith(isJoin: false), GameView.race));
  test('results when I finished, even while others race',
      () => expect(viewWith(isJoin: false, idx: kWords.length), GameView.results));
  test('results when the race is over', () => expect(viewWith(isOver: true), GameView.results));
  test('watch when I am out', () => expect(viewWith(isJoin: false, out: true), GameView.watch));
  test('watch as a spectator, even in the lobby',
      () => expect(viewWith(spectator: true), GameView.watch));
}
