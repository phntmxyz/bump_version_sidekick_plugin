import 'package:phntmxyz_bump_version_sidekick_plugin/src/bump_version.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

void main() {
  test('bump major version', () {
    expect(
      Version(0, 0, 0).bumpVersion(VersionBumpType.major),
      Version(1, 0, 0),
    );

    expect(
      Version(1, 0, 0).bumpVersion(VersionBumpType.major),
      Version(2, 0, 0),
    );

    expect(
      Version(1, 2, 3, build: '12').bumpVersion(VersionBumpType.major),
      Version(2, 0, 0, build: '13'),
    );

    expect(
      Version(1, 2, 3, pre: '7').bumpVersion(VersionBumpType.major),
      Version(2, 0, 0),
    );
  });

  test('bump minor version', () {
    expect(
      Version(0, 0, 0).bumpVersion(VersionBumpType.minor),
      Version(0, 1, 0),
    );

    expect(
      Version(1, 0, 0).bumpVersion(VersionBumpType.minor),
      Version(1, 1, 0),
    );

    expect(
      Version(1, 2, 3, build: '12').bumpVersion(VersionBumpType.minor),
      Version(1, 3, 0, build: '13'),
    );

    expect(
      Version(1, 2, 3, pre: '7').bumpVersion(VersionBumpType.minor),
      Version(1, 3, 0),
    );
  });

  test('bump patch version', () {
    expect(
      Version(0, 0, 0).bumpVersion(VersionBumpType.patch),
      Version(0, 0, 1),
    );

    expect(
      Version(1, 0, 0).bumpVersion(VersionBumpType.patch),
      Version(1, 0, 1),
    );

    expect(
      Version(1, 2, 3, build: '12').bumpVersion(VersionBumpType.patch),
      Version(1, 2, 4, build: '13'),
    );

    expect(
      Version(1, 2, 3, pre: '7').bumpVersion(VersionBumpType.patch),
      // yup, that's correct. It just strips the pre-release suffix
      Version(1, 2, 3),
    );
  });

  test('bump build number only when it is safe', () {
    expect(
      Version(1, 2, 3, build: '2').bumpVersion(VersionBumpType.patch),
      Version(1, 2, 4, build: '3'),
    );

    expect(
      Version(1, 2, 3, build: 'foo.42.bar').bumpVersion(VersionBumpType.patch),
      Version(1, 2, 4, build: 'foo.43.bar'),
    );

    expect(
      Version(1, 2, 3, build: 'foo.19.89.bar')
          .bumpVersion(VersionBumpType.patch),
      Version(1, 2, 4, build: 'foo.19.89.bar'),
    );
  });
}
