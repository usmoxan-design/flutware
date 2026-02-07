import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/app_models.dart';

class LogicInterpreter {
  static void run(List<ActionBlock> actions, BuildContext context) {
    for (var action in actions) {
      if (action.type == 'toast') {
        Fluttertoast.showToast(msg: action.data['message'] ?? '');
      }
    }
  }
}
