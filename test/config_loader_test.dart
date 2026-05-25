import 'package:flutter_test/flutter_test.dart';
import 'package:shinobi_world/config/game_config_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads first demo config modules', () async {
    final config = await GameConfigLoader.load();

    expect(config.app.brand.companyName, 'Boadas Corp');
    expect(config.character.pointRoll.min, 5);
    expect(config.character.pointRoll.max, 25);
    expect(config.worldRun.villageCount.min, 10);
    expect(config.worldRun.villageCount.max, 20);
    expect(config.villagePopulation.roleStats['kage'], isNotNull);
    expect(config.training.minimumRequiredSeals, 1);
    expect(config.enemies, isEmpty);
  });
}
