# Bump Version sidekick plugin

A plugin for [sidekick CLIs](https://pub.dev/packages/sidekick).  

## Description

- Bumps the version of a package (major, minor, patch)
- Optionally commits the version bump
- modification API to adjust other files (e.g. `CHANGELOG.md`)

## Installation

### Prerequisites:

- install `sidekick`: `dart pub global activate sidekick`
- generate custom sidekick CLI: `sidekick init`

Installing plugins to a custom sidekick CLI is very similar to installing a package with
the [pub tool](https://dart.dev/tools/pub/cmd/pub-global#activating-a-package).

### Installing this plugin from pub.dev

```bash
your_custom_sidekick_cli sidekick plugins install phntmxyz_bump_version_sidekick_plugin
```

## Usage
```bash
your_custom_sidekick_cli bump_version [package-path] [--minor|patch|major] --[no-]commit
```

`package-path` is the path to the folder containing the `pubspec.yaml` whose version should be bumped. 
An error is thrown when no `pubspec.yaml` can be found there.  
If `package-path` is not given, this defaults to the `mainProject` which can be optionally defined in your sidekick_cli. 
If no `mainProject` is defined, this defaults to the current directory.

One of `--minor`, `--patch`, `--major` is required. This controls how the version is bumped.  
E.g. current version is `1.2.3`, `--minor` is selected -> updates to `1.3.0`.  

If `--commit` is given, the version bump is automatically committed.

## Modification API

```dart
runner..addCommand(BumpVersionCommand()..addModification(bumpChangelog));
```

```dart
Future<void> bumpChangelog(DartPackage package, Version oldVersion, Version newVersion) async {
  final readme = package.root.file('README.md');
  final content = readme.readAsStringSync();

  final versionRegex = RegExp(r'my_package: \^(.+)');
  final update = content.replaceFirst(versionRegex, 'my_package: ^${newVersion.canonicalizedVersion}');
  readme.writeAsStringSync(update);
}
```

## License

```
Copyright 2023 phntm GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
