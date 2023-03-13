import 'package:sidekick_core/sidekick_core.dart';

/// Captures the status of a file before doing any changes ([captureFileStatus])
/// and commits the changes ([commit]) unless
/// - the file had local changes
/// - there are staged files
/// - the HEAD is detached
class GitFileCommitter {
  GitFileCommitter(this.file);
  final File file;

  bool _hasPubspecLocalChanges = false;
  bool _areThereStagedFiles = false;
  bool _isInDetachedHEAD = false;

  bool _captured = false;

  /// Call this method before doing any file changes to check if the file doesn't have any local changes and it can be committed safely after with [commit]
  void captureFileStatus() {
    final pubspecDiff =
        'git diff HEAD --exit-code --quiet ${file.absolute.path}'
            .start(nothrow: true);
    _hasPubspecLocalChanges = pubspecDiff.exitCode != 0;

    final allFilesDiff =
        'git diff --cached --quiet --exit-code'.start(nothrow: true);
    _areThereStagedFiles = allFilesDiff.exitCode != 0;

    final detachedHEAD = 'git symbolic-ref -q HEAD'
        .start(progress: Progress.printStdErr(), nothrow: true);
    _isInDetachedHEAD = detachedHEAD.exitCode != 0;
    _captured = true;
  }

  /// Commits all changes of [file] when there are no local changes detected before by [captureFileStatus]
  void commit(String message) {
    if (!_captured) {
      throw StateError('Call captureFileStatus first');
    }
    if (_hasPubspecLocalChanges) {
      error("There are local changes in ${relative(file.path)}, "
          "can't commit version bump");
    }
    if (_areThereStagedFiles) {
      error('There are staged files, not committing version bump');
    }
    if (_isInDetachedHEAD) {
      error('You are in "detached HEAD" state. Not committing version bump');
    }
    'git add ${file.path}'.start(progress: Progress.printStdErr());
    'git commit -m "$message" --no-verify'
        .start(progress: Progress.printStdErr());
    'git --no-pager log -n1 --oneline'.run;
  }
}
