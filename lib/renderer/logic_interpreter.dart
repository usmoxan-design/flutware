import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/app_models.dart';

class LogicInterpreter {
  static void run(List<ActionBlock> actions, BuildContext context) {
    for (var action in actions) {
      switch (action.type) {
        case 'toast':
          _showToast(action.data['message'] ?? '');
          break;
        // Future actions can be added here
        default:
          debugPrint('Unknown action type: ${action.type}');
      }
    }
  }

  static void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
