import 'package:sidekick_core/sidekick_core.dart';
// ignore: depend_on_referenced_packages
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Sets the version in the pubspec.yaml file
void setPubspecVersion(File pubspecFile, Version version) {
  final editor = YamlEditor(pubspecFile.readAsStringSync());
  editor.update(['version'], version.toString());
  pubspecFile.writeAsStringSync(editor.toString());
}

/// Reads the version from the pubspec.yaml file
Version? readPubspecVersion(File pubspecFile) {
  if (!pubspecFile.existsSync()) {
    error('pubspec.yaml not found at ${pubspecFile.absolute.path}');
  }
  final pubspecContents = pubspecFile.readAsStringSync();
  final yaml = loadYaml(pubspecContents) as Map;
  final versionString = yaml['version'] as String?;
  if (versionString == null) {
    return null;
  }
  return Version.parse(versionString);
}
