import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
      final pubspec = dir.file('pubspec.yaml');
      await pubspec.appendString('\nversion: 1.2.3');

      // TODO remove
      print('Directory.current: ${Directory.current.path}');
      print('pubspec.path: ${pubspec.path}');
      print('pubspec.existsSync(): ${pubspec.existsSync()}');
      print('dcli exists: ${exists(pubspec.path)}');

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

  // TODO remove
  test('bumps major2', () async {
    late final SidekickCommandRunner runner;
    late final File pubspec;
    await insideFakeProjectWithSidekick2((dir) async {
      pubspec = dir.file('pubspec.yaml');
      await pubspec.appendString('\nversion: 1.2.3');

      print('Directory.current: ${Directory.current.path}');
      print('pubspec.path: ${pubspec.path}');
      print('pubspec.existsSync(): ${pubspec.existsSync()}');
      print('dcli exists: ${exists(pubspec.path)}');

      final pathToUtf8Array = _toUtf8Array(pubspec.path);
      print('pathToUtf8Array: $pathToUtf8Array');
      final pathToStringFromUtf8Array = _toStringFromUtf8Array(pathToUtf8Array);
      print('pathToStringFromUtf8Array: $pathToStringFromUtf8Array');
      final rawPath = utf8.encoder.convert(pathToStringFromUtf8Array);
      print('rawPath: $rawPath');

      runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );
    });

    print('outside insideFakeProjectWithSidekick2');
    print('Directory.current: ${Directory.current.path}');
    print('pubspec.path: ${pubspec.path}');
    print('pubspec.existsSync(): ${pubspec.existsSync()}');
    print('dcli exists: ${exists(pubspec.path)}');

    runner.addCommand(BumpVersionCommand());
    await runner.run(['bump-version', '--major', pubspec.parent.path]);
    expect(
      PubSpec.fromFile(pubspec.path).version,
      Version(2, 0, 0),
    );
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
        _gitCommit(dir);
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
        _gitCommit(dir);
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
  withEnvironment(
    () => 'git commit -m "initial"'
        .start(workingDirectory: workingDirectory.path),
    // without this, `git commit` crashes on CI
    environment: {
      'GIT_AUTHOR_NAME': 'Sidekick Test CI',
      'GIT_AUTHOR_EMAIL': 'sidekick-ci@phntm.xyz',
      'GIT_COMMITTER_NAME': 'Sidekick Test CI',
      'GIT_COMMITTER_EMAIL': 'sidekick-ci@phntm.xyz',
    },
  );
}

// TODO remove
R insideFakeProjectWithSidekick2<R>(
  R Function(Directory projectRoot) callback, {
  bool overrideSidekickCoreWithLocalDependency = false,
  String? sidekickCoreVersion,
  String? lockedSidekickCoreVersion,
  String? sidekickCliVersion,
  bool insideGitRepo = false,
}) {
  final tempDir = Directory.systemTemp.createTempSync();
  Directory projectRoot = tempDir;
  if (insideGitRepo) {
    'git init -q ${tempDir.path}'.run;
    projectRoot = tempDir.directory('myProject')..createSync();
  }

  projectRoot.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('''
name: main_project

environment:
  sdk: '>=2.14.0 <3.0.0'
''');
  projectRoot.file('dash').createSync();

  final fakeSidekickDir = projectRoot.directory('packages/dash')
    ..createSync(recursive: true);

  fakeSidekickDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('''
name: dash

environment:
  sdk: '>=2.14.0 <3.0.0'
  
${sidekickCoreVersion == null && !overrideSidekickCoreWithLocalDependency ? '' : '''
dependencies:
  sidekick_core: ${sidekickCoreVersion ?? '0.0.0'}
'''}

${sidekickCliVersion == null ? '' : '''
sidekick:
  cli_version: $sidekickCliVersion
'''}
''');
  fakeSidekickDir.file('pubspec.lock')
    ..createSync()
    ..writeAsStringSync('''
packages:
  sidekick_core:
    dependency: "direct main"
    source: hosted
    description:
      name: sidekick_core
      url: "https://pub.dev"
    version: "${lockedSidekickCoreVersion ?? '0.0.0'}"
''');

  final fakeSidekickLibDir = fakeSidekickDir.directory('lib')..createSync();

  fakeSidekickLibDir.file('src/dash_project.dart').createSync(recursive: true);
  fakeSidekickLibDir.file('dash_sidekick.dart').createSync();

  env['SIDEKICK_PACKAGE_HOME'] = fakeSidekickDir.absolute.path;
  env['SIDEKICK_ENTRYPOINT_HOME'] = projectRoot.absolute.path;
  if (!env.exists('SIDEKICK_ENABLE_UPDATE_CHECK')) {
    env['SIDEKICK_ENABLE_UPDATE_CHECK'] = 'false';
  }

  if (overrideSidekickCoreWithLocalDependency) {
    overrideSidekickCoreWithLocalPath(fakeSidekickDir);
  }

  addTearDown(() {
    projectRoot.deleteSync(recursive: true);
    env['SIDEKICK_PACKAGE_HOME'] = null;
    env['SIDEKICK_ENTRYPOINT_HOME'] = null;
    env['SIDEKICK_ENABLE_UPDATE_CHECK'] = null;
  });

  Directory cwd = projectRoot;

  final oldZone = Zone.current;

  return IOOverrides.runZoned<R>(
    () => callback(projectRoot),
    fseGetTypeSync: (String path, bool followLinks) {
      final rawPath = _toStringFromUtf8Array(_toUtf8Array(path));

      print('fseGetTypeSync override');
      print('path: $path');
      print('path.codeUnits: ${path.codeUnits}');
      print('rawPath: $rawPath');
      print('rawPath.codeUnits: ${rawPath.codeUnits}');

      return oldZone.run(() {
        return FileSystemEntity.typeSync(rawPath, followLinks: followLinks);
      });
    },
    getCurrentDirectory: () => cwd,
    setCurrentDirectory: (dir) => cwd = Directory(dir),
  );
}

String _toStringFromUtf8Array(Uint8List l) {
  Uint8List nonNullTerminated = l;
  if (l.last == 0) {
    nonNullTerminated =
        new Uint8List.view(l.buffer, l.offsetInBytes, l.length - 1);
  }
  return utf8.decode(nonNullTerminated, allowMalformed: true);
}

Uint8List _toUtf8Array(String s) =>
    _toNullTerminatedUtf8Array(utf8.encoder.convert(s));

Uint8List _toNullTerminatedUtf8Array(Uint8List l) {
  if (l.isEmpty || (l.isNotEmpty && l.last != 0)) {
    final tmp = new Uint8List(l.length + 1);
    tmp.setRange(0, l.length, l);
    return tmp;
  } else {
    return l;
  }
}
