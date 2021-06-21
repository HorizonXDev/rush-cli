import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:github/github.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';
import 'package:rush_cli/commands/upgrade_command/helpers/upgrade_utils.dart';
import 'package:rush_prompt/rush_prompt.dart';

class UpgradeCommand extends Command {
  final String _dataDir;

  UpgradeCommand(this._dataDir) {
    final dir = Directory(p.join(_dataDir, '.installer'))
      ..createSync(recursive: true);
    Hive.init(dir.path);
  }

  @override
  String get description =>
      'Upgrades Rush and all it\'s components to the latest available version.';

  @override
  String get name => 'upgrade';

  @override
  Future<void> run() async {
    PrintArt();
    Logger.log(LogType.info, 'Fetching data...');

    final box = await Hive.openBox('data.init');
    final binDir = p.dirname(Platform.resolvedExecutable);

    final contents = await UpgradeUtils.fetchContents(box, binDir, '');

    if (contents.isEmpty) {
      Logger.log(LogType.info,
          'You already have the latest version of Rush installed.');
      exit(0);
    }

    final pb = ProgressBar(
        'Downloading... (${UpgradeUtils.getSize(contents)} MiB)',
        contents.length);

    await UpgradeUtils.downloadContents(contents, box,
        binDirPath: binDir, dataDirPath: _dataDir, pb: pb);

    _printFooter(await UpgradeUtils.getLatestRelease());

    await _swapExe(binDir);
  }

  /// Swaps the old Rush executable with the new one
  Future<void> _swapExe(String binDir) async {
    final newExeExists = Directory(binDir)
        .listSync()
        .any((element) => p.extension(element.path) == '.new');

    if (newExeExists) {
      final oldExe =
          p.join(binDir, 'rush' + (Platform.isWindows ? '.exe' : ''));

      // Windows doesn't allows modifying any EXE while its running.
      // Therefore, we spawn a new process, detached from this one,
      // and run swap.exe which swaps the old exe with the new one.
      if (Platform.isWindows) {
        final args = <String>[];
        args
          ..add(p.join(binDir, 'swap.exe'))
          ..addAll(['-o', oldExe]);

        await ProcessRunner()
            .runProcess(args, startMode: ProcessStartMode.detached);
      } else {
        File(oldExe).deleteSync();
        File(oldExe + '.new').renameSync(oldExe);
      }
    }
  }

  void _printFooter(Release release) {
    final console = Console();

    console
      ..setForegroundColor(ConsoleColor.green)
      ..write('Success! ')
      ..resetColorAttributes()
      ..writeLine('Rush has been upgraded to ${release.tagName}')
      ..resetColorAttributes();

    console
      ..writeLine()
      ..setForegroundColor(ConsoleColor.blue)
      ..writeLine('Changelog')
      ..resetColorAttributes();

    final body = release.body!.split('\n');

    body
        .where((el) => el.startsWith(RegExp(r'(\*|-|•)')))
        .take(5)
        .forEach((el) {
      console.writeLine(
          ' ' * 2 + '- ' + el.replaceFirst(RegExp(r'(\*|-|•)'), '').trim());
    });

    console
      ..writeLine(' ' * 4 + '...')
      ..writeLine()
      ..writeLine('See the complete changelog here: ')
      ..setForegroundColor(ConsoleColor.blue)
      ..writeLine(release.htmlUrl)
      ..resetColorAttributes();
  }
}
