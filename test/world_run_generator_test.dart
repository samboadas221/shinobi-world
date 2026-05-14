import 'package:flutter_test/flutter_test.dart';
import 'package:shinobi_world/config/game_config_loader.dart';
import 'package:shinobi_world/world/world_run_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates a starting village and then the remaining run', () async {
    final config = await GameConfigLoader.load();
    final generator = WorldRunGenerator(
      runConfig: config.worldRun,
      populationConfig: config.villagePopulation,
    );

    final partialRun = generator.generateStartingVillageOnly();
    final fullRun = generator.generateRemaining(partialRun);

    expect(partialRun.villages, hasLength(1));
    expect(fullRun.villages.length, inInclusiveRange(10, 20));
    expect(fullRun.ninjas, isNotEmpty);
    expect(fullRun.ninjas.first.stats.keys, contains('health'));
  });
}
