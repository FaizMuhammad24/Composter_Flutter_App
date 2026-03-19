import 'dart:io';

void main() async {
  final folders = [
    'lib/utils/mocks',
    'lib/utils/helpers',
    'lib/utils/styles',
    'lib/widgets/cards',
    'lib/widgets/common',
  ];

  for (final folder in folders) {
    final dir = Directory(folder);
    if (!dir.existsSync()) continue;
    
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      String content = file.readAsStringSync();
      List<String> lines = content.split('\n');
      bool changed = false;

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith("import '")) {
          // If the import has exactly N levels of `../`, increment by 1
          String line = lines[i];
          
          if (line.contains("import '../../../")) {
            lines[i] = line.replaceAll("import '../../../", "import '../../../../");
            changed = true;
          } else if (line.contains("import '../../")) {
            lines[i] = line.replaceAll("import '../../", "import '../../../");
            changed = true;
          } else if (line.contains("import '../")) {
            lines[i] = line.replaceAll("import '../", "import '../../");
            changed = true;
          } else if (line.contains("import 'package:")) {
            // Do nothing
          } else {
            // It's importing a sibling `import 'some_file.dart';`
            // Let's assume it still works if it's external, or maybe we don't care.
          }
        }
      }
      if (changed) {
        file.writeAsStringSync(lines.join('\n'));
        print('Fixed ${file.path}');
      }
    }
  }
}
