import 'package:sidekick_core/sidekick_core.dart';
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
  final pubSpec = PubSpec.fromFile(pubspecFile.absolute.path);
  return pubSpec.version;
}
