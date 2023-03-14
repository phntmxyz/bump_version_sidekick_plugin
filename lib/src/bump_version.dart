import 'package:sidekick_core/sidekick_core.dart';

extension BumpVersion on Version {
  /// Returns a bumped [Version], major, minor or patch
  ///
  /// Always strips the pre-release identifiers.
  /// If the build information contains a single number, it is incremented.
  Version bumpVersion(VersionBumpType bumpType) {
    Version newVersion = () {
      switch (bumpType) {
        case VersionBumpType.major:
          return nextMajor;
        case VersionBumpType.minor:
          return nextMinor;
        case VersionBumpType.patch:
          return nextPatch;
      }
    }();

    // bump of build information is only safe when it contains a single number,
    // otherwise we don't know its incrementation schema and we leave it as is
    if (build.whereType<int>().length == 1) {
      final newBuild = build.map((e) => e is int ? e + 1 : e).join('.');
      newVersion = newVersion.copyWith(build: newBuild);
    } else {
      newVersion =
          newVersion.copyWith(build: build.isNotEmpty ? build.join('.') : null);
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
