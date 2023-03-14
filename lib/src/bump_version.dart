import 'package:sidekick_core/sidekick_core.dart';

extension BumpVersion on Version {
  /// Returns a bumped [Version], major, minor or patch
  ///
  /// Always bumps buildNumber when set by 1
  Version bumpVersion(VersionBumpType bumpType) {
    final oldBuildNumber = build.firstOrNull as int?;
    Version newVersion = this;
    switch (bumpType) {
      case VersionBumpType.major:
        newVersion = nextMajor;
        break;
      case VersionBumpType.minor:
        newVersion = nextMinor;
        break;
      case VersionBumpType.patch:
        newVersion = nextPatch;
        break;
    }

    if (oldBuildNumber != null) {
      final newBuildNumber = oldBuildNumber + 1;
      // build is immutable and null if not present
      newVersion = newVersion.copyWith(build: newBuildNumber.toString());
    }

    return newVersion;
  }
}

/// What kind of Version bump to perform
enum VersionBumpType {
  major,
  minor,
  patch,
}

extension on Version {
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
