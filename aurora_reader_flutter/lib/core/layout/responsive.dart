import 'package:flutter/material.dart';

class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

enum ScreenSize { mobile, tablet, desktop }

class ResponsiveHelper {
  ResponsiveHelper._();

  static ScreenSize screenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Breakpoints.desktop) return ScreenSize.desktop;
    if (width >= Breakpoints.mobile) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  static bool isMobile(BuildContext context) =>
      screenSize(context) == ScreenSize.mobile;

  static bool isTablet(BuildContext context) =>
      screenSize(context) == ScreenSize.tablet;

  static bool isDesktop(BuildContext context) =>
      screenSize(context) == ScreenSize.desktop;

  static int gridColumns(BuildContext context) {
    switch (screenSize(context)) {
      case ScreenSize.mobile:
        return 2;
      case ScreenSize.tablet:
        return 3;
      case ScreenSize.desktop:
        final width = MediaQuery.sizeOf(context).width;
        return width >= 1600 ? 6 : 4;
    }
  }

  static double contentMaxWidth(BuildContext context) {
    switch (screenSize(context)) {
      case ScreenSize.mobile:
        return MediaQuery.sizeOf(context).width;
      case ScreenSize.tablet:
        return 900;
      case ScreenSize.desktop:
        return 1200;
    }
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    switch (ResponsiveHelper.screenSize(context)) {
      case ScreenSize.desktop:
        return (desktop ?? tablet ?? mobile)(context);
      case ScreenSize.tablet:
        return (tablet ?? mobile)(context);
      case ScreenSize.mobile:
        return mobile(context);
    }
  }
}
