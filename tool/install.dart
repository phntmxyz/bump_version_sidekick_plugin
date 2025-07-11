import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, mainProject, repository;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;

  await addSelfAsDependency();
  await pubGet(package);

  await registerPlugin(
    sidekickCli: package,
    import:
        "import 'package:phntmxyz_bump_version_sidekick_plugin/phntmxyz_bump_version_sidekick_plugin.dart';",
    command: 'BumpVersionCommand()',
  );
}
