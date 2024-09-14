import 'package:flutter/material.dart';

class Styles {
  static Color scaffoldBackgroundColor = Color.fromARGB(255, 246, 234, 234);
  static Color defaultRedColor = const Color(0xffff698a);
  static Color defaultYellowColor = const Color(0xFFE96560);
  static Color defaultBlueColor = const Color(0xff52beff);
  static Color defaultGreyColor = const Color(0xff77839a);
  static Color defaultLightGreyColor = const Color(0xffc4c4c4);
  static Color defaultLightWhiteColor = const Color(0xFFf2f6fe);

  static double defaultPadding = 18.0;

  static BorderRadius defaultBorderRadius = BorderRadius.circular(20);

  static ScrollbarThemeData scrollbarTheme =
      const ScrollbarThemeData().copyWith(
    thumbColor: MaterialStateProperty.all(defaultYellowColor),
    thumbVisibility: MaterialStateProperty.all(false),
    interactive: true,
  );
}
