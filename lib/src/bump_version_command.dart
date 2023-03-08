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
    final bool bumpMajor = argResults?['major'] as bool? ?? false;
    final bool bumpMinor = argResults?['minor'] as bool? ?? false;
    final bool bumpPatch = argResults?['patch'] as bool? ?? false;
    final bool commit = argResults?['commit'] as bool? ?? false;

    if (!(bumpMajor ^
        bumpMinor ^
        bumpPatch ^
        (bumpMajor && bumpMinor && bumpPatch))) {
      // exactly one bump<version> variable must be true, all others must be false
      error('Bump version with either --major, --minor, or --patch');
    }

    final packageDirectory = Directory(
      argResults?.rest.firstOrNull ??
          mainProject?.root.path ??
          Directory.current.path,
    );
    final pubspecFile = DartPackage.fromDirectory(packageDirectory)?.pubspec;

    if (pubspecFile == null || !pubspecFile.existsSync()) {
      error('Pubspec.yaml not found');
    }

    final pubSpec = PubSpec.fromFile(pubspecFile.absolute.path);
    final version = pubSpec.version;

    if (version == null) {
      error("Can't bump version because "
          "${pubspecFile.path} has no current version");
    }

    final oldBuildNumber = version.build.firstOrNull as int?;
    Version newVersion = version;
    if (bumpMajor) {
      newVersion = version.nextMajor;
    }
    if (bumpMinor) {
      newVersion = version.nextMinor;
    }
    if (bumpPatch) {
      newVersion = version.nextPatch;
    }

    if (oldBuildNumber != null) {
      final newBuildNumber = oldBuildNumber + 1;
      // build is immutable and null if not present
      newVersion = newVersion.copyWith(build: newBuildNumber.toString());
    }

    bool hasPubspecLocalChanges = false;
    bool areThereStagedFiles = false;
    bool isInDetachedHEAD = false;
    if (commit) {
      final pubspecDiff =
          'git diff HEAD --exit-code --quiet ${pubspecFile.absolute.path}'
              .start(nothrow: true);
      hasPubspecLocalChanges = pubspecDiff.exitCode != 0;

      final allFilesDiff =
          'git diff --cached --quiet --exit-code'.start(nothrow: true);
      areThereStagedFiles = allFilesDiff.exitCode != 0;

      final detachedHEAD = 'git symbolic-ref -q HEAD'
          .start(progress: Progress.printStdErr(), nothrow: true);
      isInDetachedHEAD = detachedHEAD.exitCode != 0;
    }

    // save to disk
    pubspecFile.replaceFirst(version.toString(), newVersion.toString());
    print(green('${pubSpec.name} version bumped from $version to $newVersion'));

    if (commit) {
      if (hasPubspecLocalChanges) {
        error("There are local changes in ${relative(pubspecFile.path)}, "
            "can't commit version bump");
      }
      if (areThereStagedFiles) {
        error('There are staged files, not committing version bump');
      }
      if (isInDetachedHEAD) {
        error('You are in "detached HEAD" state. Not committing version bump');
      }
      'git add ${pubspecFile.path}'.start(progress: Progress.printStdErr());
      'git commit -m "Bump version to $newVersion" --no-verify'
          .start(progress: Progress.printStdErr());
      'git --no-pager log -n1 --oneline'.run;
    }
  }
}

extension VersionExtensions on Version {
  /// Creates a copy of [Version], optionally changing [preRelease] and [build]
  Version Function({String? preRelease, String? build}) get copyWith =>
      _copyWith;

  /// Makes it distinguishable if users used `null` or did not provide any value
  static const _defaultParameter = Object();

  // copyWith version which handles `null`, as in freezed
  Version _copyWith({
    dynamic preRelease = _defaultParameter,
    dynamic build = _defaultParameter,
  }) {
    return Version(
      major,
      minor,
      patch,
      pre: () {
        if (preRelease == _defaultParameter) {
          if (this.preRelease.isEmpty) {
            return null;
          }
          return this.preRelease.join('.');
        }
        return preRelease as String?;
      }(),
      build: () {
        if (build == _defaultParameter) {
          if (this.build.isEmpty) {
            return null;
          }
          return this.build.join('.');
        }
        return build as String?;
      }(),
    );
  }
}
