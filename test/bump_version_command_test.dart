import 'package:bump_version_sidekick_plugin/bump_version_sidekick_plugin.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('throws when pubspec does not exist', () async {
    await insideFakeProjectWithSidekick((dir) async {
      dir.file('pubspec.yaml').deleteSync();
      final runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(BumpVersionCommand());
      expect(
        () => runner.run(['bump-version', '--major']),
        throwsA('Pubspec.yaml not found'),
      );
    });
  });

  test('throws when pubspec has no version', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(BumpVersionCommand());
      expect(
        () => runner.run(['bump-version', '--major']),
        throwsA(contains('has no current version')),
      );
    });
  });

  test('bumps major', () async {
    await insideFakeProjectWithSidekick((dir) async {
      await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
      final runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(BumpVersionCommand());
      await runner.run(['bump-version', '--major']);
      expect(
        PubSpec.fromFile(dir.file('pubspec.yaml').path).version,
        Version(2, 0, 0),
      );
    });
  });

  test('bumps minor', () async {
    await insideFakeProjectWithSidekick((dir) async {
      await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
      final runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(BumpVersionCommand());
      await runner.run(['bump-version', '--minor']);
      expect(
        PubSpec.fromFile(dir.file('pubspec.yaml').path).version,
        Version(1, 3, 0),
      );
    });
  });

  test('bumps patch', () async {
    await insideFakeProjectWithSidekick((dir) async {
      await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
      final runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(BumpVersionCommand());
      await runner.run(['bump-version', '--patch']);
      expect(
        PubSpec.fromFile(dir.file('pubspec.yaml').path).version,
        Version(1, 2, 4),
      );
    });
  });

  group('commit', () {
    test('throws when pubspec has local changes', () async {
      await insideFakeProjectWithSidekick((dir) async {
        'git init -q ${dir.path} '.run;
        'git -C ${dir.path} add .'.run;
        'git -C ${dir.path} commit -m "initial"'.run;
        await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
        final runner = initializeSidekick(
          dartSdkPath: fakeDartSdk().path,
        );
        runner.addCommand(BumpVersionCommand());
        expect(
          () => runner.run(['bump-version', '--major', '--commit']),
          throwsA(contains('There are local changes')),
        );
      });
    });

    test('throws when there are staged files', () async {
      await insideFakeProjectWithSidekick((dir) async {
        await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
        'git init -q ${dir.path} '.run;
        'git -C ${dir.path} add .'.run;
        'git -C ${dir.path} commit -m "initial"'.run;
        dir.file('foo').writeAsStringSync('foo');
        'git -C ${dir.path} add foo'.run;

        final runner = initializeSidekick(
          dartSdkPath: fakeDartSdk().path,
        );
        runner.addCommand(BumpVersionCommand());
        expect(
          () => runner.run(['bump-version', '--major', '--commit']),
          throwsA(contains('There are staged files')),
        );
      });
    });

    test('throws when HEAD is deteached', () async {
      await insideFakeProjectWithSidekick((dir) async {
        await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
        'git init -q ${dir.path} '.run;
        'git -C ${dir.path} add .'.run;
        'git -C ${dir.path} commit -m "initial"'.run;
        'git -C ${dir.path} checkout --detach'.run;

        final runner = initializeSidekick(
          dartSdkPath: fakeDartSdk().path,
        );
        runner.addCommand(BumpVersionCommand());
        expect(
          () => runner.run(['bump-version', '--major', '--commit']),
          throwsA(contains('You are in "detached HEAD" state')),
        );
      });
    });

    test('commits version bump', () async {
      await insideFakeProjectWithSidekick((dir) async {
        await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
        'git init -q ${dir.path} '.run;
        'git -C ${dir.path} add .'.run;
        'git -C ${dir.path} commit -m "initial"'.run;

        final runner = initializeSidekick(
          dartSdkPath: fakeDartSdk().path,
        );
        runner.addCommand(BumpVersionCommand());
        await runner.run(['bump-version', '--major', '--commit']);

        final lastCommitMessage = 'git -C ${dir.path} show -s --format=%s'
            .start(progress: Progress.capture(), nothrow: true)
            .lines
            .first;
        expect(lastCommitMessage, contains('Bump version to 2.0.0'));
      });
    });
  });
}