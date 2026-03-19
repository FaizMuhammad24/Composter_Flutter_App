import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  final replacements = {
    // Utils -> mocks
    'utils/mock_actuator_logs.dart': 'utils/mocks/mock_actuator_logs.dart',
    'utils/mock_data.dart': 'utils/mocks/mock_data.dart',
    'utils/mock_notifications.dart': 'utils/mocks/mock_notifications.dart',
    'utils/mock_sensor_history.dart': 'utils/mocks/mock_sensor_history.dart',
    'utils/mock_system_status.dart': 'utils/mocks/mock_system_status.dart',
    // Utils -> helpers
    'utils/date_formatter.dart': 'utils/helpers/date_formatter.dart',
    'utils/screen_utils.dart': 'utils/helpers/screen_utils.dart',
    'utils/validators.dart': 'utils/helpers/validators.dart',
    // Utils -> styles
    'utils/app_elevation.dart': 'utils/styles/app_elevation.dart',
    'utils/app_radius.dart': 'utils/styles/app_radius.dart',
    // Widgets -> cards
    'widgets/alert_card.dart': 'widgets/cards/alert_card.dart',
    'widgets/deposit_card.dart': 'widgets/cards/deposit_card.dart',
    'widgets/reward_card.dart': 'widgets/cards/reward_card.dart',
    'widgets/sensor_card.dart': 'widgets/cards/sensor_card.dart',
    'widgets/stats_card.dart': 'widgets/cards/stats_card.dart',
    // Widgets -> common
    'widgets/loading_shimmer.dart': 'widgets/common/loading_shimmer.dart',
    'widgets/log_item_widget.dart': 'widgets/common/log_item_widget.dart',
  };

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;
    for (final entry in replacements.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        changed = true;
      }
    }
    if (changed) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
