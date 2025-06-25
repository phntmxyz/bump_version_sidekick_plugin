import 'package:phntmxyz_bump_version_sidekick_plugin/phntmxyz_bump_version_sidekick_plugin.dart';
import 'package:pubspec_manager/pubspec_manager.dart' as pubspec_manager;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  // ignore: unnecessary_async
  test('throws when pubspec does not exist', () async {
    insideFakeProjectWithSidekick((dir) {
      dir.file('pubspec.yaml').deleteSync();
      final runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(BumpVersionCommand());
      expect(
        () => runner.run(['bump-version', '--major']),
        throwsA(contains('No Dart package with pubspec.yaml found')),
      );
    });
  });

  test('throws when pubspec has no version', () async {
    // ignore: unnecessary_async
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
      final pubspec = dir.file('pubspec.yaml');
      await pubspec.appendString('\nversion: 1.2.3');

      final runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(BumpVersionCommand());
      await runner.run(['bump-version', '--major']);
      expect(
        pubspec_manager.PubSpec.loadFromPath(dir.file('pubspec.yaml').path)
            .version
            .toString(),
        '2.0.0',
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
        pubspec_manager.PubSpec.loadFromPath(dir.file('pubspec.yaml').path)
            .version
            .toString(),
        '1.3.0',
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
        pubspec_manager.PubSpec.loadFromPath(dir.file('pubspec.yaml').path)
            .version
            .toString(),
        '1.2.4',
      );
    });
  });

  group('commit', () {
    test('works when pubspec has local changes', () async {
      await insideFakeProjectWithSidekick((dir) async {
        'git init -q ${dir.path} '.run;
        'git -C ${dir.path} add .'.run;
        await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
        _gitCommit(dir);
        // local change
        await dir.file('pubspec.yaml').appendString('\n\n#comment');
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
        expect(
          dir.file('pubspec.yaml').readAsStringSync(),
          contains('#comment'),
        );
        expect(
          dir.file('pubspec.yaml').readAsStringSync(),
          contains('version: 2.0.0'),
        );
      });
    });

    test('staged files are restored', () async {
      await insideFakeProjectWithSidekick((dir) async {
        await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
        'git init -q ${dir.path} '.run;
        'git -C ${dir.path} add .'.run;
        _gitCommit(dir);
        final fooFile = dir.file('foo')..writeAsStringSync('foo');
        'git -C ${dir.path} add foo'.run;

        final runner = initializeSidekick(
          dartSdkPath: fakeDartSdk().path,
        );
        runner.addCommand(BumpVersionCommand());
        expect(fooFile.existsSync(), isTrue);
        expect(fooFile.readAsStringSync(), 'foo');
      });
    });

    test('throws when HEAD is deteached', () async {
      await insideFakeProjectWithSidekick((dir) async {
        await dir.file('pubspec.yaml').appendString('\nversion: 1.2.3');
        'git init -q ${dir.path} '.run;
        'git -C ${dir.path} add .'.run;
        _gitCommit(dir);
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
        _gitCommit(dir);

        // `BumpVersionCommand` calls `git commit` which needs this committer information, else it throws
        'git config user.email "sidekick-ci@phntm.xyz"'
            .start(workingDirectory: dir.path);
        'git config user.name "Sidekick Test CI"'
            .start(workingDirectory: dir.path);
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

void _gitCommit(Directory workingDirectory) {
  // Set git configuration for this test to avoid CI failures
  'git config user.email "sidekick-ci@phntm.xyz"'
      .start(workingDirectory: workingDirectory.path);
  'git config user.name "Sidekick Test CI"'
      .start(workingDirectory: workingDirectory.path);

  'git commit -m "initial"'.start(workingDirectory: workingDirectory.path);
}
