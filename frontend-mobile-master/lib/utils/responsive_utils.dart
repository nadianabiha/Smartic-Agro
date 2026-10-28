import 'package:flutter/material.dart';

/// Breakpoints untuk responsive design
/// - Small Phone: < 360 px
/// - Medium Phone: 360-480 px
/// - Large Phone: 480-600 px
/// - Tablet: >= 600 px
enum DeviceType { smallPhone, mediumPhone, largePhone, tablet }

class ResponsiveUtils {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;
  late final EdgeInsets padding;
  late final DeviceType deviceType;
  late final bool isPortrait;
  late final double textScaleFactor;

  ResponsiveUtils(this.context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    padding = mediaQuery.padding;
    isPortrait = mediaQuery.orientation == Orientation.portrait;
    textScaleFactor = mediaQuery.textScaler.scale(1.0);

    // Determine device type based on width
    if (screenWidth < 360) {
      deviceType = DeviceType.smallPhone;
    } else if (screenWidth < 480) {
      deviceType = DeviceType.mediumPhone;
    } else if (screenWidth < 600) {
      deviceType = DeviceType.largePhone;
    } else {
      deviceType = DeviceType.tablet;
    }
  }

  /// Check if device is tablet
  bool get isTablet => deviceType == DeviceType.tablet;

  /// Check if device is small phone
  bool get isSmallPhone => deviceType == DeviceType.smallPhone;

  /// Get responsive horizontal padding
  double get horizontalPadding {
    switch (deviceType) {
      case DeviceType.smallPhone:
        return 12.0;
      case DeviceType.mediumPhone:
        return 16.0;
      case DeviceType.largePhone:
        return 20.0;
      case DeviceType.tablet:
        return 32.0;
    }
  }

  /// Get responsive vertical padding
  double get verticalPadding {
    switch (deviceType) {
      case DeviceType.smallPhone:
        return 8.0;
      case DeviceType.mediumPhone:
        return 12.0;
      case DeviceType.largePhone:
        return 16.0;
      case DeviceType.tablet:
        return 24.0;
    }
  }

  /// Get responsive font size
  double fontSize(double baseSize) {
    double multiplier;
    switch (deviceType) {
      case DeviceType.smallPhone:
        multiplier = 0.85;
        break;
      case DeviceType.mediumPhone:
        multiplier = 1.0;
        break;
      case DeviceType.largePhone:
        multiplier = 1.1;
        break;
      case DeviceType.tablet:
        multiplier = 1.25;
        break;
    }
    return baseSize * multiplier;
  }

  /// Get responsive icon size
  double iconSize(double baseSize) {
    switch (deviceType) {
      case DeviceType.smallPhone:
        return baseSize * 0.8;
      case DeviceType.mediumPhone:
        return baseSize;
      case DeviceType.largePhone:
        return baseSize * 1.1;
      case DeviceType.tablet:
        return baseSize * 1.3;
    }
  }

  /// Get responsive spacing
  double spacing(double baseSpacing) {
    switch (deviceType) {
      case DeviceType.smallPhone:
        return baseSpacing * 0.75;
      case DeviceType.mediumPhone:
        return baseSpacing;
      case DeviceType.largePhone:
        return baseSpacing * 1.15;
      case DeviceType.tablet:
        return baseSpacing * 1.5;
    }
  }

  /// Get max content width for tablet (prevent too wide content)
  double get maxContentWidth {
    if (isTablet) {
      return 500; // Max width for form content on tablets
    }
    return screenWidth;
  }

  /// Get button height
  double get buttonHeight {
    switch (deviceType) {
      case DeviceType.smallPhone:
        return 44.0;
      case DeviceType.mediumPhone:
        return 48.0;
      case DeviceType.largePhone:
        return 52.0;
      case DeviceType.tablet:
        return 56.0;
    }
  }

  /// Get input field height
  double get inputHeight {
    switch (deviceType) {
      case DeviceType.smallPhone:
        return 48.0;
      case DeviceType.mediumPhone:
        return 52.0;
      case DeviceType.largePhone:
        return 56.0;
      case DeviceType.tablet:
        return 60.0;
    }
  }
}

/// Extension untuk kemudahan akses
extension ResponsiveContext on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);
}
