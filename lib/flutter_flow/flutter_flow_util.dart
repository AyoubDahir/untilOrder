import 'package:flutter/material.dart';

T createModel<T>(BuildContext context, T Function() model) => model();

void safeSetState(VoidCallback fn) {
  if (fn != null) {
    fn();
  }
}
