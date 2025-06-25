import 'dart:io';
import 'package:phntmxyz_bump_version_sidekick_plugin/src/bump_version.dart';
import 'package:pubspec_manager/pubspec_manager.dart';
import 'package:test/test.dart';

void main() {
  test('bump major version', () {
    final v000 = _createVersion('0.0.0');
    final v100 = _createVersion('1.0.0');
    final v200 = _createVersion('2.0.0');
    final v123build12 = _createVersion('1.2.3+12');
    final v200build13 = _createVersion('2.0.0+13');
    final v123pre7 = _createVersion('1.2.3-7');

    expect(
      v000.bumpVersion(VersionBumpType.major).toString(),
      v100.toString(),
    );

    expect(
      v100.bumpVersion(VersionBumpType.major).toString(),
      v200.toString(),
    );

    expect(
      v123build12.bumpVersion(VersionBumpType.major).toString(),
      v200build13.toString(),
    );

    expect(
      v123pre7.bumpVersion(VersionBumpType.major).toString(),
      v200.toString(),
    );
  });

  test('bump minor version', () {
    final v000 = _createVersion('0.0.0');
    final v010 = _createVersion('0.1.0');
    final v100 = _createVersion('1.0.0');
    final v110 = _createVersion('1.1.0');
    final v123build12 = _createVersion('1.2.3+12');
    final v130build13 = _createVersion('1.3.0+13');
    final v123pre7 = _createVersion('1.2.3-7');
    final v130 = _createVersion('1.3.0');

    expect(
      v000.bumpVersion(VersionBumpType.minor).toString(),
      v010.toString(),
    );

    expect(
      v100.bumpVersion(VersionBumpType.minor).toString(),
      v110.toString(),
    );

    expect(
      v123build12.bumpVersion(VersionBumpType.minor).toString(),
      v130build13.toString(),
    );

    expect(
      v123pre7.bumpVersion(VersionBumpType.minor).toString(),
      v130.toString(),
    );
  });

  test('bump patch version', () {
    final v000 = _createVersion('0.0.0');
    final v001 = _createVersion('0.0.1');
    final v100 = _createVersion('1.0.0');
    final v101 = _createVersion('1.0.1');
    final v123build12 = _createVersion('1.2.3+12');
    final v124build13 = _createVersion('1.2.4+13');
    final v123pre7 = _createVersion('1.2.3-7');
    final v123 = _createVersion('1.2.3');

    expect(
      v000.bumpVersion(VersionBumpType.patch).toString(),
      v001.toString(),
    );

    expect(
      v100.bumpVersion(VersionBumpType.patch).toString(),
      v101.toString(),
    );

    expect(
      v123build12.bumpVersion(VersionBumpType.patch).toString(),
      v124build13.toString(),
    );

    expect(
      v123pre7.bumpVersion(VersionBumpType.patch).toString(),
      // yup, that's correct. It just strips the pre-release suffix
      v123.toString(),
    );
  });

  test('bump build number only when it is safe', () {
    final v123build2 = _createVersion('1.2.3+2');
    final v124build3 = _createVersion('1.2.4+3');
    final v123buildFoo42Bar = _createVersion('1.2.3+foo.42.bar');
    final v124buildFoo43Bar = _createVersion('1.2.4+foo.43.bar');
    final v123buildFoo198989Bar = _createVersion('1.2.3+foo.19.89.bar');
    final v124buildFoo198989Bar = _createVersion('1.2.4+foo.19.89.bar');

    expect(
      v123build2.bumpVersion(VersionBumpType.patch).toString(),
      v124build3.toString(),
    );

    expect(
      v123buildFoo42Bar.bumpVersion(VersionBumpType.patch).toString(),
      v124buildFoo43Bar.toString(),
    );

    expect(
      v123buildFoo198989Bar.bumpVersion(VersionBumpType.patch).toString(),
      v124buildFoo198989Bar.toString(),
    );
  });
}

/// Helper function to create a Version from a version string
Version _createVersion(String versionString) {
  // Create a temporary pubspec file since pubspec_manager works with files
  final tempDir = Directory.systemTemp.createTempSync('version_test');
  final pubspecFile = File('${tempDir.path}/pubspec.yaml');
  final yamlContent = 'name: test\nversion: $versionString';
  pubspecFile.writeAsStringSync(yamlContent);

  final pubspec = PubSpec.loadFromPath(pubspecFile.path);
  final version = pubspec.version;

  // Clean up
  tempDir.deleteSync(recursive: true);

  return version;
}
