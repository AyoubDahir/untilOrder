import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/login_page/login_page_widget.dart';
import 'dart:ui';
import 'onboarding_widget.dart' show OnboardingWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OnboardingModel extends ChangeNotifier {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Carousel widget.
  PageController? pageController;
  int currentPageIndex = 0;
  
  void initState(BuildContext context) {
    pageController = PageController();
  }

  void dispose() {
    pageController?.dispose();
    super.dispose();
  }
}
