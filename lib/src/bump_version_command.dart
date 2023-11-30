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
    addModification(bumpPubspecVersion);
  }

  final List<FileModification> _modifications = [];

  void addModification(FileModification modification) {
    _modifications.add(modification);
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

    void applyModifications() {
      for (final modification in _modifications) {
        modification.call(package, version, bumpedVersion);
      }
    }

    bool bumped = false;
    if (commit) {
      final detachedHEAD = 'git symbolic-ref -q HEAD'
          .start(progress: Progress.printStdErr(), nothrow: true);
      if (detachedHEAD.exitCode != 0) {
        throw 'You are in "detached HEAD" state, can not commit version bump';
      } else {
        commitFileModifications(
          applyModifications,
          commitMessage: 'Bump version to $bumpedVersion',
        );
        bumped = true;
      }
    }
    if (!bumped) {
      applyModifications();
    }

    print(
      green(
        '${package.name} version bumped '
        'from $currentVersion to $bumpedVersion',
      ),
    );
  }

  /// Updates the version in pubspec.yaml
  void bumpPubspecVersion(
    DartPackage package,
    Version oldVersion,
    Version newVersion,
  ) {
    setPubspecVersion(package.pubspec, newVersion);
  }
}

typedef FileModification = void Function(
  DartPackage package,
  Version oldVersion,
  Version newVersion,
);

/// Commits only the file changes that have been done in [block]
void commitFileModifications(
  void Function() block, {
  required String commitMessage,
}) {
  final stashName = 'pre-bump-${DateTime.now().toIso8601String()}';

  // stash changes
  'git stash save --include-untracked "$stashName"'
      .start(progress: Progress.printStdErr());

  try {
    // apply modifications
    block();

    // commit
    'git add -A'.start(progress: Progress.printStdErr());
    'git commit -m "$commitMessage" --no-verify'
        .start(progress: Progress.printStdErr());
    'git --no-pager log -n1 --oneline'.run;
  } catch (e) {
    printerr('Detected error, discarding modifications');
    // discard all modifications
    'git reset --hard'.start(progress: Progress.printStdErr());
    rethrow;
  } finally {
    final stashes = 'git stash list'.start(progress: Progress.capture()).lines;
    final stash = stashes.firstOrNullWhere((line) => line.contains(stashName));
    if (stash != null) {
      final stashId = RegExp(r'stash@{(\d+)}').firstMatch(stash)?.group(1);
      // restore changes
      'git merge --squash --strategy-option=theirs stash@{$stashId}'
          .start(progress: Progress.print());
      try {
        // apply modifications again to make sure the stash did not overwrite already made changes
        block();
      } catch (e) {
        // ignore
      }
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
