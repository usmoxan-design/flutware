import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/app_models.dart';
import 'json_renderer.dart';

class LogicInterpreter {
  static void run(
    List<ActionBlock> actions,
    BuildContext context, {
    ProjectData? project,
  }) {
    for (var action in actions) {
      _execute(action, context, project: project);
    }
  }

  static void _execute(
    ActionBlock action,
    BuildContext context, {
    ProjectData? project,
  }) {
    switch (action.type) {
      case 'if':
        final condition = _parseCondition(action.data['condition']);
        if (condition) {
          run(action.innerActions, context, project: project);
        }
        break;
      case 'if_else':
        final condition = _parseCondition(action.data['condition']);
        run(
          condition ? action.innerActions : action.elseActions,
          context,
          project: project,
        );
        break;
      case 'set_enabled':
        _showSnackBar(
          context,
          'setEnabled(${action.data['widgetId']}, ${action.data['enabled']})',
        );
        break;
      case 'request_focus':
        _showSnackBar(context, 'requestFocus(${action.data['widgetId']})');
        break;
      case 'get_width':
        _showSnackBar(context, 'getWidth(${action.data['widgetId']})');
        break;
      case 'get_height':
        _showSnackBar(context, 'getHeight(${action.data['widgetId']})');
        break;
      case 'set_variable':
        _showSnackBar(
          context,
          '${action.data['name']} = ${action.data['value']}',
        );
        break;
      case 'equals':
        _showSnackBar(context, '${action.data['a']} == ${action.data['b']}');
        break;
      case 'toast':
        _showToast(action.data['message'] ?? '');
        break;
      case 'snackbar':
        _showSnackBar(context, action.data['message'] ?? '');
        break;
      case 'navigate':
        _navigateTo(context, project, action.data['targetPageId'] ?? '');
        break;
      case 'back':
        Navigator.pop(context);
        break;
      default:
        debugPrint('Unknown action type: ${action.type}');
    }
  }

  static bool _parseCondition(dynamic value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return raw == 'true' || raw == '1';
  }

  static void _navigateTo(
    BuildContext context,
    ProjectData? project,
    String pageId,
  ) {
    if (project == null) return;
    final page = project.pages.firstWhere(
      (p) => p.id == pageId,
      orElse: () => PageData(id: '', name: 'Unknown'),
    );
    if (page.id.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            JsonRenderer(pageData: page, projectData: project),
      ),
    );
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

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        elevation: 10,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(5),
      ),
    );
  }
}
