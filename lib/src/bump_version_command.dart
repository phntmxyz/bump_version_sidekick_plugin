import 'package:phntmxyz_bump_version_sidekick_plugin/phntmxyz_bump_version_sidekick_plugin.dart';
import 'package:phntmxyz_bump_version_sidekick_plugin/src/git_file_committer.dart';
import 'package:sidekick_core/sidekick_core.dart';

class BumpVersionCommand extends Command {
  @override
  final String description = 'Bumps the version of a package';

  @override
  String get invocation => super.invocation.replaceFirst(
        '[arguments]',
        '[package-path] [--minor|patch|major] --[no-]commit',
      );

  @override
  final String name = 'bump-version';

  BumpVersionCommand() {
    argParser.addFlag(
      'major',
      help: 'Bumps to the next major version. e.g. 1.2.6+8 => 2.0.0+9',
    );
    argParser.addFlag(
      'minor',
      help: 'Bumps to the next minor version. e.g. 1.2.6+8 => 1.3.0+9',
    );
    argParser.addFlag(
      'patch',
      help: 'Bumps to the next patch version. e.g. 1.2.6+8 => 1.2.7+9',
    );
    argParser.addFlag(
      'commit',
      help:
          'Automatically commits the version bump. Precondition, no local changes in pubspec.yaml',
    );
  }

  @override
  Future<void> run() async {
    // Parse arguments
    final bool commit = argResults?['commit'] as bool? ?? false;
    final bumpType = argResults!.parseBumpType();

    final packageDirectory = Directory(
      argResults?.rest.firstOrNull ??
          mainProject?.root.path ??
          Directory.current.path,
    );
    final package = DartPackage.fromDirectory(packageDirectory);
    if (package == null) {
      error("No Dart package with pubspec.yaml found "
          "in ${packageDirectory.path}");
    }
    final pubspecFile = package.pubspec;

    // Read current version
    final Version? currentVersion = readPubspecVersion(pubspecFile);
    if (currentVersion == null) {
      error("Can't bump version because "
          "${pubspecFile.path} has no current version");
    }

    // Bump version
    final Version bumpedVersion = currentVersion.bumpVersion(bumpType);

    final fileCommitter = GitFileCommitter(pubspecFile);
    if (commit) {
      fileCommitter.captureFileStatus();
    }

    // Save to pubspec.yaml
    setPubspecVersion(pubspecFile, bumpedVersion);
    print(
      green('${package.name} version bumped '
          'from $currentVersion to $bumpedVersion'),
    );

    if (commit) {
      fileCommitter.commit('Bump version to $bumpedVersion');
    }
  }
}

extension on ArgResults {
  VersionBumpType parseBumpType() {
    final bool bumpMajor = this['major'] as bool? ?? false;
    final bool bumpMinor = this['minor'] as bool? ?? false;
    final bool bumpPatch = this['patch'] as bool? ?? false;

    if (!(bumpMajor ^
        bumpMinor ^
        bumpPatch ^
        (bumpMajor && bumpMinor && bumpPatch))) {
      // exactly one bump<version> variable must be true, all others must be false
      error('Bump version with either --major, --minor, or --patch');
    }

    if (bumpMajor) return VersionBumpType.major;
    if (bumpMinor) return VersionBumpType.minor;
    if (bumpPatch) return VersionBumpType.patch;
    throw 'No bump type selected';
  }
}
