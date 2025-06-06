import 'package:cbd/src/runner.dart';
import 'package:cli_launcher/cli_launcher.dart';

void main(List<String> arguments) {
  launchExecutable(
    arguments,
    LaunchConfig(name: ExecutableName('cbd'), entrypoint: CbdRunner.launch),
  );
}
