import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Pretendard';

  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeBase = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeTitle = 24.0;

  // Text Styles
  static const TextStyle title = TextStyle(
    fontSize: fontSizeTitle,
    fontWeight: FontWeight.bold,
    color: AppColors.foreground,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: fontSizeLarge,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  );

  static const TextStyle body = TextStyle(
    fontSize: fontSizeMedium,
    fontWeight: FontWeight.normal,
    color: AppColors.foreground,
  );

  static const TextStyle caption = TextStyle(
    fontSize: fontSizeSmall,
    fontWeight: FontWeight.normal,
    color: AppColors.mutedForeground,
  );
}
