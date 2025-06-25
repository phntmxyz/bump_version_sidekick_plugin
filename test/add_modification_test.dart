import 'package:phntmxyz_bump_version_sidekick_plugin/phntmxyz_bump_version_sidekick_plugin.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('executes sync modification', () async {
    await insideFakeProjectWithSidekick((dir) async {
      await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
      final readme = dir.file('README.md');
      readme.writeAsStringSync('''
# Package

```yaml
dependencies:
  my_package: ^1.2.3
```
      ''');
      final runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(
        BumpVersionCommand()
          ..addModification((package, oldVersion, newVersion) {
            final versionRegex = RegExp(r'my_package: \^(.+)');
            final update = readme.readAsStringSync().replaceFirst(
                  versionRegex,
                  'my_package: ^${newVersion.canonicalizedVersion}',
                );
            readme.writeAsStringSync(update);
          }),
      );
      await runner.run(['bump-version', '--minor']);

      expect(readme.readAsStringSync(), contains('my_package: ^1.3.0'));
    });
  });

  test('executes async modification', () async {
    await insideFakeProjectWithSidekick((dir) async {
      await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
      final readme = dir.file('README.md');
      readme.writeAsStringSync('''
# Package

```yaml
dependencies:
  my_package: ^1.2.3
```
      ''');
      final runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(
        BumpVersionCommand()
          ..addModification((package, oldVersion, newVersion) async {
            // make it really async
            await Future.delayed(const Duration(milliseconds: 200));

            final versionRegex = RegExp(r'my_package: \^(.+)');
            final update = readme.readAsStringSync().replaceFirst(
                  versionRegex,
                  'my_package: ^${newVersion.canonicalizedVersion}',
                );
            readme.writeAsStringSync(update);
          }),
      );
      await runner.run(['bump-version', '--minor']);

      expect(readme.readAsStringSync(), contains('my_package: ^1.3.0'));
    });
  });

  test('modification receives correct versions', () async {
    await insideFakeProjectWithSidekick((dir) async {
      await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
      final readme = dir.file('README.md');
      readme.writeAsStringSync('''
# Package

```yaml
dependencies:
  my_package: ^1.2.3
```
      ''');
      final runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );

      Version? oldVersion;
      Version? newVersion;
      runner.addCommand(
        BumpVersionCommand()
          ..addModification((package, oldV, newV) {
            oldVersion = oldV;
            newVersion = newV;
          }),
      );
      await runner.run(['bump-version', '--minor']);

      expect(oldVersion, Version(1, 2, 3));
      expect(newVersion, Version(1, 3, 0));
    });
  });
}
