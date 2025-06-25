import 'package:pubspec_manager/pubspec_manager.dart';
import 'package:sidekick_core/sidekick_core.dart' hide Version;
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
  final pubSpec = PubSpec.loadFromPath(pubspecFile.absolute.path);
  final pmVersion = pubSpec.version;
  if (pmVersion.isMissing || pmVersion.isEmpty) {
    return null;
  }
  return pmVersion;
}
