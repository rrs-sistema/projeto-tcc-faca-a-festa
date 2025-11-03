import 'package:flutter/material.dart';

import 'event_theme_controller.dart';

extension AdminTheme on EventThemeController {
  LinearGradient get adminGradient => LinearGradient(
        colors: [
          primaryColor.value.withValues(alpha: 0.85),
          primaryColor.value.withValues(alpha: 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Color get adminAccent => primaryColor.value;
}
