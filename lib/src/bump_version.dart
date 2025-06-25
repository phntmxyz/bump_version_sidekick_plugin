import 'dart:io';
import 'package:pubspec_manager/pubspec_manager.dart';

extension BumpVersion on Version {
  /// Returns a bumped [Version], major, minor or patch
  ///
  /// Always strips the pre-release identifiers.
  /// If the build information contains a single number, it is incremented.
  Version bumpVersion(VersionBumpType bumpType) {
    final currentSemVersion = semVersion;

    final newSemVersion = () {
      switch (bumpType) {
        case VersionBumpType.major:
          return currentSemVersion.nextMajor;
        case VersionBumpType.minor:
          return currentSemVersion.nextMinor;
        case VersionBumpType.patch:
          return currentSemVersion.nextPatch;
      }
    }();

    // bump of build information is only safe when it contains a single number,
    // otherwise we don't know its incrementation schema and we leave it as is
    final newVersionString = () {
      if (currentSemVersion.build.whereType<int>().length == 1) {
        final newBuild =
            currentSemVersion.build.map((e) => e is int ? e + 1 : e).join('.');
        final major = newSemVersion.major;
        final minor = newSemVersion.minor;
        final patch = newSemVersion.patch;
        final preRelease = newSemVersion.preRelease.isNotEmpty
            ? newSemVersion.preRelease.join('.')
            : null;

        var versionStr = '$major.$minor.$patch';
        if (preRelease != null) versionStr += '-$preRelease';
        return versionStr += '+$newBuild';
      } else {
        final build = currentSemVersion.build.isNotEmpty
            ? currentSemVersion.build.join('.')
            : null;
        var versionStr = newSemVersion.toString();
        if (build != null && !versionStr.contains('+')) {
          versionStr += '+$build';
        }
        return versionStr;
      }
    }();

    // Create a new Version by creating a temporary file
    // This is necessary because pubspec_manager is designed to work with files
    final tempDir = Directory.systemTemp.createTempSync('version_bump');
    final pubspecFile = File('${tempDir.path}/pubspec.yaml');
    final yamlContent = 'name: temp\nversion: $newVersionString';
    pubspecFile.writeAsStringSync(yamlContent);

    final pubspec = PubSpec.loadFromPath(pubspecFile.path);
    final newVersion = pubspec.version;

    // Clean up
    tempDir.deleteSync(recursive: true);

    return newVersion;
  }
}

/// What kind of Version bump to perform
enum VersionBumpType {
  major,
  minor,
  patch,
}
